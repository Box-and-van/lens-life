import 'server-only'; import Stripe from 'stripe'; import { env } from '@/lib/env';
export function stripe(){const e=env();if(!e.LL_ENABLE_STRIPE||!e.STRIPE_SECRET_KEY) throw new Error('Stripe is disabled or not configured');return new Stripe(e.STRIPE_SECRET_KEY);}
