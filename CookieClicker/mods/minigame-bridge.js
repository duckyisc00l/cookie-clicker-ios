/*
	Minigames for the iOS app: Garden (Farm), Stock Market (Bank), Pantheon (Temple) and Grimoire (Wizard tower).
	They are the desktop game's own minigame files, running in a frame (mods/minigames/index.html) on top of the
	phone game. A building's minigame unlocks once the building is level 1 (sugar lumps), like on desktop.
	This file connects them to the phone game: their effects, buffs, achievements, saving, and the window they show in.
*/
G.addData(function(){
	const HOUR=1000*60*60;

	//---- achievements from the minigames
	const ACHIEVS=[
		['Bibbidi-bobbidi-boo','Cast <b>9</b> spells.',[21,11]],
		["I'm the wiz",'Cast <b>99</b> spells.',[22,11]],
		['A wizard is you',"Cast <b>999</b> spells.<q>I'm a what?</q>",[29,11]],
		['Botany enthusiast','Harvest <b>100</b> mature garden plants.',[26,20]],
		['Green, aching thumb','Harvest <b>1,000</b> mature garden plants.',[27,20]],
		['In the garden of Eden (baby)',"Fill every tile of the biggest garden plot with plants.<q>Isn't tending to those precious little plants just so rock and/or roll?</q>",[28,20]],
		['Keeper of the conservatory','Unlock every garden seed.',[25,20]],
		['Seedless to nay','Convert a complete seed log into sugar lumps by sacrificing your garden to the sugar hornets.<div class="line"></div>Owning this achievement makes seeds <b>5% cheaper</b>, plants mature <b>5% sooner</b>, and plant upgrades drop <b>5% more</b>.',[29,20]],
		['Initial public offering','Make your first stock market profit.',[0,33]],
		['Rookie numbers','Own at least <b>100</b> of every stock market good.<q>Gotta pump those numbers up!</q>',[9,33]],
		['No nobility in poverty','Own at least <b>500</b> of every stock market good.<q>What kind of twisted individual is out there cramming camels through needle holes anyway?</q>',[10,33]],
		['Full warehouses','Own at least <b>1,000</b> of a stock market good.',[11,33]],
		['Make my day','Make <b>a day</b> of CpS ($86,400) in 1 stock market sale.',[1,33]],
		['Buy buy buy','Spend <b>a day</b> of CpS ($86,400) in 1 stock market purchase.',[1,33]],
		['Liquid assets','Have your stock market profits surpass <b>$10,000,000</b>.',[12,33]],
		['Gaseous assets','Have your stock market profits surpass <b>a whole year</b> of CpS ($31,536,000).<q>Boy, how volatile!</q>',[18,33],'shadow'],
		['Pyramid scheme','Unlock the <b>highest-tier</b> stock market headquarters.',[18,33]],
	];
	ACHIEVS.forEach(function(a,i){
		if (G.achievsBN && G.achievsBN[a[0]]) return;
		let o={name:a[0],id:2300+i,desc:a[1],icon:a[2],order:62000+i};
		if (a[3]) o.pool=a[3];
		new G.Achiev(o);
	});

	//---- buffs the minigames give (same names, numbers and wording as the desktop game)
	const pct=function(me){return B(me.pow);};
	const BUFFS=[
		['haggler luck',"Haggler's luck",[25,11],1,me=>[['upgradeCostM',1-me.pow/100,1]],me=>`All upgrades are ${pct(me)}% cheaper for [t]!`],
		['haggler misery',"Haggler's misery",[25,11],2,me=>[['upgradeCostM',1+me.pow/100,1]],me=>`All upgrades are ${pct(me)}% pricier for [t]!`],
		['pixie luck','Crafty pixies',[26,11],1,me=>[['buildingCostM',1-me.pow/100,1]],me=>`All buildings are ${pct(me)}% cheaper for [t]!`],
		['pixie misery','Nasty goblins',[26,11],2,me=>[['buildingCostM',1+me.pow/100,1]],me=>`All buildings are ${pct(me)}% pricier for [t]!`],
		['magic adept','Magic adept',[29,11],1,me=>[],me=>`Spells backfire ${B(me.pow)} times less for [t].`],
		['magic inept','Magic inept',[29,11],2,me=>[],me=>`Spells backfire ${B(me.pow)} times more for [t].`],
		['devastation','Devastation',[23,18],1,me=>[['clickM',me.pow,1]],me=>`Clicking power +${Math.floor(me.pow*100-100)}% for [t]!`],
		['sugar blessing','Sugar blessing',[29,16],1,me=>[['gcFreqM',1.1,1]],me=>`You find 10% more golden cookies for the next [t].`],
		['loan 1','Loan 1',[1,33],1,me=>[['cpsBuffM',me.pow,1]],me=>`Cookie production x${B(me.pow,2)} for [t]!`],
		['loan 1 interest','Loan 1 (interest)',[1,33],2,me=>[['cpsBuffM',me.pow,1]],me=>`Cookie production x${B(me.pow,2)} for [t]!`],
		['loan 2','Loan 2',[1,33],1,me=>[['cpsBuffM',me.pow,1]],me=>`Cookie production x${B(me.pow,2)} for [t]!`],
		['loan 2 interest','Loan 2 (interest)',[1,33],2,me=>[['cpsBuffM',me.pow,1]],me=>`Cookie production x${B(me.pow,2)} for [t]!`],
		['loan 3','Loan 3',[1,33],1,me=>[['cpsBuffM',me.pow,1]],me=>`Cookie production x${B(me.pow,2)} for [t]!`],
		['loan 3 interest','Loan 3 (interest)',[1,33],2,me=>[['cpsBuffM',me.pow,1]],me=>`Cookie production x${B(me.pow,2)} for [t]!`],
	];
	BUFFS.forEach(function(b){
		if (G.buffTypesBN[b[0]]) return;
		new G.buffType({name:b[0],nameD:b[1],icon:b[2],type:b[3],effsFunc:b[4],desc:b[5],t:60,pow:1,stackT:2,stackPow:2});
	});
	//show a toast when a minigame gives a buff
	G.toastBuff=function(me)
	{
		if (!me || !me.type) return;
		G.toast(me.type.nameD,me.type.desc(me).replaceAll('[t]',sayTime(me.tm*1000,-1)),me.type.icon);
	};

	//---- the minigame frame
	const MG={'Farm':'Garden','Bank':'Stock Market','Temple':'Pantheon','Wizard tower':'Grimoire'};
	let frame=null, frameReady=false, shown=0;
	const F=function(){return (frame && frameReady && frame.contentWindow && frame.contentWindow.Game)?frame.contentWindow.Game:null;};
	G.minigameGame=F;

	const css=document.createElement('style');
	css.textContent=`
		#ccMinigame{position:fixed;left:0;top:0;width:320px;height:100%;z-index:1000000;display:none;background:#000 url(img/darkNoise.jpg);}
		#ccMinigame.on{display:block;}
		#ccMinigameBar{position:absolute;left:0;right:0;top:0;height:calc(var(--cc-sat,0px) + 36px);padding-top:var(--cc-sat,0px);box-sizing:border-box;background:url(img/woodPanels.png);background-size:320px auto;box-shadow:0 2px 4px rgba(0,0,0,0.6);z-index:2;}
		#ccMinigameTitle{position:absolute;left:10px;bottom:6px;font-family:Fancy,Georgia,serif;font-size:20px;color:#fff;text-shadow:0 0 2px #000,1px 1px 1px #000;}
		#ccMinigameLevel{position:absolute;left:10px;bottom:-12px;font-size:9px;color:rgba(255,255,255,0.7);}
		#ccMinigameClose{position:absolute;right:8px;bottom:5px;width:72px;height:24px;line-height:24px;text-align:center;font-family:Fancy,Georgia,serif;font-size:14px;color:#ccc;text-shadow:1px 1px 0 #000;
			background:linear-gradient(rgba(255,255,255,0.1),rgba(0,0,0,0.1));border-radius:4px;box-shadow:0 0 0 1px #000 inset,0 2px 0 rgba(255,255,255,0.2) inset;}
		#ccMinigameFrameBox{position:absolute;left:0;right:0;top:calc(var(--cc-sat,0px) + 36px);bottom:0;overflow:hidden;}
		#ccMinigameFrame{position:absolute;left:0;top:0;border:0;transform-origin:0 0;background:transparent;}
		.ccMinigameOpen{margin-top:6px!important;}
		.ccMinigameNote{font-size:85%;color:rgba(255,255,255,0.7);}
	`;
	document.head.appendChild(css);

	//how much the desktop layout is shrunk to fit the phone (desktop minigames are ~430px wide)
	const SCALE=1;
	const layout=function()
	{
		const box=document.getElementById('ccMinigameFrameBox');
		if (!box || !frame) return;
		frame.style.width=Math.ceil(320/SCALE)+'px';
		frame.style.height=Math.ceil(box.clientHeight/SCALE)+'px';
		frame.style.transform='scale('+SCALE+')';
	};
	const build=function()
	{
		if (document.getElementById('ccMinigame')) return;
		const host=document.getElementById('game')||document.body;
		const el=document.createElement('div');
		el.id='ccMinigame';
		el.innerHTML='<div id="ccMinigameBar"><div id="ccMinigameTitle"></div><div id="ccMinigameClose">Close</div></div><div id="ccMinigameFrameBox"><iframe id="ccMinigameFrame" src="minigames/index.html"></iframe></div>';
		host.appendChild(el);
		frame=document.getElementById('ccMinigameFrame');
		document.getElementById('ccMinigameClose').addEventListener('click',function(){PlaySound('snd/clickOff2.mp3',0.5);window.__ccCloseMinigame();});
		window.addEventListener('resize',layout);
		layout();
	};
	window.__ccMinigamePageReady=function(){frameReady=true;layout();G.refreshCps=1;};
	window.__ccMinigameReady=function(name){G.refreshCps=1;};
	window.__ccOpenMinigame=function(buildingName)
	{
		const b=G.buildingsBN[buildingName];
		if (!b || !(b.level>0)) return;
		build();
		const open=function()
		{
			const g=F();
			if (!g) {setTimeout(open,100);return;}
			g.ccLoad(buildingName);
			g.ccShow(buildingName);
			shown=buildingName;
			document.getElementById('ccMinigameTitle').textContent=MG[buildingName];
			document.getElementById('ccMinigame').classList.add('on');
			layout();
		};
		if (G.closePopup) G.closePopup();
		PlaySound('snd/clickOn2.mp3',0.5);
		open();
	};
	window.__ccCloseMinigame=function()
	{
		const el=document.getElementById('ccMinigame');
		if (el) el.classList.remove('on');
		const g=F();
		if (g) {g.ccShow(0);if (g.ClosePrompt && g.promptOn) g.ClosePrompt();}
		shown=0;
	};

	//---- the building info popup: open the minigame, or say how to unlock it
	const levelBox=window.__ccLevelBox;
	window.__ccLevelBox=function(me)
	{
		let str=levelBox?levelBox(me):'';
		if (!MG[me.name] || !G.canLumps() || G.lumpT<=0) return str;
		if ((me.level||0)>=1)
		{
			str+=`<div style="text-align:center;">`+G.button({text:`Open ${MG[me.name]}`,classes:'bumpButton ccMinigameOpen',onclick:function(){window.__ccOpenMinigame(me.name);}})+`</div>`;
		}
		else str+=`<div class="ccMinigameNote" style="text-align:center;">Levelling up your ${me.plural} unlocks the <b>${MG[me.name]}</b> minigame.</div>`;
		return str;
	};
	//a level-up loads the minigame right away
	const levelUp=G.levelUpBuilding;
	G.levelUpBuilding=function(me)
	{
		const r=levelUp.apply(this,arguments);
		if (r && MG[me.name]) {build();const g=F();if (g) g.ccLoadAll();if (me.level==1) G.toast(`${MG[me.name]} unlocked!`,`Open it from your ${me.plural}' info in the Store.`,me.icon);}
		return r;
	};

	//---- gods (Pantheon) and plants (Garden) change the game's numbers
	G.hasGod=function(what){const g=F();return (g && g.hasGod)?g.hasGod(what):0;};
	window.__ccMinigameEffs=function(pool)
	{
		const g=F();
		if (!g) return;
		//garden plants
		const garden=g.ccLoaded&&g.ccLoaded['Farm'];
		if (garden && garden.effs)
		{
			const e=garden.effs;
			const map={cps:'cpsM',click:'clickM',cursorCps:'building0M',grandmaCps:'building1M',goldenCookieGain:'gcEffectsMultM',goldenCookieFreq:'gcFreqM',
				goldenCookieDur:'gcLifeM',goldenCookieEffDur:'gcEffectsLifeM',wrathCookieGain:'gcWrathEffectsMultM',wrathCookieFreq:'gcFreqM',wrathCookieDur:'gcWrathLifeM',
				wrathCookieEffDur:'gcWrathEffectsLifeM',reindeerGain:'reindeerEffectsMultM',reindeerFreq:'reindeerFreqM',reindeerDur:'reindeerLifeM',itemDrops:'dropChanceM',
				milk:'milkPowerM',upgradeCost:'upgradeCostM',buildingCost:'buildingCostM'};
			for (const k in map)
			{
				if (k=='wrathCookieFreq') continue;//golden and wrath cookies share one timer in the phone game
				if (typeof e[k]==='number' && typeof pool[map[k]]==='number') pool[map[k]]*=e[k];
			}
		}
		//gods
		if (!g.hasGod) return;
		let lvl;
		let mult=1, build=1;
		lvl=g.hasGod('asceticism');if (lvl==1) mult*=1.15;else if (lvl==2) mult*=1.1;else if (lvl==3) mult*=1.05;
		lvl=g.hasGod('ages');if (lvl) mult*=1+0.15*Math.sin((Date.now()/1000/(60*60*[0,3,12,24][lvl]))*Math.PI*2);
		lvl=g.hasGod('decadence');if (lvl==1) build*=0.93;else if (lvl==2) build*=0.95;else if (lvl==3) build*=0.98;
		lvl=g.hasGod('industry');if (lvl==1) build*=1.1;else if (lvl==2) build*=1.06;else if (lvl==3) build*=1.03;
		if (lvl) pool['gcFreqM']/=[1,1.1,1.06,1.03][lvl];
		lvl=g.hasGod('labor');if (lvl==1) build*=0.97;else if (lvl==2) build*=0.98;else if (lvl==3) build*=0.99;
		if (lvl) pool['clickM']*=[1,1.15,1.1,1.05][lvl];
		lvl=g.hasGod('decadence');if (lvl) {pool['gcEffectsLifeM']*=[1,1.07,1.05,1.02][lvl];pool['gcWrathEffectsLifeM']*=[1,1.07,1.05,1.02][lvl];}
		lvl=g.hasGod('mother');if (lvl) {pool['milkPowerM']*=[1,1.1,1.05,1.03][lvl];pool['gcFreqM']/=[1,1.15,1.1,1.05][lvl];}
		lvl=g.hasGod('seasons');if (lvl && G.season!='' && G.season!='fools') pool['gcFreqM']/=[1,0.97,0.98,0.99][lvl];
		lvl=g.hasGod('creation');if (lvl) pool['buildingCostM']*=[1,0.93,0.95,0.98][lvl];
		pool['cpsM']*=mult;
		for (let i=0;i<G.buildings.length;i++) {if (typeof pool['building'+i+'M']==='number') pool['building'+i+'M']*=build;}
	};
	//Dotjeiess: heavenly chips have less effect
	if (G.GetHeavenlyMultiplier)
	{
		const hm=G.GetHeavenlyMultiplier;
		G.GetHeavenlyMultiplier=function(){let m=hm.apply(this,arguments);const l=G.hasGod('creation');if (l) m*=[1,0.7,0.8,0.9][l];return m;};
	}
	//Rigidel: sugar lumps ripen sooner while your building count ends in 0
	const rigidel=function()
	{
		const l=G.hasGod('order');
		if (!l) return 0;
		let n=0;for (let i=0;i<G.buildings.length;i++) n+=G.buildings[i].amount;
		if (n%10!=0) return 0;
		return [0,HOUR,HOUR*2/3,HOUR/3][l];
	};
	Object.defineProperty(G,'lumpMatureAge',{get:function(){return HOUR*20-rigidel();},set:function(){},configurable:true});
	Object.defineProperty(G,'lumpRipeAge',{get:function(){return HOUR*23-rigidel();},set:function(){},configurable:true});
	Object.defineProperty(G,'lumpOverripeAge',{get:function(){return HOUR*24-rigidel();},set:function(){},configurable:true});

	//---- hooks into the phone game
	const hookWhenReady=function()
	{
		if (!G.Save || !G.buildings || !G.buildings.length || !G.shimmerTypesBN || !G.shimmerTypesBN.golden || !document.getElementById('game')) {setTimeout(hookWhenReady,200);return;}

		//saving: the minigames' states go into each building's save
		const save=G.Save;
		G.Save=function(){const g=F();if (g) g.ccSaveAll();return save.apply(this,arguments);};
		//loading a save (startup, import, QR): reload the minigames from it
		const load=G.LoadFromObject;
		G.LoadFromObject=function(){const r=load.apply(this,arguments);const g=F();if (g) g.ccLoadSaves();else build();return r;};
		//ascending or wiping the save resets the minigames like on desktop
		const reset=G.Reset;
		G.Reset=function(hard){const r=reset.apply(this,arguments);const g=F();if (g) g.ccReset(hard);if (hard) {for (let i=0;i<G.buildings.length;i++) G.buildings[i].minigameSave='';}return r;};

		//Godzamok: selling buildings boosts clicking for 10 seconds
		const sell=G.Building.prototype.sell;
		G.Building.prototype.sell=function()
		{
			const before=this.amount;
			const r=sell.apply(this,arguments);
			const sold=before-this.amount;
			const l=G.hasGod('ruin');
			if (sold>0 && l)
			{
				const per=[0,0.01,0.005,0.0025][l];
				const old=G.hasBuff('devastation');
				if (old) {old.pow+=sold*per;old.effs=old.type.effsFunc(old);G.refreshCps=1;}
				else new G.buff('devastation',{t:10,pow:1+sold*per});
			}
			return r;
		};
		//Holobore: clicking a golden cookie unslots him and uses up all worship swaps
		const golden=G.shimmerTypesBN.golden;
		const click=golden.click;
		golden.click=function(me)
		{
			const r=click.apply(this,arguments);
			const g=F();
			if (g && g.hasGod && g.hasGod('asceticism') && g.forceUnslotGod) {if (g.forceUnslotGod('asceticism') && g.useSwap) g.useSwap(1000000);}
			return r;
		};
		//loans: when a loan runs out, its interest starts
		const logicBuffs=G.logicBuffs;
		G.logicBuffs=function()
		{
			const before=G.buffs.slice();
			const r=logicBuffs.apply(this,arguments);
			for (let i=0;i<before.length;i++)
			{
				const b=before[i];
				if (G.buffs.indexOf(b)==-1 && /^loan \d$/.test(b.type.name))
				{
					const g=F();
					if (g && g.takeLoan) g.takeLoan(parseInt(b.type.name.slice(5)),true);
				}
			}
			return r;
		};
		//highest unbuffed CpS (the Stock Market prices goods in it)
		const computeCps=G.computeCps;
		G.computeCps=function(){const r=computeCps.apply(this,arguments);G.cookiesPsRawHighest=Math.max(G.cookiesPsRawHighest||0,G.cookiesPsUnbuffed||0);return r;};

		//start the minigame page now if any minigame is unlocked, so they keep running in the background
		for (const n in MG) {const b=G.buildingsBN[n];if (b && b.level>0) {build();break;}}
		//minigames keep running (garden growing, market ticking) while closed: the page runs all the time once built
		setInterval(function(){for (const n in MG){const b=G.buildingsBN[n];if (b && b.level>0) {build();return;}}},5000);
	};
	hookWhenReady();
});
