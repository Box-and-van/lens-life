import Link from 'next/link';
export function PortalNav({base,items}:{base:string;items:string[]}){return <div className="portalnav"><Link href={base}>Overview</Link>{items.map(x=><Link key={x} href={`${base}/${x}`}>{x.replaceAll('-',' ')}</Link>)}</div>}
