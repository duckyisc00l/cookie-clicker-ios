const withGame=require('./harness');const fs=require('fs');
withGame(async p=>{
 const out=await p.evaluate(()=>{
  const names=a=>(a||[]).map(x=>typeof x=='string'?x:x.name);
  const r={fps:G.fps,HCfactor:G.HCfactor,positions:G.HeavenlyUpgradePositions,lasting:names(G.lastingUpgrades),
   santaDrops:names(G.santaDrops),reindeerDrops:names(G.reindeerDrops),heartDrops:names(G.heartDrops),halloweenDrops:names(G.halloweenDrops),eggDrops:names(G.eggDrops),rareEggDrops:names(G.rareEggDrops),easterEggs:names(G.easterEggs),
   goldenCookieUpgrades:names(G.goldenCookieUpgrades),seasonTriggerBasePrice:G.seasonTriggerBasePrice,
   seasons:Object.fromEntries(Object.entries(G.seasons||{}).map(([k,s])=>[k,{name:s.name,start:s.start,over:s.over,trigger:s.trigger,triggerUpgrade:s.triggerUpgrade&&s.triggerUpgrade.name}])),
   dragonLevels:(G.dragonLevels||[]).map(d=>({name:d.name,action:d.action,pic:d.pic,cost:d.cost?d.cost.toString():null,buy:d.buy?d.buy.toString():null,costStr:d.costStr?d.costStr.toString():null})),
   dragonAuras:Object.fromEntries(Object.entries(G.dragonAuras||{}).map(([k,a])=>[k,{name:a.name,desc:a.desc,pic:a.pic}])),
   santaLevels:G.santaLevels,milks:(G.milks||G.Milks||[]).map(m=>({name:m.name,pic:m.pic,icon:m.icon})),
   permanentSlots:G.permanentUpgrades,
   ticker:G.getTicker.toString(),
   gkeys:Object.keys(G).filter(k=>typeof G[k]!='function').slice(0,600)};
  return r;});
 fs.writeFileSync('data2.json',JSON.stringify(out));console.log(Object.keys(out).map(k=>k+':'+JSON.stringify(out[k]).length).join(' '));console.log(out.fps,out.HCfactor,JSON.stringify(out.seasons),JSON.stringify(out.dragonLevels).slice(0,1500));});
