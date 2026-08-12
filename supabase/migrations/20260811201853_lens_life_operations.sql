insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('ll-private-documents','ll-private-documents',false,10485760,array['application/pdf','image/jpeg','image/png','image/webp']),
  ('ll-deliveries','ll-deliveries',false,52428800,array['image/jpeg','image/png','image/webp','image/tiff']),
  ('ll-public-portfolio','ll-public-portfolio',true,20971520,array['image/jpeg','image/png','image/webp']),
  ('ll-privacy-exports','ll-privacy-exports',false,52428800,array['application/zip','application/json','text/csv'])
on conflict (id) do update set name=excluded.name,public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create or replace function public.ll_claim_outbox_events(p_limit integer default 20, p_lock_minutes integer default 10)
returns setof public.ll_event_outbox language plpgsql security definer set search_path = public as $$
begin
  return query with candidates as (
    select id from public.ll_event_outbox
    where (status='pending' and available_at<=now()) or (status='processing' and locked_at<now()-make_interval(mins=>p_lock_minutes))
    order by available_at,created_at for update skip locked limit greatest(1,least(p_limit,100))
  ), updated as (
    update public.ll_event_outbox e set status='processing',locked_at=now(),attempts=e.attempts+1,last_error=null from candidates c where e.id=c.id returning e.*
  ) select * from updated;
end;$$;
create or replace function public.ll_complete_outbox_event(p_event_id uuid) returns boolean language plpgsql security definer set search_path=public as $$begin update public.ll_event_outbox set status='processed',processed_at=now(),locked_at=null,last_error=null where id=p_event_id and status='processing';return found;end;$$;
create or replace function public.ll_retry_outbox_event(p_event_id uuid,p_error text,p_delay_minutes integer default 5) returns boolean language plpgsql security definer set search_path=public as $$begin update public.ll_event_outbox set status='pending',available_at=now()+make_interval(mins=>greatest(1,least(p_delay_minutes,1440))),locked_at=null,last_error=left(coalesce(p_error,'unknown error'),4000) where id=p_event_id and status='processing';return found;end;$$;
revoke all on function public.ll_claim_outbox_events(integer,integer) from public,anon,authenticated;
revoke all on function public.ll_complete_outbox_event(uuid) from public,anon,authenticated;
revoke all on function public.ll_retry_outbox_event(uuid,text,integer) from public,anon,authenticated;
grant execute on function public.ll_claim_outbox_events(integer,integer) to service_role;
grant execute on function public.ll_complete_outbox_event(uuid) to service_role;
grant execute on function public.ll_retry_outbox_event(uuid,text,integer) to service_role;
