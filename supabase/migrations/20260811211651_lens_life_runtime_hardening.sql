alter table public.ll_bookings add column if not exists checkout_request_id text;
alter table public.ll_quotes add column if not exists request_id text;
create unique index if not exists ll_bookings_checkout_request_id_uidx on public.ll_bookings(checkout_request_id) where checkout_request_id is not null;
create unique index if not exists ll_quotes_request_id_uidx on public.ll_quotes(request_id) where request_id is not null;
create unique index if not exists ll_bookings_quote_id_uidx on public.ll_bookings(quote_id) where quote_id is not null;
create unique index if not exists ll_payment_reconciliation_payment_id_uidx on public.ll_payment_reconciliation(payment_id) where payment_id is not null;
create index if not exists ll_quotes_status_created_idx on public.ll_quotes(status,created_at desc);
create index if not exists ll_photographer_payment_accounts_status_idx on public.ll_photographer_payment_accounts(onboarding_status,payouts_enabled);
create index if not exists ll_operation_idempotency_status_idx on public.ll_operation_idempotency(status,created_at);

create or replace function public.ll_record_payment_success(p_booking_id uuid,p_checkout_session_id uuid,p_payment_intent_id text,p_amount_pence bigint,p_currency text,p_stripe_event_id text,p_charge_id text default null) returns jsonb language plpgsql security invoker set search_path=public as $$
declare v_booking public.ll_bookings%rowtype;v_payment public.ll_payments%rowtype;
begin
 select * into v_booking from public.ll_bookings where id=p_booking_id for update;if not found then raise exception 'booking_not_found';end if;
 insert into public.ll_payments(booking_id,checkout_session_id,provider,provider_payment_intent_id,payment_type,status,amount_pence,currency,settled_at,idempotency_key,metadata) values(p_booking_id,p_checkout_session_id,'stripe',p_payment_intent_id,'booking','paid',p_amount_pence,upper(p_currency),now(),'stripe:payment:'||p_payment_intent_id,jsonb_strip_nulls(jsonb_build_object('stripe_event_id',p_stripe_event_id,'charge_id',p_charge_id))) on conflict(provider_payment_intent_id) do update set status='paid',settled_at=coalesce(public.ll_payments.settled_at,now()),metadata=public.ll_payments.metadata||excluded.metadata returning * into v_payment;
 update public.ll_checkout_sessions set status='paid',updated_at=now() where id=p_checkout_session_id;
 if v_booking.status='pending_payment' then update public.ll_bookings set status='confirmed',confirmed_at=coalesce(confirmed_at,now()) where id=p_booking_id;insert into public.ll_booking_status_history(booking_id,from_status,to_status,reason,actor_type) values(p_booking_id,v_booking.status,'confirmed','stripe_payment_succeeded','system');end if;
 insert into public.ll_payment_reconciliation(payment_id,booking_id,expected_amount_pence,observed_amount_pence,status) values(v_payment.id,p_booking_id,v_booking.total_pence,p_amount_pence,case when v_booking.total_pence=p_amount_pence then 'clear' else 'mismatch' end) on conflict(payment_id) do update set booking_id=excluded.booking_id,expected_amount_pence=excluded.expected_amount_pence,observed_amount_pence=excluded.observed_amount_pence,status=excluded.status,mismatch_reason=case when excluded.status='clear' then null else public.ll_payment_reconciliation.mismatch_reason end,updated_at=now();
 insert into public.ll_event_outbox(event_key,aggregate_type,aggregate_id,event_type,payload,idempotency_key) values('booking.confirmed:'||p_booking_id::text,'booking',p_booking_id,'booking.confirmed',jsonb_build_object('booking_id',p_booking_id,'payment_id',v_payment.id),'booking.confirmed:'||p_booking_id::text) on conflict(idempotency_key) do nothing;
 return jsonb_build_object('booking_id',p_booking_id,'payment_id',v_payment.id,'status','paid');
end;$$;
revoke all on function public.ll_record_payment_success(uuid,uuid,text,bigint,text,text,text) from public,anon,authenticated;grant execute on function public.ll_record_payment_success(uuid,uuid,text,bigint,text,text,text) to service_role;
