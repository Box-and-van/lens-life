# Security and compliance
- RLS enabled on Lens Life tables; public/authenticated table privileges are not used as a shortcut for privileged business operations.
- Supabase secret/service credentials are server-only.
- Server identity uses verified claims; authorisation is resolved from DB-linked user IDs and staff role assignments.
- Private photographer documents and customer galleries are stored in private buckets. Customer assets are returned through short-lived signed URLs after ownership checks.
- Stripe and Resend webhooks require provider signatures and raw payload verification.
- All external integrations fail closed.
- Admin state changes produce audit records.
- Data subject requests, consent, policy versions, retention rules and legal holds have dedicated records.
- Production launch requires review of UK GDPR/privacy copy, controller/processor relationships and retention schedules by the business.
