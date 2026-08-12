import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { publicEnv } from '@/lib/env';
export async function createClient(){
  const store=await cookies(); const e=publicEnv();
  return createServerClient(e.url,e.key,{cookies:{
    getAll(){return store.getAll()},
    setAll(items){try{items.forEach(({name,value,options})=>store.set(name,value,options))}catch{}},
  }});
}
