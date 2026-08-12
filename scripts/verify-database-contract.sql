select count(*) as ll_tables from pg_tables where schemaname='public' and tablename like 'll\_%' escape '\';
select version,name from supabase_migrations.schema_migrations where name like 'lens_life%' order by version;
select id,name,public from storage.buckets where id like 'll-%' order by id;
select p.proname,pg_get_function_identity_arguments(p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('ll_accept_job_offer','ll_record_payment_success','ll_schedule_payout_if_eligible','ll_claim_outbox_events','ll_complete_outbox_event','ll_retry_outbox_event') order by p.proname;
