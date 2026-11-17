const sharp=require('sharp');
(async()=>{for(const f of process.argv.slice(2)){const{data,info}=await sharp(f).ensureAlpha().raw().toBuffer({resolveWithObject:true});
const h=new Map();for(let i=0;i<data.length;i+=4){if(data[i+3]<200)continue;const k=((data[i]>>4)<<8)|((data[i+1]>>4)<<4)|(data[i+2]>>4);h.set(k,(h.get(k)||0)+1);}
const tot=[...h.values()].reduce((a,b)=>a+b,0);const top=[...h.entries()].sort((a,b)=>b[1]-a[1]).slice(0,10);
console.log(f.split('/').slice(-2).join('/'),top.map(([k,c])=>'#'+[k>>8,(k>>4)&15,k&15].map(v=>(v*17+8).toString(16).padStart(2,'0')).join('')+'('+(100*c/tot).toFixed(0)+'%)').join(' '));}})();
