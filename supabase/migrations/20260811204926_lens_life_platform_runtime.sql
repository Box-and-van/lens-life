alter table public.ll_organisation_contacts add column if not exists user_id uuid references auth.users(id) on delete set null;
create unique index if not exists ll_organisation_contacts_user_id_uidx on public.ll_organisation_contacts(user_id) where user_id is not null;
create index if not exists ll_customers_user_id_idx on public.ll_customers(user_id) where user_id is not null;
create index if not exists ll_photographers_user_id_idx on public.ll_photographers(user_id) where user_id is not null;
create index if not exists ll_staff_profiles_user_id_idx on public.ll_staff_profiles(user_id) where user_id is not null;

create table if not exists public.ll_photographer_payment_accounts (
 id uuid primary key default gen_random_uuid(),photographer_id uuid not null unique references public.ll_photographers(id) on delete cascade,provider text not null default 'stripe',provider_account_id text unique,onboarding_status text not null default 'not_started',charges_enabled boolean not null default false,payouts_enabled boolean not null default false,details_submitted boolean not null default false,last_synced_at timestamptz,metadata jsonb not null default '{}'::jsonb,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.ll_operation_idempotency (
 id uuid primary key default gen_random_uuid(),idempotency_key text not null unique,operation text not null,actor_type text,actor_id uuid,status text not null default 'started',result jsonb,error text,expires_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
alter table public.ll_photographer_payment_accounts enable row level security;alter table public.ll_operation_idempotency enable row level security;
revoke all on table public.ll_photographer_payment_accounts from anon,authenticated;revoke all on table public.ll_operation_idempotency from anon,authenticated;
grant all on table public.ll_photographer_payment_accounts to service_role;grant all on table public.ll_operation_idempotency to service_role;
create unique index if not exists ll_one_active_assignment_per_booking_uidx on public.ll_booking_assignments(booking_id) where status in ('assigned','accepted','active');

create or replace function public.ll_accept_job_offer(p_offer_id uuid,p_photographer_id uuid) returns jsonb
language plpgsql security invoker set search_path=public as $$
declare v_offer public.ll_job_offers%rowtype;v_booking public.ll_bookings%rowtype;v_assignment public.ll_booking_assignments%rowtype;v_job public.ll_jobs%rowtype;
begin
 select * into v_offer from public.ll_job_offers where id=p_offer_id for update;if not found then raise exception 'offer_not_found';end if;
 if v_offer.photographer_id<>p_photographer_id then raise exception 'offer_owner_mismatch';end if;if v_offer.status<>'offered' then raise exception 'offer_not_available';end if;
 if v_offer.expires_at is not null and v_offer.expires_at<=now() then update public.ll_job_offers set status='expired',responded_at=now() where id=v_offer.id;raise exception 'offer_expired';end if;
 select * into v_booking from public.ll_bookings where id=v_offer.booking_id for update;if not found then raise exception 'booking_not_found';end if;
 if exists(select 1 from public.ll_booking_assignments where booking_id=v_booking.id and status in ('assigned','accepted','active')) then raise exception 'booking_already_assigned';end if;
 update public.ll_job_offers set status='accepted',responded_at=now() where id=v_offer.id;update public.ll_job_offers set status='superseded',responded_at=coalesce(responded_at,now()) where booking_id=v_booking.id and id<>v_offer.id and status='offered';
 insert into public.ll_booking_assignments(booking_id,photographer_id,job_offer_id,status,payout_pence,assigned_at,accepted_at) values(v_booking.id,p_photographer_id,v_offer.id,'accepted',v_offer.offered_payout_pence,now(),now()) returning * into v_assignment;
 insert into public.ll_jobs(booking_id,assignment_id,status,upload_due_at,metadata) values(v_booking.id,v_assignment.id,'scheduled',coalesce(v_booking.event_ends_at,v_booking.event_starts_at)+interval '72 hours',jsonb_build_object('source','offer_acceptance')) on conflict(booking_id) do update set assignment_id=excluded.assignment_id,status='scheduled',updated_at=now() returning * into v_job;
 update public.ll_bookings set status='assigned' where id=v_booking.id;insert into public.ll_booking_status_history(booking_id,from_status,to_status,reason,actor_type,actor_id) values(v_booking.id,v_booking.status,'assigned','photographer_offer_accepted','photographer',p_photographer_id);
 insert into public.ll_event_outbox(event_key,aggregate_type,aggregate_id,event_type,payload,idempotency_key) values('booking.assigned:'||v_booking.id::text,'booking',v_booking.id,'booking.assigned',jsonb_build_object('booking_id',v_booking.id,'photographer_id',p_photographer_id,'assignment_id',v_assignment.id),'booking.assigned:'||v_booking.id::text) on conflict(idempotency_key) do nothing;
 return jsonb_build_object('booking_id',v_booking.id,'assignment_id',v_assignment.id,'job_id',v_job.id,'status','accepted');
end;$$;

create or replace function public.ll_record_payment_success(p_booking_id uuid,p_checkout_session_id uuid,p_payment_intent_id text,p_amount_pence bigint,p_currency text,p_stripe_event_id text,p_charge_id text default null) returns jsonb
language plpgsql security invoker set search_path=public as $$
declare v_booking public.ll_bookings%rowtype;v_payment public.ll_payments%rowtype;
begin
 select * into v_booking from public.ll_bookings where id=p_booking_id for update;if not found then raise exception 'booking_not_found';end if;
 insert into public.ll_payments(booking_id,checkout_session_id,provider,provider_payment_intent_id,payment_type,status,amount_pence,currency,settled_at,idempotency_key,metadata) values(p_booking_id,p_checkout_session_id,'stripe',p_payment_intent_id,'booking','paid',p_amount_pence,upper(p_currency),now(),'stripe:payment:'||p_payment_intent_id,jsonb_strip_nulls(jsonb_build_object('stripe_event_id',p_stripe_event_id,'charge_id',p_charge_id))) on conflict(provider_payment_intent_id) do update set status='paid',settled_at=coalesce(public.ll_payments.settled_at,now()),metadata=public.ll_payments.metadata||excluded.metadata returning * into v_payment;
 update public.ll_checkout_sessions set status='paid',updated_at=now() where id=p_checkout_session_id;
 if v_booking.status='pending_payment' then update public.ll_bookings set status='confirmed',confirmed_at=coalesce(confirmed_at,now()) where id=p_booking_id;insert into public.ll_booking_status_history(booking_id,from_status,to_status,reason,actor_type) values(p_booking_id,v_booking.status,'confirmed','stripe_payment_succeeded','system');end if;
 insert into public.ll_payment_reconciliation(payment_id,booking_id,expected_amount_pence,observed_amount_pence,status) values(v_payment.id,p_booking_id,v_booking.total_pence,p_amount_pence,case when v_booking.total_pence=p_amount_pence then 'clear' else 'mismatch' end) on conflict do nothing;
 insert into public.ll_event_outbox(event_key,aggregate_type,aggregate_id,event_type,payload,idempotency_key) values('booking.confirmed:'||p_booking_id::text,'booking',p_booking_id,'booking.confirmed',jsonb_build_object('booking_id',p_booking_id,'payment_id',v_payment.id),'booking.confirmed:'||p_booking_id::text) on conflict(idempotency_key) do nothing;
 return jsonb_build_object('booking_id',p_booking_id,'payment_id',v_payment.id,'status','paid');
end;$$;

create or replace function public.ll_schedule_payout_if_eligible(p_booking_id uuid,p_photographer_id uuid) returns jsonb
language plpgsql security invoker set search_path=public as $$
declare v_booking public.ll_bookings%rowtype;v_payment public.ll_payments%rowtype;v_assignment public.ll_booking_assignments%rowtype;v_existing public.ll_photographer_payouts%rowtype;v_share bigint;
begin
 select * into v_booking from public.ll_bookings where id=p_booking_id;if not found then raise exception 'booking_not_found';end if;if v_booking.status<>'completed' and v_booking.completed_at is null then raise exception 'booking_not_completed';end if;
 select * into v_assignment from public.ll_booking_assignments where booking_id=p_booking_id and photographer_id=p_photographer_id and status in ('accepted','active','completed') order by assigned_at desc limit 1;if not found then raise exception 'assignment_not_found';end if;
 select * into v_payment from public.ll_payments where booking_id=p_booking_id and status='paid' order by settled_at desc nulls last limit 1;if not found then raise exception 'payment_not_settled';end if;
 if exists(select 1 from public.ll_payment_reconciliation where payment_id=v_payment.id and status<>'clear') then raise exception 'reconciliation_not_clear';end if;
 if not exists(select 1 from public.ll_deliverables d join public.ll_jobs j on j.id=d.job_id where j.booking_id=p_booking_id and d.status in ('delivered','approved') and d.delivered_at is not null) then raise exception 'delivery_not_verified';end if;
 v_share:=coalesce(nullif(v_assignment.payout_pence,0),round(v_booking.total_pence*0.8)::bigint);
 insert into public.ll_photographer_payouts(photographer_id,booking_id,payment_id,status,gross_booking_pence,provider_share_pence,adjustments_pence,payout_pence,scheduled_for,metadata) values(p_photographer_id,p_booking_id,v_payment.id,'scheduled',v_booking.total_pence,v_share,0,v_share,current_date+5,jsonb_build_object('rule','default_80_20')) on conflict(photographer_id,booking_id) do update set status=case when public.ll_photographer_payouts.status='paid' then 'paid' else 'scheduled' end,scheduled_for=coalesce(public.ll_photographer_payouts.scheduled_for,current_date+5),updated_at=now() returning * into v_existing;
 return jsonb_build_object('payout_id',v_existing.id,'status',v_existing.status,'scheduled_for',v_existing.scheduled_for,'amount_pence',v_existing.payout_pence);
end;$$;
revoke all on function public.ll_accept_job_offer(uuid,uuid) from public,anon,authenticated;revoke all on function public.ll_record_payment_success(uuid,uuid,text,bigint,text,text,text) from public,anon,authenticated;revoke all on function public.ll_schedule_payout_if_eligible(uuid,uuid) from public,anon,authenticated;
grant execute on function public.ll_accept_job_offer(uuid,uuid) to service_role;grant execute on function public.ll_record_payment_success(uuid,uuid,text,bigint,text,text,text) to service_role;grant execute on function public.ll_schedule_payout_if_eligible(uuid,uuid) to service_role;
