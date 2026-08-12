create unique index if not exists ll_quote_lines_service_uidx on public.ll_quote_lines(quote_id,service_offering_id,line_type) where service_offering_id is not null;
create unique index if not exists ll_conversations_support_case_uidx on public.ll_conversations(support_case_id) where support_case_id is not null;
