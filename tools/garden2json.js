// Exports the desktop Garden's plant list (names, timings, effects text) to JSON for the Swift app.
const fs=require('fs');
const src=fs.readFileSync(process.argv[2],'utf8');
const a=src.indexOf('M.plants={'), b=src.indexOf('M.plantsById=[];');
const loc=(s,p)=>{if(p===undefined)return s;const arr=Array.isArray(p)?p:[p];return s.replace(/%(\d)/g,(m,i)=>arr[i-1]);};
const cap=s=>s.charAt(0).toUpperCase()+s.slice(1);
const Game={Objects:{Grandma:{single:'grandma'},Cursor:{single:'cursor'}},sayTime:(t)=>Math.round(t/30/60)+' minutes',fps:30};
const M={};
new Function('M','loc','Game','Beautify','cap','EN','choose','PlaySound',src.slice(a,b))(M,loc,Game,String,cap,true,x=>x[0],()=>0);
const out=[];let n=0;
for(const k in M.plants){const p=M.plants[k];out.push({key:k,id:n++,name:p.name,icon:p.icon,cost:p.cost,costM:p.costM,ageTick:p.ageTick,ageTickR:p.ageTickR,mature:p.mature,children:p.children,effs:p.effsStr,q:p.q||'',weed:!!p.weed,fungus:!!p.fungus,immortal:!!p.immortal,noContam:!!p.noContam,contam:p.contam||0,plantable:p.plantable!==false,details:p.detailsStr||''});}
fs.writeFileSync(process.argv[3],JSON.stringify(out));
console.log(out.length, out.map(p=>p.key+(p.contam?'(c'+p.contam+')':'')+(p.plantable?'':'(np)')).join(' '));
