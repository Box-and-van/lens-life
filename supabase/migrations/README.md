# Database migrations

The staging project is the canonical database currently targeted by Lens Life. The original foundation migration was executed before repository source control was connected, so its repository file is an explicit baseline assertion rather than a fabricated recreation of 58k of already-applied SQL. Later migration history is validated by version/name and the application additionally checks the runtime contract through health/readiness gates.

For a brand-new isolated Supabase project, first export/pull the canonical Lens Life schema from staging using the Supabase CLI, review it, then replay subsequent migrations. Do not pretend the baseline marker creates the 120-table platform.
