# Testing strategy
1. Static gates: typecheck, lint, route manifest, production build.
2. Auth: customer/photographer/business/staff users cannot cross console boundaries.
3. Booking: duplicate idempotency keys reuse checkout and never duplicate bookings/charges.
4. Stripe webhook: invalid signatures rejected; repeated event IDs are idempotent.
5. Dispatch: only approved, service-enabled, coverage/availability eligible photographers offered work; concurrent accept cannot create multiple active assignments.
6. Delivery: unauthorised uploads/gallery reads rejected; gallery signed URLs expire.
7. Quality: failed reviews do not release galleries; passed reviews do.
8. Payout: cannot schedule before completed delivery + reconciliation; repeated scheduling/transfer is idempotent.
9. Email/n8n: provider flags off => no external side effect; retries do not duplicate notifications.
10. B2B: contacts see only their organisation account and related sites/bookings/billing.
