import 'server-only'; import { Resend } from 'resend'; import { env } from '@/lib/env';
export function resend(){const e=env();if(!e.LL_ENABLE_RESEND||!e.RESEND_API_KEY) throw new Error('Resend is disabled or not configured');return new Resend(e.RESEND_API_KEY);}
