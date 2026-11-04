const withGame=require('./harness');const fs=require('fs');
withGame(async p=>{
 const out=await p.evaluate(()=>{
  const fn=f=>typeof f=='function'?{fn:f.toString()}:f;
  const ua=u=>u&&u.what?{cookies:u.cookies,cps:u.cps,milk:u.milk,buildings:(()=>{const r=[];for(let i=0;i<u.buildings.length;i+=2)r.push([u.buildings[i].id,u.buildings[i+1]]);return r;})(),upgrades:u.upgrades.map(x=>x.id),achievs:u.achievs.map(x=>x.id),spe:u.spe?u.spe.toString():null}:null;
  const tierKey=t=>t&&typeof t=='object'?(t.name||null):t;
  return {
   tiers:G.tiers?Object.fromEntries(Object.entries(G.tiers).map(([k,t])=>[k,{name:t.name,price:t.price,achievUnlock:t.achievUnlock,upgrade:t.unshackleUpgrade?t.unshackleUpgrade.id:null,special:t.special,color:t.color}])):null,
   buildings:G.buildings.map(b=>({id:b.id,name:b.name,single:b.single,plural:b.plural,actionName:b.actionName,extraName:b.extraName,extraPlural:b.extraPlural,desc:b.desc,pic:b.pic,icon:b.icon,baseCost:b.baseCost,baseCps:b.baseCps,cps:b.cps,cost:b.cost,foolName:b.foolName,foolPlural:b.foolPlural,foolDesc:b.foolDesc,unshackle:b.unshackleUpgrade?b.unshackleUpgrade.id:null})),
   upgrades:G.upgrades.map(u=>({id:u.id,name:u.name,desc:u.desc,q:u.q,icon:u.icon,pool:u.pool,order:u.order,cost:u.cost,power:u.power,tier:tierKey(u.tier),
     effs:u.effs.map(e=>[e[0],typeof e[1]=='function'?{fn:e[1].toString()}:e[1],e[2]]),costFunc:fn(u.costFunc)||null,func:fn(u.func)||null,descFunc:fn(u.descFunc)||null,preDescFunc:fn(u.preDescFunc)||null,qFunc:fn(u.qFunc)||null,iconFunc:fn(u.iconFunc)||null,
     unlockAt:ua(u.unlockAt),unimplemented:u.unimplemented,extra:Object.keys(u).filter(k=>!['unimplemented','effs','id','pool','tier','unlockAt','power','cost','costFunc','func','order','icon','iconFunc','name','q','desc','descFunc','preDescFunc','qFunc','unlocked','owned','ping'].includes(k)&&typeof u[k]!='function')})),
   achievs:G.achievs.map(a=>({id:a.id,name:a.name,desc:a.desc,q:a.q,icon:a.icon,pool:a.pool,order:a.order,tier:tierKey(a.tier),descFunc:fn(a.descFunc)||null,unlockAt:ua(a.unlockAt),unimplemented:a.unimplemented})),
   buffTypes:G.buffTypes.map(t=>({name:t.name,nameD:t.nameD,icon:t.icon,desc:fn(t.desc),t:t.t,pow:t.pow,type:t.type,stackT:t.stackT,stackPow:t.stackPow,init:fn(t.init)||null,effsFunc:fn(t.effsFunc)||null})),
   heavenlyParents:G.HeavenlyUpgradeParents||null,
   upgradePools:Object.fromEntries(Object.entries(G.upgradePools).map(([k,v])=>[k,v.map(u=>u.id)])),
   dragonAuras:G.dragonAuras||null,
  };
 });fs.writeFileSync('data.json',JSON.stringify(out));console.log('ok',fs.statSync('data.json').size);});
