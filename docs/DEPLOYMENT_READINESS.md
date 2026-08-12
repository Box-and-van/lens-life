# Deployment readiness

## Code gates
- `npm ci`
- TypeScript strict typecheck
- Next ESLint rules
- critical route manifest
- production Next build
- staging smoke test of `/api/lens-life/health/live` and `/api/lens-life/health/ready`

## External configuration required before live activation
1. Set the production Supabase URL and publishable + secret keys.
2. Configure Supabase Auth Site URL, allowed redirect URLs and email templates.
3. Set Stripe secret and webhook secret; register `/api/lens-life/webhooks/stripe`.
4. Complete Stripe Connect platform requirements before `LL_ENABLE_STRIPE_PAYOUTS=true`.
5. Set Resend API key, verified sending domain/from address and webhook secret; register `/api/lens-life/webhooks/resend`.
6. Import n8n workflows, set `APP_BASE_URL` and `N8N_AUTOMATION_SECRET`, test retries/idempotency, then enable `LL_ENABLE_N8N=true`.
7. Confirm privacy/legal copy and retention values for the production entity.
8. Complete market readiness and photographer supply checks before enabling public booking in a market.
9. Run end-to-end Stripe test-mode booking, assignment, upload, quality, gallery approval and payout tests.
10. Only then enable public booking/provider flags and promote an approved staging commit to `main`.

No live money movement or communications should be enabled merely because the code deploys successfully.
