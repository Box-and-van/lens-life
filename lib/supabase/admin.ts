import 'server-only';
import { createClient } from '@supabase/supabase-js';
import { publicEnv, requireServerSecret } from '@/lib/env';
export function adminDb(){ const e=publicEnv(); return createClient(e.url,requireServerSecret(),{auth:{persistSession:false,autoRefreshToken:false}}); }
