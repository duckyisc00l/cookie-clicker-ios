/*
	Sugar lumps and building levels, ported from the desktop version of Cookie Clicker for the iOS app.
	The mobile version has these marked "not yet implemented". Rules follow the desktop game:
	- lumps start growing once you've baked a billion cookies in total
	- a lump matures after 20 hours (can be harvested, 50% chance of getting it), ripens after 23 hours
	  (harvest for sure), and falls after 24 hours (harvested automatically); they keep growing while closed
	- lumps can be bifurcated, golden, meaty (more likely during the Grandmapocalypse) or caramelized
	- spend lumps to level up buildings: level N+1 costs N+1 lumps, each level gives +1% to that building
	The app adds lumps, lumpsTotal, lumpT, lumpCurrentType and building levels to the game's save.
*/
G.addData(function(){
	const HOUR=1000*60*60;
	const ACHIEVS=[
		[`Dude, sweet`,`Harvest <b>7 coalescing sugar lumps</b>.`,[24,14]],
		[`Sugar rush`,`Harvest <b>30 coalescing sugar lumps</b>.`,[26,14]],
		[`Year's worth of cavities`,`Harvest <b>365 coalescing sugar lumps</b>.<q>My lumps my lumps my lumps.</q>`,[29,14]],
		[`Hand-picked`,`Successfully harvest a coalescing sugar lump before it's ripe.`,[28,14]],
		[`Sugar sugar`,`Harvest a <b>bifurcated sugar lump</b>.`,[29,15]],
		[`All-natural cane sugar`,`Harvest a <b>golden sugar lump</b>.`,[29,16],'shadow'],
		[`Sweetmeats`,`Harvest a <b>meaty sugar lump</b>.`,[29,17]],
		[`Maillard reaction`,`Harvest a <b>caramelized sugar lump</b>.`,[29,27]],
	];
	ACHIEVS.forEach(function(a,i){
		let o={name:a[0],id:2200+i,desc:a[1],icon:a[2],order:61000+i};
		if (a[3]) o.pool=a[3];
		new G.Achiev(o);
	});

	G.lumps=0;G.lumpsTotal=0;G.lumpT=0;G.lumpCurrentType=0;G.lumpRefill=0;

	G.lumpMatureAge=HOUR*20;
	G.lumpRipeAge=HOUR*23;
	G.lumpOverripeAge=HOUR*24;

	//lumps have started once lumpT is set; they start after a billion cookies baked in total
	G.canLumps=function(){return G.lumpT>0 || (G.cookiesEarned+(G.cookiesReset||0))>=1e9;};

	G.computeLumpType=function()
	{
		Math.seedrandom(G.seed+'/'+G.lumpT);
		let types=[0];
		if (Math.random()<0.1) types.push(1);//bifurcated
		if (Math.random()<3/1000) types.push(2);//golden
		if (Math.random()<0.1*(G.elderWrath||0)) types.push(3);//meaty
		if (Math.random()<1/50) types.push(4);//caramelized
		G.lumpCurrentType=choose(types);
		Math.seedrandom();
	};

	G.gainLumps=function(total)
	{
		G.lumps+=total;
		G.lumpsTotal+=total;
		if (G.lumpsTotal>=7) G.win(`Dude, sweet`);
		if (G.lumpsTotal>=30) G.win(`Sugar rush`);
		if (G.lumpsTotal>=365) G.win(`Year's worth of cavities`);
		G.drawLump();
	};

	G.harvestLumps=function(amount,silent)
	{
		G.lumpT=Date.now();
		let total=amount;
		const type=G.lumpCurrentType;
		if (type==1) total*=choose([1,2]);
		else if (type==2)
		{
			total*=choose([2,3,4,5,6,7]);
			G.earn(Math.min(G.cookiesPs*60*60*24,G.cookies));
			G.toast(`Sugar blessing!`,`Your golden sugar lump doubled your cookies.`,[29,16]);
		}
		else if (type==3) total*=choose([0,0,1,2,2]);
		else if (type==4) total*=choose([1,2,3]);
		total=Math.floor(total);
		G.gainLumps(total);
		if (type==1) G.win(`Sugar sugar`);
		else if (type==2) G.win(`All-natural cane sugar`);
		else if (type==3) G.win(`Sweetmeats`);
		else if (type==4) G.win(`Maillard reaction`);
		if (!silent)
		{
			if (total>0) G.toast(`+${B(total)} sugar lump${total==1?'':'s'}`,`You now have ${B(G.lumps)}.`,[29,14]);
			else G.toast(`Botched harvest!`,`The sugar lump crumbled away.`,[23,14]);
			PlaySound('snd/pop'+Math.floor(Math.random()*3+1)+'.mp3',0.75);
		}
		G.computeLumpType();
		G.drawLump();
		return total;
	};

	G.harvestLumpNow=function()
	{
		const age=Date.now()-G.lumpT;
		if (age<G.lumpMatureAge) return;
		if (age<G.lumpRipeAge)
		{
			const amount=choose([0,1]);
			if (amount!=0) G.win(`Hand-picked`);
			G.harvestLumps(amount);
		}
		else G.harvestLumps(1);
	};

	G.doLumps=function()
	{
		if (!G.canLumps()) {G.drawLump();return;}
		if (G.lumpT<=0)
		{
			//first time!
			G.lumpT=Date.now();
			G.lumps=Math.max(0,G.lumps);
			G.lumpsTotal=Math.max(0,G.lumpsTotal);
			G.computeLumpType();
			G.toast(`Sugar lumps!`,`Because you've baked a <b>billion cookies</b>, you're now attracting <b>sugar lumps</b>. One is growing next to your cookie count. Harvest it when it's ripe and spend lumps to level up your buildings!`,[23,14]);
		}
		G.lumpT=Math.min(Date.now(),G.lumpT);
		const age=Date.now()-G.lumpT;
		if (age>=G.lumpOverripeAge)
		{
			//fell on its own (also covers lumps that grew while the game was closed)
			const amount=Math.floor(age/G.lumpOverripeAge);
			if (amount>1)
			{
				G.harvestLumps(1,true);
				G.lumpCurrentType=0;
				G.harvestLumps(amount-1,true);
				G.toast(`Welcome back!`,`You harvested <b>${B(amount)} sugar lumps</b> while you were away.`,[29,14]);
				G.lumpT=Date.now()-(age-amount*G.lumpOverripeAge);
				G.computeLumpType();
			}
			else G.harvestLumps(1);
		}
		G.drawLump();
	};

	//---------- the lump on the cookie screen
	G.lumpIcons=function()
	{
		const age=Date.now()-G.lumpT;
		const phase=Math.min(6,Math.floor((age/G.lumpOverripeAge)*7));
		const phase2=Math.min(6,Math.floor((age/G.lumpOverripeAge)*7)+1);
		let row=14,row2=14;
		const type=G.lumpCurrentType;
		if (type==1) {if (phase2>=6) row2=15;}
		else if (type==2) {if (phase>=4) row=16;if (phase2>=4) row2=16;}
		else if (type==3) {if (phase>=4) row=17;if (phase2>=4) row2=17;}
		else if (type==4) {if (phase>=4) row=27;if (phase2>=4) row2=27;}
		let opacity=Math.min(6,(age/G.lumpOverripeAge)*7)%1;
		if (phase>=6) opacity=1;
		return {a:[23+Math.min(phase,5),row],b:[23+phase2,row2],opacity:opacity};
	};
	G.drawLump=function()
	{
		let el=document.getElementById('ccLumps');
		const screen=G.screens && G.screens['cookie'] && G.screens['cookie'].l;
		if (!screen) return;
		if (!G.canLumps() || G.lumpT<=0) {if (el) el.style.display='none';return;}
		if (!el)
		{
			el=document.createElement('div');
			el.id='ccLumps';
			el.innerHTML=`<div class="ccLumpIcon"></div><div class="ccLumpIcon ccLumpIcon2"></div><div class="ccLumpAmount"></div>`;
			el.addEventListener('click',function(e){e.preventDefault();e.stopPropagation();G.lumpPopup();});
			screen.appendChild(el);
		}
		el.style.display='block';
		const ic=G.lumpIcons();
		const icons=el.querySelectorAll('.ccLumpIcon');
		icons[0].style.backgroundPosition=(-ic.a[0]*48)+'px '+(-ic.a[1]*48)+'px';
		icons[1].style.backgroundPosition=(-ic.b[0]*48)+'px '+(-ic.b[1]*48)+'px';
		icons[1].style.opacity=ic.opacity;
		el.querySelector('.ccLumpAmount').textContent=B(G.lumps);
		el.classList.toggle('ccRipe',Date.now()-G.lumpT>=G.lumpMatureAge);
	};
	G.lumpPopup=function()
	{
		PlaySound('snd/press.mp3',0.15);
		const age=Date.now()-G.lumpT;
		const mature=age>=G.lumpMatureAge, ripe=age>=G.lumpRipeAge;
		let status;
		if (!mature) status=`This sugar lump is still growing and will be <b>mature</b> in <b>${sayTime(G.lumpMatureAge-age,-1)}</b>, <b>ripe</b> in <b>${sayTime(G.lumpRipeAge-age,-1)}</b> and will <b>fall</b> in <b>${sayTime(G.lumpOverripeAge-age,-1)}</b>.`;
		else if (!ripe) status=`This sugar lump is <b>mature</b> and will be <b>ripe</b> in <b>${sayTime(G.lumpRipeAge-age,-1)}</b>. Harvesting it now has a <b>50% chance</b> of working. It will fall on its own in <b>${sayTime(G.lumpOverripeAge-age,-1)}</b>.`;
		else status=`This sugar lump is <b>ripe</b>! Harvest it now, or it will fall on its own in <b>${sayTime(G.lumpOverripeAge-age,-1)}</b>.`;
		const type=G.lumpCurrentType;
		let typeText='';
		if (type==1) typeText=`This sugar lump grew to be <b>bifurcated</b>; harvesting it has a 50% chance of yielding two lumps.`;
		else if (type==2) typeText=`This sugar lump grew to be <b>golden</b>; harvesting it will yield 2 to 7 lumps and double your cookies (up to a day's worth).`;
		else if (type==3) typeText=`This sugar lump was affected by the elders and grew to be <b>meaty</b>; harvesting it will yield between 0 and 2 lumps.`;
		else if (type==4) typeText=`This sugar lump is <b>caramelized</b>, its stickiness binding it to unexpected things; harvesting it will yield between 1 and 3 lumps.`;
		const ic=G.lumpIcons();
		G.popup({text:`
			<h3>Sugar lumps</h3>
			<div style="text-align:center;padding:4px;">
				<div class="icon" style="display:inline-block;transform:scale(1.5);margin:12px;background-position:${-ic.b[0]*48}px ${-ic.b[1]*48}px;"></div>
				<p>You have <b>${B(G.lumps)} sugar lump${G.lumps==1?'':'s'}</b>.</p>
				<p>${status}</p>
				${typeText?`<p>${typeText}</p>`:''}
				${mature?G.button({text:`Harvest`,classes:'bumpButton',onclick:function(e,el){G.closePopup();G.harvestLumpNow();}}):''}
			</div>
			<line></line>
			<div style="padding:4px;font-size:90%;color:rgba(255,255,255,0.75);">
				<p>&bull; Sugar lumps can be harvested when mature; left alone they ripen (harvest is then guaranteed) and eventually fall and are harvested automatically.</p>
				<p>&bull; Spend them to <b>level up buildings</b> from each building's info screen in the Store: every level gives <b>+1%</b> to that building's production.</p>
				<p>&bull; Sugar lumps keep growing while the game is closed.</p>
			</div>
		`,close:`Close`});
	};

	//---------- building levels (shown in each building's info popup)
	G.levelUpBuilding=function(me)
	{
		const cost=(me.level||0)+1;
		if (G.lumps<cost) return false;
		G.lumps-=cost;
		me.level=(me.level||0)+1;
		G.computeCps();
		PlaySound('snd/upgrade.mp3',0.6);
		G.toast(`${me.getName?me.getName():me.name} level ${me.level}!`,`${me.plural.charAt(0).toUpperCase()+me.plural.slice(1)} now make <b>+${me.level}%</b> more cookies.`,me.icon);
		G.drawLump();
		return true;
	};
	window.__ccLevelBox=function(me)
	{
		if (!G.canLumps() || G.lumpT<=0) return '';
		const lvl=me.level||0, cost=lvl+1, can=G.lumps>=cost;
		const what=lvl>0
			?(lvl==1?me.extraName:me.extraPlural).replace('[X]',B(lvl))+` granting <b>+${B(lvl)}% ${me.single} CpS</b>.`
			:`Spend sugar lumps to level up this building. Each level gives <b>+1%</b> to its production.`;
		return `<line></line><div style="text-align:center;padding:4px;">
			<h3 style="margin:4px 0;">Level ${B(lvl)}</h3>
			<p>${what}</p>
			`+G.button({text:`Level up for ${B(cost)} sugar lump${cost==1?'':'s'}`,classes:'bumpButton'+(can?'':' ccDisabled'),onclick:function(e,el){
				if (G.levelUpBuilding(me)) G.closePopup();
				else {PlaySound('snd/clickOff2.mp3',0.5);triggerAnim(el,'plop');}
			}})+`
			<p style="font-size:85%;color:rgba(255,255,255,0.6);">You have ${B(G.lumps)} sugar lump${G.lumps==1?'':'s'}.</p>
		</div>`;
	};

	//wipe lumps and levels on a hard reset, like the desktop game
	const reset=G.Reset;
	G.Reset=function(hard)
	{
		if (hard)
		{
			G.lumps=0;G.lumpsTotal=0;G.lumpT=0;G.lumpCurrentType=0;G.lumpRefill=0;
			for (let i=0;i<G.buildings.length;i++) G.buildings[i].level=0;
			let el=document.getElementById('ccLumps');if (el) el.style.display='none';
		}
		return reset.apply(this,arguments);
	};

	const css=document.createElement('style');
	css.textContent=`
		#ccLumps{position:absolute;left:4px;top:58px;width:48px;height:62px;z-index:100;cursor:pointer;display:none;}
		#ccLumps .ccLumpIcon{position:absolute;left:0;top:0;width:48px;height:48px;background:url(img/icons.png);}
		#ccLumps .ccLumpAmount{position:absolute;left:0;right:0;top:44px;text-align:center;font-family:Fancy,sans-serif;font-size:13px;color:#fff;text-shadow:0 0 2px #000,0 1px 1px #000;}
		#ccLumps.ccRipe .ccLumpIcon2{animation:ccLumpPulse 1.6s ease-in-out infinite;}
		@keyframes ccLumpPulse{0%,100%{filter:drop-shadow(0 0 0 rgba(255,255,200,0));}50%{filter:drop-shadow(0 0 6px rgba(255,255,200,0.9));}}
		.bumpButton.ccDisabled{opacity:0.5;}
	`;
	document.head.appendChild(css);

	setInterval(function(){
		if (!G.screens || !G.buildings || typeof G.cookiesEarned!=='number') return;
		G.doLumps();
	},1000);
});
