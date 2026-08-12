export const PLATFORM_MARGIN_BPS=2000; export const PHOTOGRAPHER_SHARE_BPS=8000; export const DEFAULT_PAYOUT_DELAY_DAYS=5;
export function split(total:number){return {platform:Math.round(total*PLATFORM_MARGIN_BPS/10000),photographer:Math.round(total*PHOTOGRAPHER_SHARE_BPS/10000)}}
export function money(pence:number|string|null|undefined,currency='GBP'){return new Intl.NumberFormat('en-GB',{style:'currency',currency}).format(Number(pence||0)/100)}
