import { createBrowserClient } from '@supabase/ssr';
import { publicEnv } from '@/lib/env';
export function createClient(){ const e=publicEnv(); return createBrowserClient(e.url,e.key); }
