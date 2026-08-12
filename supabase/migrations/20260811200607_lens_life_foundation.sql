-- Historical staging baseline.
-- The full foundation was applied to box-and-van-v2-staging as migration
-- 20260811200607_lens_life_foundation. This repository was connected after
-- the migration had already been applied. Deployment validation must verify
-- the live baseline using scripts/verify-database-contract.sql before any
-- later Lens Life migration is promoted.
DO $$
DECLARE missing_count integer;
BEGIN
  SELECT count(*) INTO missing_count
  FROM (VALUES
    ('ll_runtime_config'),('ll_feature_flags'),('ll_staff_roles'),('ll_staff_profiles'),('ll_markets'),
    ('ll_service_categories'),('ll_service_offerings'),('ll_customers'),('ll_organisations'),('ll_business_accounts'),
    ('ll_photographers'),('ll_quotes'),('ll_checkout_sessions'),('ll_bookings'),('ll_job_offers'),('ll_booking_assignments'),
    ('ll_jobs'),('ll_deliverables'),('ll_delivery_assets'),('ll_payments'),('ll_refunds'),('ll_photographer_payouts'),
    ('ll_support_cases'),('ll_event_outbox'),('ll_audit_log')
  ) AS required(name)
  WHERE to_regclass('public.'||required.name) IS NULL;
  IF missing_count > 0 THEN
    RAISE EXCEPTION 'Lens Life historical foundation baseline is missing % required tables. Restore from the canonical staging migration before continuing.', missing_count;
  END IF;
END $$;
