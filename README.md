# Lens Life

Deployment-ready managed photography platform for Lens Life. The `staging` branch is the integration and acceptance environment; `main` remains production-controlled.

## Platform surfaces
- Public photography site and booking checkout
- Authenticated customer portal
- Authenticated photographer onboarding/operations portal
- Authenticated recurring-B2B portal
- Role-gated internal Lens Life admin console
- Supabase Postgres + private/public Storage
- Stripe Checkout + signed webhooks + Stripe Connect payout onboarding
- Resend operational email + signed webhook
- Durable n8n outbox worker contract

## Safety defaults
All external actions fail closed. Public booking, Stripe, Stripe payouts, Resend, n8n and marketing sends are disabled unless the matching environment flag is explicitly `true` and its secret exists.

## Run
```bash
cp .env.example .env.local
npm ci
npm run dev
```

## Validate
```bash
npm run validate
```

See `docs/DEPLOYMENT_READINESS.md` and `docs/ARCHITECTURE.md` before enabling production integrations.
