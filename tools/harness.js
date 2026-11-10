const {chromium,devices}=require('playwright');const fs=require('fs'),path=require('path');
const ROOT='/home/claude/cookie-clicker-ios/CookieClicker',WWW=ROOT+'/www';
const sw=fs.readFileSync(ROOT+'/CordovaBridgeScript.swift','utf8');const bridge=sw.slice(sw.indexOf('#"""\n')+5,sw.indexOf('"""#'));
const CT={html:'text/html',js:'text/javascript',css:'text/css',png:'image/png',jpg:'image/jpeg',mp3:'audio/mpeg',ttf:'font/ttf',gif:'image/gif',webp:'image/webp',json:'application/json'};
function patchMain(js){const P=[
 ["'You':['Deduplication','Clone strike'],","'You':['Deduplication','Clone strike'],'Black hole':['Event horizon','Evaporation'],'Galaxy':['Starburst','Galactic drift'],'Multiverse mixer':['Perfect blend','Lumpy batter'],'Big bang':['Cosmic dawn','Heat death'],"],
 ["'tippedN'];","'tippedN','lumps','lumpsTotal','lumpT','lumpCurrentType','lumpRefill'];"],
 ["var transfer=['amount','amountMax','bought','cookiesMade'];","var transfer=['amount','amountMax','bought','cookiesMade','level'];"],
 ["myCps=(myCps+G.pool['building'+me.id+'A'])*G.pool['building'+me.id+'M'];","myCps=(myCps+G.pool['building'+me.id+'A'])*G.pool['building'+me.id+'M']*(1+(me.level||0)*0.01);"],
 ['<p class="switchTopIn" style="text-align:right;color:rgba(255,255,255,0.65);"><q>${me.getDesc()}</q></p>','${window.__ccLevelBox?window.__ccLevelBox(me):\'\'}<p class="switchTopIn" style="text-align:right;color:rgba(255,255,255,0.65);"><q>${me.getDesc()}</q></p>']];
 for(const [a,b] of P){if(!js.includes(a))console.log('PATCH MISSING',a.slice(0,50));js=js.split(a).join(b);}return js;}
module.exports=async function withGame(fn){const b=await chromium.launch();const ctx=await b.newContext({...devices['iPhone 14 Pro Max']});
 await ctx.route('http://app.test/**',r=>{let u=decodeURIComponent(new URL(r.request().url()).pathname.slice(1))||'index.html';
  if(u=='cordova.js')return r.fulfill({body:bridge,contentType:'text/javascript'});
  let body;
  if(u=='main.js')body=patchMain(fs.readFileSync(path.join(WWW,u),'utf8'));
  else if(u=='data.js')body=fs.readFileSync(path.join(WWW,u),'utf8')+'\n;\n'+fs.readFileSync(ROOT+'/mods/more-content.js','utf8')+'\n;\n'+fs.readFileSync(ROOT+'/mods/sugar-lumps.js','utf8');
  else if(u=='img/icons.png'||u=='img/buildings.png')body=fs.readFileSync(ROOT+'/mods/'+path.basename(u));
  else{const p=u.startsWith('hd/')?path.join(ROOT,u):path.join(WWW,u);if(!fs.existsSync(p))return r.fulfill({status:404,body:''});body=fs.readFileSync(p);
   if(u=='index.html')body=body.toString().replace(/<meta name="viewport"[^>]*>/i,'<meta name="viewport" content="width=320, user-scalable=no, viewport-fit=cover">');}
  r.fulfill({body,contentType:CT[path.extname(u).slice(1)]||'application/octet-stream'});});
 const seed=process.argv[2]?fs.readFileSync(process.argv[2],'utf8'):'{}';
 await ctx.addInitScript(s=>{window.__files=JSON.parse(s);window.webkit={messageHandlers:{native:{postMessage:function(m){var a=m.args,f=__files,r;
 switch(m.action){case 'getFile':if(!(a.name in f)){if(a.create)f[a.name]='';else{r=false;break;}}r=true;break;case 'readFile':r=f[a.name]||'';break;case 'writeFile':f[a.name]=a.data;r=true;break;case 'listFiles':r=Object.keys(f);break;default:r=true;}return Promise.resolve(r);}}}};},seed);
 const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));
 await p.goto('http://app.test/index.html');await p.waitForFunction(()=>window.G&&G.buildings&&document.getElementById('bigCookie'));
 await p.evaluate(()=>__ccSafeInsets(59,34,430));await p.waitForTimeout(1500);

 const r=await fn(p,errs);await b.close();return r;};
