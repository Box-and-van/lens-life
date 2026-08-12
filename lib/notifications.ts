import 'server-only'; import { adminDb } from '@/lib/supabase/admin'; import { env } from '@/lib/env'; import { resend } from '@/lib/resend';
export async function sendOperationalEmail(input:{to:string;subject:string;html:string;dedupe:string;recipientType?:string;recipientId?:string}){
 const db=adminDb(); const existing=await db.from('ll_notification_deliveries').select('id,status').eq('deduplication_key',input.dedupe).maybeSingle(); if(existing.data) return existing.data;
 const {data,error}=await db.from('ll_notification_deliveries').insert({destination:input.to,deduplication_key:input.dedupe,communication_class:'operational',recipient_type:input.recipientType,recipient_id:input.recipientId,status:'queued'}).select('id').single(); if(error) throw error;
 const e=env(); if(!e.LL_ENABLE_RESEND) return data; const sent=await resend().emails.send({from:e.RESEND_FROM_EMAIL!,to:input.to,subject:input.subject,html:input.html}); if(sent.error) throw sent.error;
 await db.from('ll_notification_deliveries').update({provider_message_id:sent.data?.id,status:'sent',sent_at:new Date().toISOString()}).eq('id',data.id); return data;
}
