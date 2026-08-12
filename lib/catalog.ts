export type Service={key:string;category:string;name:string;price:number;duration:string;deliverables:string};
export const services:Service[]=[
{key:'portrait_mini',category:'Portrait & Lifestyle',name:'Mini',price:10000,duration:'30 minutes',deliverables:'10 edited images'},
{key:'portrait_standard',category:'Portrait & Lifestyle',name:'Standard',price:18000,duration:'1 hour',deliverables:'25 edited images'},
{key:'portrait_premium',category:'Portrait & Lifestyle',name:'Premium',price:30000,duration:'2 hours',deliverables:'50 edited images'},
{key:'event_small',category:'Events',name:'Small Event',price:25000,duration:'2 hours',deliverables:'~60 edited images'},
{key:'event_half_day',category:'Events',name:'Half Day',price:45000,duration:'4 hours',deliverables:'~150 edited images'},
{key:'event_full_day',category:'Events',name:'Full Day',price:80000,duration:'8 hours',deliverables:'~300 edited images'},
{key:'business_headshots',category:'Business & Branding',name:'Headshots',price:25000,duration:'1 hour',deliverables:'Up to 10 staff'},
{key:'business_branding',category:'Business & Branding',name:'Branding',price:40000,duration:'2 hours',deliverables:'40 edited images'},
{key:'business_product',category:'Business & Branding',name:'Product',price:30000,duration:'Session',deliverables:'Up to ~20 products'},
{key:'wedding_half_day',category:'Weddings',name:'Half Day Wedding',price:70000,duration:'5 hours',deliverables:'~300 edited images'},
{key:'wedding_full_day',category:'Weddings',name:'Full Day Wedding',price:120000,duration:'8–10 hours',deliverables:'~500 edited images'},
{key:'property_1_2_bed',category:'Property',name:'1–2 Bedroom',price:12000,duration:'Property session',deliverables:'Edited property set'},
{key:'property_3_4_bed',category:'Property',name:'3–4 Bedroom',price:18000,duration:'Property session',deliverables:'Edited property set'},
{key:'property_5_plus',category:'Property',name:'5+ Bedroom',price:24000,duration:'Property session',deliverables:'Edited property set'},
];
