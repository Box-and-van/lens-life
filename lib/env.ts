import { z } from 'zod';

const truthy = z.string().optional().transform(v => v === 'true');
const serverSchema = z.object({
  NEXT_PUBLIC_APP_URL: z.string().url().default('http://localhost:3000'),
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z.string().min(1),
  SUPABASE_SECRET_KEY: z.string().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  STRIPE_SECRET_KEY: z.string().optional(),
  STRIPE_WEBHOOK_SECRET: z.string().optional(),
  RESEND_API_KEY: z.string().optional(),
  RESEND_WEBHOOK_SECRET: z.string().optional(),
  RESEND_FROM_EMAIL: z.string().optional(),
  N8N_AUTOMATION_SECRET: z.string().optional(),
  LL_ENABLE_PUBLIC_BOOKING: truthy,
  LL_ENABLE_STRIPE: truthy,
  LL_ENABLE_STRIPE_PAYOUTS: truthy,
  LL_ENABLE_RESEND: truthy,
  LL_ENABLE_N8N: truthy,
  LL_ENABLE_MARKETING_SEND: truthy,
  APP_DEMO_MODE: truthy,
});
export function env(){ return serverSchema.parse(process.env); }
export function publicEnv(){
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if(!url||!key) throw new Error('Supabase public environment is not configured');
  return {url,key};
}
export function requireServerSecret(){
  const e=env(); const key=e.SUPABASE_SECRET_KEY || e.SUPABASE_SERVICE_ROLE_KEY;
  if(!key) throw new Error('SUPABASE_SECRET_KEY is required');
  return key;
}
