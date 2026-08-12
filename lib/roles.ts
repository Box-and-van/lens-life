import 'server-only';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { adminDb } from '@/lib/supabase/admin';
export type Actor={userId:string;email?:string;customerId?:string;photographerId?:string;businessAccountId?:string;staffId?:string;roles:string[]};
export async function getActor():Promise<Actor|null>{
  const auth=await createClient(); const {data}=await auth.auth.getClaims(); const claims=data?.claims as {sub?:string,email?:string}|undefined;
  if(!claims?.sub) return null;
  const fresh=await auth.auth.getUser(); const email=fresh.data.user?.email?.toLowerCase(); const confirmed=!!fresh.data.user?.email_confirmed_at;
  const db=adminDb();
  if(email&&confirmed){
    await Promise.all([
      db.from('ll_customers').update({user_id:claims.sub}).eq('email',email).is('user_id',null),
      db.from('ll_photographers').update({user_id:claims.sub}).ilike('email',email).is('user_id',null),
      db.from('ll_staff_profiles').update({user_id:claims.sub}).ilike('email',email).is('user_id',null),
      db.from('ll_organisation_contacts').update({user_id:claims.sub}).ilike('email',email).is('user_id',null),
    ]);
  }
  let c=await db.from('ll_customers').select('id').eq('user_id',claims.sub).maybeSingle();
  if(!c.data&&email&&confirmed){const ins=await db.from('ll_customers').insert({user_id:claims.sub,email,status:'active'}).select('id').single();if(!ins.error)c=ins as any}
  const [p,s,oc]=await Promise.all([
    db.from('ll_photographers').select('id').eq('user_id',claims.sub).maybeSingle(),
    db.from('ll_staff_profiles').select('id').eq('user_id',claims.sub).eq('status','active').maybeSingle(),
    db.from('ll_organisation_contacts').select('id,organisation_id').eq('user_id',claims.sub).maybeSingle(),
  ]);
  let businessAccountId:string|undefined;if(oc.data?.organisation_id){const b=await db.from('ll_business_accounts').select('id').eq('organisation_id',oc.data.organisation_id).maybeSingle();businessAccountId=b.data?.id}
  let roles:string[]=[];if(s.data?.id){const r=await db.from('ll_staff_role_assignments').select('ll_staff_roles(role_key)').eq('staff_profile_id',s.data.id);roles=(r.data||[]).map((x:any)=>x.ll_staff_roles?.role_key).filter(Boolean)}
  return {userId:claims.sub,email:email||claims.email,customerId:c.data?.id,photographerId:p.data?.id,businessAccountId,staffId:s.data?.id,roles};
}
export async function requireActor(kind:'customer'|'photographer'|'business'|'staff'){
  const a=await getActor();const ok=a&&(kind==='customer'?a.customerId:kind==='photographer'?a.photographerId:kind==='business'?a.businessAccountId:a.staffId);
  if(!ok)redirect('/auth/login?next='+encodeURIComponent(kind==='staff'?'/admin/lens-life':kind==='photographer'?'/photography/portal':kind==='business'?'/photography/business/portal':'/photography/customer'));
  return a!;
}
