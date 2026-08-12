# Architecture

Lens Life is a Next.js 16 App Router application with Supabase as system-of-record. Browser code receives only the Supabase publishable key. Privileged writes run through authenticated server routes and a server-only Supabase secret client. SSR identity is validated with `getClaims()` and platform roles are resolved from Lens Life database records rather than editable user metadata.

## Domains
Public acquisition → quote/booking → Stripe Checkout → signed Stripe webhook → atomic payment RPC → durable outbox → eligible photographer offer → assignment/job → private upload → quality review → private gallery release → customer approval → reconciliation → delayed photographer payout.

B2B accounts add organisations, contacts, sites, reusable booking templates, contracts, recurring bookings, central billing and reporting. Internal consoles expose operations, supply, finance, sales, support, privacy, content, SEO, marketing, referrals, suppliers, expansion, monitoring and releases.

## State integrity
The database enforces one active photographer assignment per booking. Offer acceptance, payment success and payout eligibility are protected by transactional RPCs and idempotency constraints. Outbox work is claimed using row locking/leases and can be completed or retried safely.
