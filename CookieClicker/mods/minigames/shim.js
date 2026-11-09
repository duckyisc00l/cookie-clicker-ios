/*
	Runs the desktop game's four minigames (Garden, Stock Market, Pantheon, Grimoire) inside the phone game.
	This page lives in an invisible-until-opened frame; "Game" here is a stand-in for the desktop game,
	backed by the real phone game (parent.G). The minigame files themselves are the desktop originals.
*/
var P=parent;
var G=P.G;
var TopBarOffset=0;
var Game={};
Game.version=2.052;
Game.resPath='';
Game.fps=30;
Game.T=0;
Game.drawT=0;
Game.scale=1;
Game.prefs={format:0,askLumps:1,fancy:1,particles:1,numbers:1,animate:1,popups:1};
Game.popups=1;
Game.mouseX=0;Game.mouseY=0;Game.mouseDown=0;
Game.keys={};
Game.sesame=0;
Game.ascensionMode=0;
Game.bakeryName='Your';
Game.clickStr='onclick';
Game.onCrate=0;
Game.setOnCrate=function(what){Game.onCrate=what;};
Game.windowW=window.innerWidth;Game.windowH=window.innerHeight;
window.addEventListener('resize',function(){Game.windowW=window.innerWidth;Game.windowH=window.innerHeight;});

//numbers look the same as in the rest of the phone game
Beautify=function(val,floats){return P.B(val,floats);};

//sounds go through the phone game's sound player
PlaySound=function(url,vol,pitchVar){if (P.PlaySound) P.PlaySound(url,vol);};

//---- values shared with the phone game
Object.defineProperty(Game,'seed',{get:function(){return G.seed||'aaaaa';}});
Object.defineProperty(Game,'cookies',{get:function(){return G.cookies;},set:function(v){G.cookies=v;}});
Object.defineProperty(Game,'cookiesEarned',{get:function(){return G.cookiesEarned;},set:function(v){G.cookiesEarned=v;}});
Object.defineProperty(Game,'cookiesPs',{get:function(){return G.cookiesPs;}});
Object.defineProperty(Game,'cookiesPsRawHighest',{get:function(){return G.cookiesPsRawHighest||G.cookiesPsUnbuffed||G.cookiesPs||0;}});
Object.defineProperty(Game,'lumps',{get:function(){return G.lumps||0;},set:function(v){G.lumps=v;}});
Object.defineProperty(Game,'lumpsTotal',{get:function(){return G.lumpsTotal||0;}});
Object.defineProperty(Game,'lumpRefill',{get:function(){return G.lumpRefill||0;},set:function(v){G.lumpRefill=v;}});
Object.defineProperty(Game,'recalculateGains',{get:function(){return G.refreshCps;},set:function(v){if (v) G.refreshCps=1;}});
Object.defineProperty(Game,'BuildingsOwned',{get:function(){var n=0;for (var i=0;i<G.buildings.length;i++) n+=G.buildings[i].amount;return n;}});
Game.Earn=function(n){G.earn(n);};
Game.Spend=function(n){G.spend(n);};
Game.Has=function(n){return (G.upgradesBN[n] && G.Has(n))?1:0;};
Game.HasAchiev=function(n){return (G.achievsBN[n] && G.HasAchiev(n))?1:0;};
Game.Win=function(n){if (typeof n!=='string'){for (var i in n) Game.Win(n[i]);return;}if (G.achievsBN && G.achievsBN[n]) G.win(n);};
Game.Unlock=function(n){if (typeof n!=='string'){for (var i in n) Game.Unlock(n[i]);return;}if (G.upgradesBN && G.upgradesBN[n]) G.unlock(n);};
Game.auraMult=function(n){return G.auraMult(n);};
Game.hasAura=function(n){return G.hasAura(n);};
Game.dropRateMult=function(){return G.dropRateMult();};
Game.gainLumps=function(n){G.gainLumps(n);};
Game.Notify=function(title,desc,pic){G.toast(title,desc||'',pic||0);};
Game.Popup=function(text,x,y)
{
	//little floating text, like the desktop game's
	var el=document.createElement('div');
	el.id='ccFloat';
	el.innerHTML=text;
	el.style.left=Math.max(0,(x||Game.mouseX)-40)+'px';
	el.style.top=((y||Game.mouseY)-20)+'px';
	document.body.appendChild(el);
	requestAnimationFrame(function(){requestAnimationFrame(function(){el.style.transform='translateY(-40px)';el.style.opacity='0';});});
	setTimeout(function(){el.remove();},1300);
};
Game.SparkleAt=function(){};
Game.SparkleOn=function(){};

//---- buildings: the desktop "Game.Objects" are views of the phone game's buildings
Game.Objects={};
Game.ObjectsById=[];
Game.ccMinigames={'Farm':['Garden','minigameGarden.js'],'Bank':['Stock Market','minigameMarket.js'],'Temple':['Pantheon','minigamePantheon.js'],'Wizard tower':['Grimoire','minigameGrimoire.js']};
for (var i=0;i<G.buildings.length;i++)
{
	(function(b){
		var o={
			id:b.id,name:b.name,dname:b.name,single:b.single,plural:b.plural,
			iconColumn:b.icon?b.icon[0]:b.id,
			minigame:0,minigameLoaded:false,onMinigame:true,minigameName:Game.ccMinigames[b.name]?Game.ccMinigames[b.name][0]:'',
			minigameUrl:Game.ccMinigames[b.name]?Game.ccMinigames[b.name][1]:'',
			getPrice:function(){return b.getCost();},
			buyFree:function(n){b.forceBuy(n||1);},
			sacrifice:function(n){b.sacrifice(n||1);},
			switchMinigame:function(){P.__ccCloseMinigame&&P.__ccCloseMinigame();},
			refresh:function(){},
		};
		Object.defineProperty(o,'amount',{get:function(){return b.amount;}});
		Object.defineProperty(o,'highest',{get:function(){return b.amountMax||b.amount;}});
		Object.defineProperty(o,'level',{get:function(){return b.level||0;}});
		Object.defineProperty(o,'bought',{get:function(){return b.bought;}});
		o.l_b=b;
		Game.Objects[b.name]=o;
		Game.ObjectsById[b.id]=o;
	})(G.buildings[i]);
}

//---- buffs: desktop buffs are counted in frames, the phone game's in seconds
Game.ccBuffView=function(b)
{
	var v={name:b.type.nameD,type:b.type};
	Object.defineProperty(v,'time',{get:function(){return b.t*Game.fps;},set:function(x){b.t=x/Game.fps;}});
	Object.defineProperty(v,'maxTime',{get:function(){return b.tm*Game.fps;},set:function(x){b.tm=x/Game.fps;}});
	Object.defineProperty(v,'arg1',{get:function(){return b.pow;},set:function(x){b.pow=x;}});
	Object.defineProperty(v,'power',{get:function(){return b.pow;}});
	return v;
};
Game.ccFindBuff=function(name)
{
	var low=(''+name).toLowerCase();
	for (var i=0;i<G.buffs.length;i++)
	{
		var b=G.buffs[i];
		if (b.type.name==name || (b.type.nameD||'').toLowerCase()==low) return b;
	}
	return 0;
};
Object.defineProperty(Game,'buffs',{get:function(){
	var o={};
	for (var i=0;i<G.buffs.length;i++){var b=G.buffs[i];o[b.type.nameD||b.type.name]=Game.ccBuffView(b);}
	return o;
}});
Game.hasBuff=function(name){var b=Game.ccFindBuff(name);return b?Game.ccBuffView(b):0;};
Game.killBuff=function(name){var b=Game.ccFindBuff(name);if (b) G.killBuff(b.type.name);};
Game.gainBuff=function(type,time,arg1)
{
	if (!G.buffTypesBN[type]) return 0;
	var b=new G.buff(type,{t:time,pow:arg1});
	if (G.toastBuff) G.toastBuff(b);
	return Game.ccBuffView(b);
};

//---- golden cookies and wrinklers
Game.shimmer=function(type,o)
{
	var oo={};
	for (var k in (o||{})) oo[k]=o[k];
	if (oo.wrath) {oo.forceWrath=true;delete oo.wrath;}
	return new G.shimmer(type,oo);
};
Game.shimmerTypes={golden:{}};
Object.defineProperty(Game.shimmerTypes.golden,'n',{get:function(){return G.shimmerTypesBN.golden.n;}});
Game.SpawnWrinkler=function(me)
{
	var w=G.spawnWrinkler(me);
	return w||0;
};
Game.PopRandomWrinkler=function(){return G.PopRandomWrinkler()||0;};

//---- desktop UI helpers (tooltips, prompts, lump refill)
__ccDesktopUI();
//on the phone, info boxes sit at the bottom of the screen (mobile.css) instead of following the mouse
Game.tooltip.update=function()
{
	if (this.shouldHide) {this.hide();this.shouldHide=0;return;}
	if (Game.drawT%10==0 && typeof(this.text)==='function')
	{
		var text=this.text();
		if (text=='') this.tta.style.opacity='0';
		else {this.tt.innerHTML=unescape(text);this.tta.style.opacity='1';}
	}
};
Game.tooltip.wobble=function(){};

//---- loading and running the minigames
Game.ccLoaded={};
Game.ccLoad=function(name)
{
	var me=Game.Objects[name];
	if (!me || !me.minigameUrl || me.minigameLoaded || me.minigameLoading) return;
	me.minigameLoading=true;
	var script=document.createElement('script');
	script.src=me.minigameUrl;
	script.onload=function()
	{
		me.minigameLoading=false;
		me.minigameLoaded=true;
		me.minigame.launch();
		var save=me.l_b.minigameSave;
		if (save) {me.minigame.reset(true);me.minigame.load(save);}
		else if (name=='Bank' && me.minigame.setCols) {me.minigame.graphCols=1;me.minigame.setCols();me.minigame.toRedraw=2;}
		if (name=='Farm' && !me.minigame.ccFit)
		{
			//only show the part of the plot that is unlocked, and make the tiles as big as the screen allows
			var M=me.minigame;M.ccFit=1;
			var build=M.buildPlot;
			M.buildPlot=function()
			{
				var r=build.apply(this,arguments);
				var lv=Math.max(1,Math.min(M.plotLimits.length,M.parent.level))-1,lim=M.plotLimits[lv];
				var w=(lim[2]-lim[0])*M.tileSize,h=(lim[3]-lim[1])*M.tileSize;
				var plot=l('gardenPlot');if (!plot) return r;
				for (var y=0;y<6;y++) for (var x=0;x<6;x++)
				{
					var t=l('gardenTile-'+x+'-'+y);if (!t) continue;
					t.style.left=((x-lim[0])*M.tileSize)+'px';t.style.top=((y-lim[1])*M.tileSize)+'px';
				}
				var avail=Math.max(200,(l('gardenField')?l('gardenField').clientWidth:300)-12);
				var z=Math.min(1.75,avail/w);
				plot.style.width=w+'px';plot.style.height=h+'px';
				plot.style.setProperty('zoom',z,'important');
				return r;
			};
			M.toRebuild=true;
		}
		Game.ccLoaded[name]=me.minigame;
		if (P.__ccMinigameReady) P.__ccMinigameReady(name);
	};
	document.head.appendChild(script);
};
Game.ccLoadAll=function()
{
	for (var n in Game.ccMinigames) {if (Game.Objects[n] && Game.Objects[n].level>0) Game.ccLoad(n);}
};
//save strings for the phone game's save
Game.ccSaveAll=function()
{
	for (var n in Game.ccLoaded) {var me=Game.Objects[n];try{me.l_b.minigameSave=me.minigame.save();}catch(e){}}
};
//a save was loaded into the phone game: reload every minigame from it
Game.ccLoadSaves=function()
{
	for (var n in Game.ccLoaded)
	{
		var me=Game.Objects[n];
		try{me.minigame.reset(true);if (me.l_b.minigameSave) me.minigame.load(me.l_b.minigameSave);}catch(e){}
	}
	Game.ccLoadAll();
};
Game.ccReset=function(hard)
{
	for (var n in Game.ccLoaded) {try{Game.ccLoaded[n].reset(hard);}catch(e){}}
};
Game.ccShown=0;
Game.ccShow=function(name)
{
	Game.ccShown=name||0;
	var rows=document.querySelectorAll('.row');
	for (var i=0;i<rows.length;i++) rows[i].classList.remove('ccShown');
	if (name && Game.Objects[name]) l('row'+Game.Objects[name].id).classList.add('ccShown');
	Game.tooltip.hide&&Game.tooltip.hide();
	l('rows').scrollTop=0;
};

//touch: remember where the finger is for tooltips; a tap elsewhere hides the tooltip
var ccTrack=function(e){var t=e.touches&&e.touches[0]?e.touches[0]:e;Game.mouseX=t.clientX;Game.mouseY=t.clientY;};
document.addEventListener('touchstart',function(e){ccTrack(e);Game.mouseDown=1;Game.tooltip.shouldHide=1;},{passive:true,capture:true});
document.addEventListener('touchmove',ccTrack,{passive:true});
document.addEventListener('touchend',function(){Game.mouseDown=0;},{passive:true});
document.addEventListener('mousemove',ccTrack);
document.addEventListener('mousedown',function(e){ccTrack(e);Game.mouseDown=1;});
document.addEventListener('mouseup',function(){Game.mouseDown=0;});
document.addEventListener('contextmenu',function(e){e.preventDefault();});

//Pantheon: drag a spirit with your finger onto a slot (the desktop version uses the mouse)
(function(){
	var dragging=0;
	var slotAt=function(x,y)
	{
		for (var i=0;i<3;i++)
		{
			var el=l('templeSlot'+i);if (!el) continue;
			var b=el.getBoundingClientRect();
			if (x>=b.left-8 && x<=b.right+8 && y>=b.top-8 && y<=b.bottom+8) return i;
		}
		return -1;
	};
	document.addEventListener('touchstart',function(e){
		var t=e.target;
		if (!t || !t.id || t.id.indexOf('templeGodDrag')!=0) return;
		var M=Game.Objects['Temple'].minigame;if (!M) return;
		var god=M.godsById[parseInt(t.id.slice(13))];if (!god) return;
		ccTrack(e);
		dragging=1;
		M.dragGod(god);
		e.preventDefault();
	},{passive:false,capture:true});
	document.addEventListener('touchmove',function(e){
		if (!dragging) return;
		ccTrack(e);
		var M=Game.Objects['Temple'].minigame;
		var s=slotAt(Game.mouseX,Game.mouseY);
		if (s!=M.slotHovered) M.hoverSlot(s);
		e.preventDefault();
	},{passive:false,capture:true});
	var end=function(e){
		if (!dragging) return;
		dragging=0;
		var M=Game.Objects['Temple'].minigame;
		M.hoverSlot(slotAt(Game.mouseX,Game.mouseY));
		M.dropGod();
		e.preventDefault();
	};
	document.addEventListener('touchend',end,{passive:false,capture:true});
	document.addEventListener('touchcancel',end,{passive:false,capture:true});
})();

Game.ccLoop=function()
{
	if (G.onAscend) return;
	for (var n in Game.ccLoaded)
	{
		var M=Game.ccLoaded[n];
		try{if (M.logic) M.logic();}catch(e){console.log(e);}
		if (Game.ccShown==n) {try{if (M.draw) M.draw();}catch(e){console.log(e);}}
	}
	if (Game.tooltip.on) Game.tooltip.update();
	if (Game.promptOn && Game.promptUpdateFunc) Game.promptUpdateFunc();
	Game.T++;
	Game.drawT++;
};
setInterval(Game.ccLoop,1000/Game.fps);

Game.ccLoadAll();
if (P.__ccMinigamePageReady) P.__ccMinigamePageReady();
