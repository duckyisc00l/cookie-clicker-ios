VERSION=VERSIONDATA.TEST;
DEV=VERSIONDATA.DEV;
ADLESS=VERSIONDATA.ADLESS;

UPDATES=VERSIONDATA.HISTORY.filter(it=>it[0]<=VERSION);
	if (!TEST && UPDATES.length<VERSIONDATA.HISTORY.length) UPDATES.unshift([-1,0,`New features`,`the alpha may have more current update notes.`]);
ALPHA_FEATURES=VERSIONDATA.ALPHA_FEATURES;


if (typeof Origami!=='undefined')
{
	var attachFastClick=Origami.fastclick;
	attachFastClick(document.body);
}

PATH=window.location.pathname;
PATH=PATH.substr(PATH,PATH.length-10);

function triggerAnim(element,anim)
{
	if (!element) return;
	element.classList.remove(anim);
	void element.offsetWidth;
	element.classList.add(anim);
}

function transfer(me,o)
{
	for (var i in o){me[i]=o[i];}
}


/*
//audio using vanilla HTML
//todo: test if maybe iOS will only play sounds that are added to the body

let Sounds=[];
let PlaySound=function(url,vol)
{
	if (!G.getSet('sound')) return false;
	
	let volume=1;
	if (vol!==undefined) volume=vol;
	if (!G.volume || volume==0) return 0;
	if (!Sounds[url])
	{
		Sounds[url]=new Audio(url);
		Sounds[url].onloadeddata=function(e)
		{
			PlaySound(url,vol);
		}
		Sounds[url].load();
	}
	else if (Sounds[url].readyState>=2)
	{
		Sounds[url].currentTime=0;
		Sounds[url].volume=Math.pow(volume*G.volume/100,2);
		Sounds[url].play();
	}
}
let PreloadSound=function(url)
{
	if (!Sounds[url])
	{
		Sounds[url]=new Audio(url);
		Sounds[url].load();
	}
}
*/

//audio using the WebAudio API
let AudioCtx=new (window.AudioContext||window.webkitAudioContext);

let FetchArrayBuffer=function(url)
{
	let request=new XMLHttpRequest();
	return new Promise(function(win,fail){
		request.responseType="arraybuffer";
		//request.onerror=(e)=>{fail();};
		
		request.onload=function()
		{
			win(request.response);
		}
		request.open("GET",url,true);
		request.send();
	});
}

let Sounds=[];
let PlaySound=function(url,vol)
{
	if (!G.getSet('sound')) return false;
	
	let volume=1;
	if (vol!==undefined) volume=vol;
	if (!G.volume || volume==0) return 0;
	
	if (!Sounds[url])
	{
		Sounds[url]=-1;
		
		FetchArrayBuffer(url)
			.then(arrayBuffer=>AudioCtx.decodeAudioData(arrayBuffer))
			.then(audioBuffer=>{
				Sounds[url]=audioBuffer;
				PlaySound(url,volume);
			});
	}
	else if (Sounds[url]!=-1)
	{
		let source=AudioCtx.createBufferSource();
		source.buffer=Sounds[url];
		let gain=AudioCtx.createGain();
		gain.gain.value=volume;
		source.connect(gain);
		gain.connect(AudioCtx.destination);
		//source.playbackRate.value=2;//pitch-shifting
		source.start();
		source.onended=function(){gain.disconnect();};
	}
}

let PreloadSound=function(url)
{
	if (!Sounds[url])
	{
		Sounds[url]=-1;
		
		FetchArrayBuffer(url)
			.then(arrayBuffer=>AudioCtx.decodeAudioData(arrayBuffer))
			.then(audioBuffer=>{
				Sounds[url]=audioBuffer;
			});
	}
}

//the old Beautify function from Cookie Clicker, shortened to B(value)
//initially adapted from http://cookieclicker.wikia.com/wiki/Frozen_Cookies_%28JavaScript_Add-on%29
function formatEveryThirdPower(notations)
{
	return function (val)
	{
		var base=0,notationValue='';
		if (!isFinite(val)) return 'Inf.';
		if (val>=1000000)
		{
			val/=1000;
			while(Math.round(val)>=1000)
			{
				val/=1000;
				base++;
			}
			if (base>=notations.length) {return 'Inf.';} else {notationValue=notations[base];}
		}
		return (Math.round(val*10)/10)+notationValue;
	};
}

function rawFormatter(val){return val>1000000000000?Math.round(val):(Math.round(val*1000)/1000);}

var formatLong=[' thousand',' million',' billion',' trillion',' quadrillion',' quintillion',' sextillion',' septillion',' octillion',' nonillion'];
var prefixes=['','un','duo','tre','quattuor','quin','sex','septen','octo','novem'];
var suffixes=['decillion','vigintillion','trigintillion','quadragintillion','quinquagintillion','sexagintillion','septuagintillion','octogintillion','nonagintillion'];
for (var i in suffixes)
{
	for (var ii in prefixes)
	{
		formatLong.push(' '+prefixes[ii]+suffixes[i]);
	}
}

var formatShort=['k','M','B','T','Qa','Qi','Sx','Sp','Oc','No'];
var prefixes=['','Un','Do','Tr','Qa','Qi','Sx','Sp','Oc','No'];
var suffixes=['D','V','T','Qa','Qi','Sx','Sp','O','N'];
for (var i in suffixes)
{
	for (var ii in prefixes)
	{
		formatShort.push(' '+prefixes[ii]+suffixes[i]);
	}
}
formatShort[10]='Dc';


var numberFormatters=
[
	formatEveryThirdPower(formatShort),
	formatEveryThirdPower(formatLong),
	rawFormatter
];
var numberFormatter=numberFormatters[0];
function Beautify(val,floats,format)
{
	var negative=(val<0);
	var decimal='';
	var fixed=val.toFixed(floats);
	if (floats>0 && Math.abs(val)<1000 && Math.floor(fixed)!=fixed) decimal='.'+(fixed.toString()).split('.')[1];
	val=Math.floor(Math.abs(val));
	if (floats>0 && fixed==val+1) val++;
	var formatter=format?numberFormatters[format]:numberFormatter;
	var output=(val.toString().indexOf('e+')!=-1 && format==2)?val.toPrecision(3).toString():formatter(val).toString().replace(/\B(?=(\d{3})+(?!\d))/g,',');
	//var output=formatter(val).toString().replace(/\B(?=(\d{3})+(?!\d))/g,',');
	if (output=='0') negative=false;
	return negative?'-'+output:output+decimal;
}
var B=Beautify;

function BeautifyTime(value)
{
	//value should be in seconds
	value=Math.max(Math.ceil(value,0));
	var years=Math.floor(value/31536000);
	value-=years*31536000;
	var days=Math.floor(value/86400);
	value-=days*86400;
	var hours=Math.floor(value/3600)%24;
	value-=hours*3600;
	var minutes=Math.floor(value/60)%60;
	value-=minutes*60;
	var seconds=Math.floor(value)%60;
	var str='';
	if (years) str+=B(years)+'Y';
	if (days || str!='') str+=B(days)+'d';
	if (hours || str!='') str+=hours+'h';
	if (minutes || str!='') str+=minutes+'m';
	if (seconds || str!='') str+=seconds+'s';
	if (str=='') str+='0s';
	return str;
}
var BT=BeautifyTime;


var sayTime=function(time,detail,mini)
{
	//time is a value where one second is equal to 1000.
	//detail skips days when >1, hours when >2, minutes when >3 and seconds when >4.
	//if detail is -1, output something like "3 hours, 9 minutes, 48 seconds"
	//if mini is true, output something like "3h9m48s"
	if (time<=0) return '';
	var str='';
	var detail=detail||0;
	time=Math.floor(time);
	var second=1000;
	if (detail==-1)
	{
		var days=0;
		var hours=0;
		var minutes=0;
		var seconds=0;
		if (time>=second*60*60*24) days=(Math.floor(time/(second*60*60*24)));
		if (time>=second*60*60) hours=(Math.floor(time/(second*60*60)));
		if (time>=second*60) minutes=(Math.floor(time/(second*60)));
		if (time>=second) seconds=(Math.floor(time/(second)));
		hours-=days*24;
		minutes-=hours*60+days*24*60;
		seconds-=minutes*60+hours*60*60+days*24*60*60;
		if (days>10) {hours=0;}
		if (days) {minutes=0;seconds=0;}
		if (hours) {seconds=0;}
		var bits=[];
		if (mini)
		{
			if (days>0) bits.push(B(days)+'d');
			if (hours>0) bits.push(B(hours)+'h');
			if (minutes>0) bits.push(B(minutes)+'m');
			if (seconds>0) bits.push(B(seconds)+'s');
			if (bits.length==0) str='<1s';
			else str=bits.join('');
		}
		else
		{
			if (days>0) bits.push(B(days)+' day'+(days==1?'':'s'));
			if (hours>0) bits.push(B(hours)+' hour'+(hours==1?'':'s'));
			if (minutes>0) bits.push(B(minutes)+' minute'+(minutes==1?'':'s'));
			if (seconds>0) bits.push(B(seconds)+' second'+(seconds==1?'':'s'));
			if (bits.length==0) str='less than 1 second';
			else str=bits.join(', ');
		}
	}
	else
	{
		if (mini)
		{
			if (time>=second*60*60*24*2 && detail<2) str=B(Math.floor(time/(second*60*60*24)))+'d';
			else if (time>=second*60*60*24 && detail<2) str='1d';
			else if (time>=second*60*60*2 && detail<3) str=B(Math.floor(time/(second*60*60)))+'h';
			else if (time>=second*60*60 && detail<3) str='1h';
			else if (time>=second*60*2 && detail<4) str=B(Math.floor(time/(second*60)))+'m';
			else if (time>=second*60 && detail<4) str='1m';
			else if (time>=second*2 && detail<5) str=B(Math.floor(time/(second)))+'s';
			else if (time>=second && detail<5) str='1s';
			else str='<1s';
		}
		else
		{
			if (time>=second*60*60*24*2 && detail<2) str=B(Math.floor(time/(second*60*60*24)))+' days';
			else if (time>=second*60*60*24 && detail<2) str='1 day';
			else if (time>=second*60*60*2 && detail<3) str=B(Math.floor(time/(second*60*60)))+' hours';
			else if (time>=second*60*60 && detail<3) str='1 hour';
			else if (time>=second*60*2 && detail<4) str=B(Math.floor(time/(second*60)))+' minutes';
			else if (time>=second*60 && detail<4) str='1 minute';
			else if (time>=second*2 && detail<5) str=B(Math.floor(time/(second)))+' seconds';
			else if (time>=second && detail<5) str='1 second';
			else str='less than 1 second';
		}
	}
	return str;
}



//===========================================================================
//INIT
//===========================================================================
G.Init=function(StartLoop)
{
	//ajax('http://orteil.dashnet.org/cookieclicker/server.php?q=checkupdate',r=>{G.debug('response: '+r);});
	window.open=(url)=>{return cordova.InAppBrowser.open(url,'_system');};
	
	var list=['snd/clickb1.mp3','snd/clickb2.mp3','snd/clickb3.mp3','snd/clickb4.mp3','snd/clickb5.mp3','snd/clickb6.mp3','snd/clickb7.mp3'];
	for (var i in list){PreloadSound(list[i]);}
	
	
//===========================================================================
//SAVE & LOAD
//load is fired on game launch; save is fired every (G.saveInterval) seconds
//===========================================================================
	G.savePathLive='CookieClickerSave.txt';
	G.savePathTest='CookieClickerSaveTest.txt';
	G.savePathPrevLive='CookieClickerSavePrev.txt';
	G.savePathPrevTest='CookieClickerSaveTestPrev.txt';
	G.savePath=TEST?G.savePathTest:G.savePathLive;
	G.savePathPrev=TEST?G.savePathPrevTest:G.savePathPrevLive;
	
	G.saveInterval=5;
	
	//localStorage.removeItem(G.savePath);
	
	let savedVars=['lastVersion','runStart','gameStart','seed','cookies','cookiesEarned','cookiesTotal','cookiesHandmade','cookieClicks','gcClicks','gcClicksTotal','gcMissed','reindeerClicks','reindeerClicksTotal','reindeerMissed','elderWrath','pledges','pledgeT','wrinklersPopped','cookiesSucked','cookiesReset','heavenlyChips','heavenlyChipsSpent','resets','seasonT','seasonUses','season','santaLevel','dragonLevel','dragonAura','dragonAura2','fortuneGC','fortuneCPS','powerClicks','powerClicksTotal','bgType','milkType','chimeType','quickButtons','tippedN'];
	
	G.Save=function(toObj)
	{
		//if toObj, return the object instead of saving
		var o={};
		
		//save data
		
		o.time=new Date().getTime();
		if (TEST) o.alpha=1;
		
		o.settings={};
		for (var i in G.settings){o.settings[i]=G.settings[i].val;}
		
		o.screen=G.onScreen.name;
		
		G.lastVersion=VERSION;
		
		var transfer=savedVars;
		for (var i=0;i<transfer.length;i++){o[transfer[i]]=G[transfer[i]];}
		o['researchT']=G.researchT;o['researchTM']=G.researchTM;o['researchUpgrade']=G.researchUpgrade?G.researchUpgrade.id:-1;o['researchUpgradeLast']=G.researchUpgradeLast?G.researchUpgradeLast.id:-1;
		o['permanentUpgrades']=G.permanentUpgrades;
		
		o.buildings={};
		var transfer=['amount','amountMax','bought','cookiesMade'];
		for (var ii=0;ii<G.buildings.length;ii++)
		{
			o.buildings[G.buildings[ii].name]={};
			for (var i=0;i<transfer.length;i++){o.buildings[G.buildings[ii].name][transfer[i]]=G.buildings[ii][transfer[i]];}
		}
		
		o.upgrades={};
		for (var ii=0;ii<G.upgrades.length;ii++)
		{
			var it=G.upgrades[ii];
			o.upgrades[it.id]=(it.unlocked<<1)|it.owned;
		}
		
		o.achievs={};
		for (var ii=0;ii<G.achievs.length;ii++)
		{
			o.achievs[G.achievs[ii].id]=G.achievs[ii].owned;
		}
		
		o.buffs=[];
		for (var i=0;i<G.buffs.length;i++)
		{
			var me=G.buffs[i];
			o.buffs.push({type:me.type.name,tm:me.tm,t:me.t,p:me.pow});
		}
		
		
		o.shimmers=[];
		for (var i=0;i<G.shimmerTypes.length;i++)
		{
			var me=G.shimmerTypes[i];
			o.shimmers[i]={};
			o.shimmers[i].t=me.n<=0?me.lastTime:-1;
		}
		
		o.wrinklers=G.saveWrinklers();
		
		//console.log('saved',o);
		
		if (toObj) return o;
		
		//clone current save to backup save, then save to current save
		
		FS.clone(G.savePath,G.savePathPrev)
		.then(()=>{return FS.write(G.savePath,o)})
		.then((o)=>{
		}).catch();
		
		/*
		return new Promise(function(win,fail){
			FS.clone(G.savePath,G.savePathPrev)
			.then(()=>{return FS.write(G.savePath,o)})
			.then((o)=>{
				win();
			}).catch(win);
		});
		*/
		//localStorage.setItem(G.savePath,JSON.stringify(o));
	}
	G.LoadFromObject=function(o)
	{
		//load data
		
		//console.log('loaded',o);
		
		var delta=(new Date().getTime()-(o.time||0))*G.fps/1000;
		
		for (var i in o.settings){if (G.settings[i]){G.setSet(i,o.settings[i]);}}
		
		var transfer=savedVars;
		for (var i=0;i<transfer.length;i++){G[transfer[i]]=o[transfer[i]]||(o[transfer[i]]===''?'':0);}
		
		G.researchT=o['researchT']||0;G.researchTM=o['researchTM']||0;G.researchUpgrade=o['researchUpgrade']!=-1?G.upgradesBID[o['researchUpgrade']]:0;G.researchUpgradeLast=o['researchUpgradeLast']!=-1?G.upgradesBID[o['researchUpgradeLast']]:0;
		G.permanentUpgrades=o['permanentUpgrades']||[-1,-1,-1,-1,-1];
		
		G.prestige=Math.floor(G.HowMuchPrestige(G.cookiesReset));
		
		G.loadQuickButtons();
		
		var transfer=['amount','amountMax','bought','cookiesMade'];
		
		for (var ii in o.buildings)
		{
			for (var i=0;i<transfer.length;i++){G.buildingsBN[ii][transfer[i]]=o.buildings[ii][transfer[i]]||0;}
		}
		
		G.upgradesN=0;
		G.achievsN=0;
		
		for (var ii in o.upgrades)
		{
			if (!G.upgradesBID[ii]) continue;
			var it=G.upgradesBID[ii];
			it.unlocked=((o.upgrades[ii]>>1)&1)||0;
			it.owned=(o.upgrades[ii]&1)||0;
			if (it.owned && it.pool!='toggle' && it.pool!='prestige') G.upgradesN++;
		}
		
		for (var ii in o.achievs)
		{
			if (!G.achievsBID[ii]) continue;
			var it=G.achievsBID[ii];
			it.owned=o.achievs[ii]||0;
			if (it.owned && it.pool!='shadow') G.achievsN++;
		}
		
		for (var i=0;i<o.buffs.length;i++)
		{
			var me=o.buffs[i];
			new G.buff(me.type,{t:me.t,tm:me.tm,pow:me.p,loaded:true});
		}
		
		for (var i=0;i<o.shimmers.length;i++)
		{
			var me=o.shimmers[i];
			var it=G.shimmerTypes[i];
			it.lastTime=me.t!=-1?me.t:Date.now();
			var max=it.delayMod(it.delayMaxBase);
			if ((Date.now()-it.lastTime)>max*1000) it.lastTime=Date.now()-Math.floor(Math.random()*max*1000);
		}
		
		G.loadWrinklers(o.wrinklers,G.lastVersion);
		
		
		G.computeCps();
		
		for (var i=0;i<G.buildings.length;i++)
		{
			var me=G.buildings[i];
			me.free=G.pool['building'+me.id+'Free'];
		}
		
		G.computeBuildingAmounts();
		
		try{
			G.setScreen(o.screen||'cookie',1);
			G.updateBG(true);
		}catch(e){
			setTimeout(()=>{
				G.setScreen(o.screen||'cookie',1);
				G.updateBG(true);
			},200);
		}
		
		var cookieDif=G.cookies;
		
		G.Logic(delta);
		
		/*cookieDif=G.cookies-cookieDif;
		if (o.time && cookieDif>=1) G.toast('Welcome back!',`<div style="margin:2px 16px 8px 16px;">You were away for ${sayTime(Date.now()-o.time)}, and made <b>${B(cookieDif)}</b> cookie${B(cookieDif)=='1'?'':'s'}.</div>`,[10,0],true);*/
		return true;
	}
	G.Load=function(file)
	{
		return new Promise(function(win,fail){
		FS.read(file||G.savePath)
		.then((o)=>{
			//var o=localStorage.getItem(file||G.savePath);
			if (!o) {win('none');console.log('No save found.');return false;}
			
			G.LoadFromObject(o);
			
			win();return true;
		}
		).catch((e)=>{win('error');console.log('Error when loading save.',e);return false;})
		});
	}
	

//===========================================================================
//RESET
//fired when the game starts, after ascending, or when the save is wiped
//===========================================================================
	G.makeSeed=function()
	{
		var chars='abcdefghijklmnopqrstuvwxyz'.split('');
		var str='';
		for (var i=0;i<5;i++){str+=choose(chars);}
		return str;
	}
	
	G.Reset=function(hard)
	{
		var hard=hard||false;
		return new Promise(function(win,fail){
			G.closeAllPopups();
			G.closeAllToasts();
			G.savedToasts=[];
			G.savedNews=[];
			
			G.l.style.display='block';
			
			G.lastVersion=VERSION;
			
			G.lastResetTimestamp=Date.now();
			
			G.runStart=Date.now();
			if (hard) G.gameStart=Date.now();
			
			G.seed=G.makeSeed();//each run has its own seed, used for deterministic random stuff
			
			G.intro=0;//intro animation; steps up to G.fps*2 then stops itself by setting itself to -1
			
			G.milkLevel=0;//visually how high is the milk; unlike in desktop, no impact from achievements
			
			var cookiesForfeited=G.cookiesEarned;
			var currentCookies=G.cookies;
			
			//game vars
			G.cookies=0;//cookies in bank
			G.cookiesD=G.cookies;//cookies displayed
			if (hard) G.cookiesReset=0;//cookies forfeited by ascending
			else
			{
				//moved to G.showAscend()
				/*G.EarnHeavenlyChips(cookiesForfeited);
				G.cookiesReset+=cookiesForfeited;*/
			}
			G.cookiesEarned=0;//cookies earned this run
			G.cookiesHandmade=0;//cookies earned this run by tapping
			if (hard) G.cookiesTotal=0;//cookies earned all-time
			G.cookiesPs=0;//cookies per second; computed every few seconds
			G.cookiesPsUnbuffed=0;//cookies per second (before buffs)
			G.cookiesPc=1;//cookies per click; computed every few seconds
			
			G.powerClicksOn=false;
			G.powerClicks=0;//this is our remaining power clicks. the stat for how many times we've used power clicks is G.powerClicksTotal
			G.gcClicks=0;
			G.reindeerClicks=0;
			if (hard)
			{
				G.gcClicksTotal=0;
				G.gcMissed=0;
				G.reindeerClicksTotal=0;
				G.reindeerMissed=0;
				G.cookieClicks=0;
				G.powerClicksTotal=0;
				
				G.setSet('dislodge',1);
				G.recentAchievs=[];
				
				G.bgType=0;
				G.milkType=0;
				G.chimeType=0;
				
				G.tippedN=0;
			}
			G.recentUpgrades=[];
			
			G.fortuneGC=0;
			G.fortuneCPS=0;
			
			G.onAscend=0;
			G.prestige=0;//prestige level (recalculated depending on G.cookiesReset)
			if (!hard) G.prestige=Math.floor(G.HowMuchPrestige(G.cookiesReset));
			
			if (hard)
			{
				G.heavenlyChips=0;//heavenly chips the player currently has
				G.heavenlyChipsSpent=0;//heavenly chips spent on cookies, upgrades and such
				G.heavenlyChipsD=0;//heavenly chips displayed
				G.resets=0;//reset counter
			}
			else if (G.gainedPrestige>0) G.resets++;
			G.gainedPrestige=0;
			
			G.resetWrinklers(hard);
			
			G.bulkBuy=1;//how many buildings we buy/sell at once
			G.bulkMode=1;//whether we're buying or selling buildings
			
			G.buildingsN=0;
			G.buildingsNmin=0;
			for (var i=0;i<G.buildings.length;i++)
			{
				var me=G.buildings[i];
				me.reset();
				me.redraw();
			}
			G.upgradesN=0;
			for (var i=0;i<G.upgrades.length;i++)
			{
				var me=G.upgrades[i];
				if (me.pool!='prestige' || hard)
				{
					var isUnlocked=me.unlocked;
					me.reset();
					if (!hard && isUnlocked)
					{
						if (G.lastingUpgrades.indexOf(me.name)!=-1){}
						else if (G.Has('Keepsakes') && G.seasonDrops.indexOf(me.name)!=-1 && Math.random()<1/5){}
						else if (G.HasAchiev('O Fortuna') && me.tier && me.tier.id=='fortune' && Math.random()<0.4){}
						else isUnlocked=false;
						if (isUnlocked) me.unlocked=1;
					}
				}
			}
			if (!hard)
			{
				for (var i=0;i<G.upgradePools['prestige'].length;i++)
				{
					var me=G.upgradePools['prestige'][i];
					if (me.owned && me.func) me.func(me);
				}
			}
			if (hard)
			{
				G.achievsN=0;
				for (var i=0;i<G.achievs.length;i++)
				{
					var me=G.achievs[i];
					me.reset();
				}
			}
			for (var i=0;i<G.screens.length;i++)
			{
				var me=G.screens[i];
				G.unpingScreen(me.name);
			}
			
			if (!hard)
			{
				if (cookiesForfeited>=1000000) G.win('Sacrifice');
				if (cookiesForfeited>=1000000000) G.win('Oblivion');
				if (cookiesForfeited>=1000000000000) G.win('From scratch');
				if (cookiesForfeited>=1000000000000000) G.win('Nihilism');
				if (cookiesForfeited>=1000000000000000000) G.win('Dematerialize');
				if (cookiesForfeited>=1000000000000000000000) G.win('Nil zero zilch');
				if (cookiesForfeited>=1000000000000000000000000) G.win('Transcendence');
				if (cookiesForfeited>=1000000000000000000000000000) G.win('Obliterate');
				if (cookiesForfeited>=1000000000000000000000000000000) G.win('Negative void');
				if (cookiesForfeited>=1000000000000000000000000000000000) G.win('To crumbs, you say?');
				if (cookiesForfeited>=1000000000000000000000000000000000000) G.win('You get nothing');
				if (cookiesForfeited>=1000000000000000000000000000000000000000) G.win('Humble rebeginnings');
				if (cookiesForfeited>=1000000000000000000000000000000000000000000) G.win('The end of the world');
				if (cookiesForfeited>=1000000000000000000000000000000000000000000000) G.win('Oh, you\'re back');
				if (cookiesForfeited>=1000000000000000000000000000000000000000000000000) G.win('Lazarus');
				if (cookiesForfeited>=1000000000000000000000000000000000000000000000000000) G.win('Smurf account');
				if (cookiesForfeited>=1000000000000000000000000000000000000000000000000000000) G.win('If at first you don\'t succeed');
				if (cookiesForfeited>=1000000000000000000000000000000000000000000000000000000000) G.win('No more room in hell');
				
				if (Math.floor(currentCookies)==1000000000000) G.win('When the cookies ascend just right');
			}
			
			G.researchT=0;//date when we started this research
			G.researchTM=0;//total duration for this research
			G.researchUpgrade=0;//current upgrade being researched
			G.researchUpgradeLast=0;//previous upgrade researched
			
			G.elderWrath=0;//current level of grandmapocalypse
			G.elderWrathD=0;//grandmapocalypse display; moves smoothly towards G.elderWrath
			G.pledges=0;//how many times we've pledged to appease the grandmas
			G.pledgeT=0;//date when the pledge expires
			
			G.resetBuffs();
			G.resetShimmers();
			G.resetPets(hard);
			G.resetSeasonData(hard);
			
			if (hard) G.resetQuickButtons();
			
			if (hard) G.permanentUpgrades=[-1,-1,-1,-1,-1];
			else
			{
				for (var i in G.permanentUpgrades)
				{
					if (G.permanentUpgrades[i]!=-1)
					{G.upgradesBID[G.permanentUpgrades[i]].forceBuy();}
				}
			}
			
			G.computeCps();
			
			for (var i=0;i<G.buildings.length;i++)
			{
				var me=G.buildings[i];
				me.free=G.pool['building'+me.id+'Free'];
				me.amount+=me.free;
				me.bought+=me.free;
			}
			
			G.computeBuildingAmounts();
			
			G.setScreen('cookie');
			G.updateBG(true);
			win();
		})
	}


//===========================================================================
//SETTINGS
//===========================================================================
	G.volume=100;
	
	G.settings={
		'fancy':{
			base:1,
			onChange:me=>{
				if (me.val==1) {G.l.classList.add('fancyGraphics');G.l.classList.remove('basicGraphics');}
				else {G.l.classList.remove('fancyGraphics');G.l.classList.add('basicGraphics');}
				if (G.backL) G.backL.style.transform='scale(1)';
				if (G.back2L) G.back2L.style.transform='scale(1)';
				if (G.bigCookieShadowL) G.bigCookieShadowL.style.display=me.val==1?'block':'none';
				if (me.val==1) G.rainScale=1; else G.rainScale=2;
				G.stabilizeResize();
			},
		},
		'particles':{
			base:1,
			onChange:me=>{
				if (G.rainL)
				{
					if (me.val==1) {G.rainL.classList.add('on');}
					else {G.rainL.classList.remove('on');}
				}
				if (G.particlesClear) G.particlesClear();
			},
		},
		'cookiepops':{
			base:1,
			onChange:me=>{
			},
		},
		'cookiewobble':{
			base:1,
			onChange:me=>{
			},
		},
		'lowMotion':{
			base:0,
			onChange:me=>{
			},
		},
		'cursors':{
			base:1,
			onChange:me=>{
			},
		},
		'diagnostic':{
			base:DEV,
			onChange:me=>{
				if (me.val==1) {G.fpsGraphShow();}
				else {G.fpsGraphHide();}
			},
			override:val=>{return (DEV?val:0);},
		},
		'debug':{
			base:DEV,
			onChange:me=>{
				if (me.val==1) {G.l.classList.add('debugOn');}
				else {G.l.classList.remove('debugOn');}
			},
			override:val=>{return (DEV?val:0);},
		},
		'sound':{
			base:1,
			onChange:me=>{
			},
		},
		'pan':{
			base:0,
			onChange:me=>{
			},
		},
		'dislodge':{
			base:1,
			onChange:me=>{
			},
		},
		'shadows':{
			base:0,
			onChange:me=>{
				if (me.val==1) {G.l.classList.add('shadowsOn');}
				else {G.l.classList.remove('shadowsOn');}
			},
		},
		'milk':{
			base:1,
			onChange:me=>{
				if (G.milkL)
				{
					if (me.val==1) {G.milkL.classList.remove('off');}
					else {G.milkL.classList.add('off');}
				}
			},
		},
		'notScary':{
			base:0,
			onChange:me=>{
			},
		},
	};
	//G.getSet=function(name){return G.settings[name].val;}
	G.getSet=function(name)
	{
		var me=G.settings[name];
		if (me.override) return me.override(me.val);
		else return G.settings[name].val;
	}
	G.setSet=function(name,val)
	{
		var me=G.settings[name];
		if (me.override) val=me.override(val);
		G.settings[name].val=val;
		if (G.settings[name].onChange) G.settings[name].onChange(G.settings[name]);
	}
	
	G.resetSettings=()=>{
		for (var i in G.settings)
		{
			var me=G.settings[i];
			me.name=i;
			if (typeof me.base==='undefined') me.base=0;
			G.setSet(me.name,me.base);
		}
	};
	G.resetSettings();
	G.addPostData(G.resetSettings);
	
//===========================================================================
//INPUTS
//===========================================================================
	
	let updateStateButton=function(me,o)
	{
		var state='OFF';
		if (typeof o.state!=='undefined') state=o.state;
		if (o.tieToSetting)
		{
			var val=G.getSet(o.tieToSetting);
			if (o.invert)
			{
				if (val==1) state='OFF';
				else if (val==0) state='ON';
			}
			else
			{
				if (val==0) state='OFF';
				else if (val==1) state='ON';
			}
		}
		if (state=='ON') {me.classList.add('on');me.classList.remove('off');}
		else if (state=='OFF') {me.classList.remove('on');me.classList.add('off');}
		me.querySelector('.stateButtonState').innerHTML=state;
	}
	
	G.stateButton=function(o)
	{
		//a state button is a big wide button that can be pressed to alter its state
		//the default behavior is to start in state "off", and to toggle to "on" when pressed
		
		let id=('button-'+G.buttonsN);
		G.buttonsN++;
		
		G.pushCallback(function(){
			let me=l(id);
			updateStateButton(me,o);
			G.onclick(me,e=>{
				if (o.onclick)
				{
					o.onclick(me);
				}
				else if (o.tieToSetting)
				{
					var val=G.getSet(o.tieToSetting);
					G.setSet(o.tieToSetting,val==0?1:0);
				}
				updateStateButton(me,o);
				PlaySound('snd/tick.mp3',0.5);
			});
		});
		
		return '<div class="bumpButton wideButton stateButton" id="'+id+'"><div class="stateButtonLabel fancy">'+o.text+'</div><div class="stateButtonState fancy"></div>'+(o.comment?('<div class="stateButtonComment">'+o.comment+'</div>'):'')+'</div>';
	}
//===========================================================================
//CONTROLS
//===========================================================================
	G.ondown=function(el,func)
	{
		AddEvent(el,'touchstart',function(e){e.preventDefault();func(e,el);});
	}
	G.onup=function(el,func)
	{
		AddEvent(el,['touchend','touchcancel'],function(e){e.preventDefault();if (!G.panning){func(e,el);}});
	}
	G.onmove=function(el,func)
	{
		AddEvent(el,'touchmove',function(e){e.preventDefault();});
	}
	//G.onclick=G.onup;
	G.onclick=function(el,func)
	{
		AddEvent(el,'click',function(e){e.preventDefault();func(e,el);});
	}
	
	G.stabilizeResize=function()
	{
		if (G.rainL && Math.floor(G.rainL.height)!=Math.floor(G.h/G.rainScale-18))
		{
			G.rainL.width=G.w/G.rainScale;
			G.rainL.height=G.h/G.rainScale-18;
			G.rainL.style.left=(50-50/G.rainScale)+'%';
			G.rainL.style.top=(50-50/G.rainScale)+'%';
			G.rainL.style.transform='scale('+(G.rainScale*1.1)+')';
		}
		
		G.shimmersOnResize();
	}
	
	G.panFrom=0;
	G.panTo=0;
	G.panning=0;
	G.canPan=1;
	G.panStep=90;
	G.dragging=0;
	G.fromX=0;
	G.fromY=0;
	G.onX=0;
	G.onY=0;
	G.velX=0;
	G.velY=0;
	G.onAngle=0;
	G.fromAngle=0;
	AddEvent(G.l,'touchstart',function(e){
		//G.fromAngle=Math.atan2(G.fromY-G.onY,G.fromX-G.onX);
		if (e.touches.length==1)
		{
			G.panFrom=G.onScreen.id*G.panStep;
			var touch=e.touches[0];
			G.fromX=Rescale(touch.pageX);
			G.fromY=Rescale(touch.pageY);
			G.onX=G.fromX;
			G.onY=G.fromY;
			G.velX=0;
			G.velY=0;
			G.dragging=1;
		}
	},true);
	AddEvent(G.l,'touchmove',function(e){
		if (e.touches.length>0)
		{
			var touch=e.touches[0];
			G.onX=Rescale(touch.pageX);
			G.onY=Rescale(touch.pageY);
			
			G.velX=G.onX-G.fromX;
			G.velY=G.onY-G.fromY;
			
			//G.onAngle=Math.atan2(G.fromY-G.onY,G.fromX-G.onX)-G.fromAngle;
			
			if (G.canPan && e.touches.length==1)
			{
				var deltaX=G.velX;
				var deltaY=G.velY;
				if (G.getSet('pan') && !G.onPopup && Math.abs(deltaY)<G.panStep/2)
				{
					G.panTo=G.panFrom-(Math.abs(deltaX)<G.panStep?deltaX*1.5:deltaX);
					G.panning=1;
				}
			}
		}
	},true);
	G.endTouch=function(e)
	{
		G.panning=0;
		if (e.touches.length==0)
		{
			G.panFrom=0;
			G.dragging=0;
			G.canPan=1;
			G.velX=0;
			G.velY=0;
		}
	}
	AddEvent(G.l,['touchend','touchcancel'],G.endTouch,true);
	
//===========================================================================
//BUILD HTML
//===========================================================================
	G.topL=document.createElement('div');
	G.topL.id='topStuff';
	G.topL.innerHTML=`
		<div id="ticker"><div id="ticker1"></div><div id="ticker2"></div></div>
		<div id="cookiesAmount">0 cookies</div>
		<div id="cookiesPs"></div>
		<div id="buffs"></div>
		<div id="particles"></div>
		<div id="popups"></div>
		<div id="toasts"></div>
		<div id="version">v.${VERSION}${TEST?' ALPHA':''}${ADLESS?' ADLESS':''}</div>
	`;
	G.l.appendChild(G.topL);
	G.topL.insertAdjacentHTML('afterend',`<div id="sparkles"></div>`);//has to be afterwards to blend correctly
	G.cookiesAmountL=l('cookiesAmount');
	G.cookiesPsL=l('cookiesPs');
	G.particlesL=l('particles');
	
	/*
	//sadly too intensive
	G.bgRain1=document.createElement('div');
	G.bgRain1.className='bgRain';G.bgRain1.id='bgRain1';
	G.l.appendChild(G.bgRain1);
	G.bgRain2=document.createElement('div');
	G.bgRain2.className='bgRain';G.bgRain2.id='bgRain2';
	G.l.appendChild(G.bgRain2);
	*/
	
	G.cheatL=document.createElement('div');
	G.cheatL.id='cheat';
	G.cheatL.className='debugOnly';
	G.cheatL.style.cssText='position:absolute;left:0px;top:20px;right:0px;z-index:10000000000;font-weight:bold;';
	G.cheatL.innerHTML=`
		`+G.button({text:'--',style:'position:absolute;left:0px;top:0px;width:32px;',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);G.cookies/=1000;}})+`
		`+G.button({text:'-',style:'position:absolute;left:32px;top:0px;width:32px;',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);G.cookies/=10;}})+`
			`+G.button({text:'G',style:'position:absolute;left:64px;top:0px;width:32px;',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);new G.shimmer('golden');}})+`
		`+G.button({text:'+',style:'position:absolute;right:32px;top:0px;width:32px;',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);G.earn(Math.max(1,G.cookies*9));}})+`
		`+G.button({text:'++',style:'position:absolute;right:0px;top:0px;width:32px;',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);G.earn(Math.max(1000,G.cookies*999));}})+`
	`;
	G.l.appendChild(G.cheatL);
	
	G.RuinTheFun=function()
	{
		for (var i=0;i<G.buildings.length;i++){G.buildings[i].forceBuy(100);}
		for (var i=0;i<G.upgrades.length;i++){if (!G.upgrades[i].unimplemented && G.upgrades[i].pool!='toggle') G.upgrades[i].forceBuy();}
		for (var i=0;i<G.achievs.length;i++){G.achievs[i].forceWin();}
		console.log('Fun ruined.');
		PlaySound('snd/powerShimmer.mp3',0.4);
	};
	
	
	G.icon=function(x,y,css)
	{
		return `<div class="icon" style="display:inline-block;vertical-align:middle;background-position:${-x*48}px ${-y*48}px;margin:-24px 4px;${css||''}"></div>`;
	};
	G.iconSmall=function(x,y,css)
	{
		return `<span class="tinyIcon" style="background-position:${-x*48}px ${-y*48}px;margin:-24px -12px -24px -26px;${css||''}"></span>`;
	};
	
//===========================================================================
//QUICK BUTTONS
//===========================================================================
	G.quickButtonOptions={
		'none':{cond:()=>{return true;},name:`None`,icon:[0,7]},
		'powerClicks':{cond:()=>{return G.Has('Power clicks');},name:`Power clicks`,icon:[30,36]},
		'goldenSwitch':{cond:()=>{return G.Has('Golden switch');},name:`Golden switch`,icon:[20,10]},
		'dragonAura1':{cond:()=>{return G.dragonLevel>=5;},name:`Dragon aura`,icon:[30,12]},
		'dragonAura2':{cond:()=>{return G.dragonLevel==G.dragonLevels.length-1;},name:`Dragon aura 2`,icon:[30,12]},
		'seasonSwitcher':{cond:()=>{return G.Has('Season switcher');},name:`Season switcher`,icon:[16,6]},
	};for (let i in G.quickButtonOptions){G.quickButtonOptions[i].id=i;}
	G.quickButtonsPos=[
		[10,10],
		[0,52],
		[52,0],
		[42,42],
	];
	G.quickButtons=[];
	G.resetQuickButtons=()=>{G.quickButtons=Array(G.quickButtonsPos.length).fill('none',0);G.quickButtons[0]='powerClicks';};
	G.loadQuickButtons=()=>{
		if (!G.quickButtons) G.resetQuickButtons();
		G.quickButtons.splice(G.quickButtonsPos.length);
		for (var i=0;i<G.quickButtonsPos.length;i++){if (!G.quickButtons[i] || !G.quickButtonOptions[G.quickButtons[i]]) G.quickButtons[i]='none';}
	};
	G.resetQuickButtons();

//===========================================================================
//PARTICLES
//===========================================================================
	G.particles=[];
	G.particlesN=50;
	G.particleI=0;
	G.particlesReset=function()
	{
		G.pendingParticles=[];
		var str='';
		for (var i=0;i<G.particlesN;i++)
		{
			str+='<div id="particle-'+i+'" class="particle">a</div>';
		}
		G.particlesL.innerHTML=str;
		for (var i=0;i<G.particlesN;i++)
		{
			G.particles[i]={
				x:0,
				y:0,
				xd:0,
				yd:0,
				s:1,
				sd:1,//multiply each frame
				grav:1,//set to 0 to disable gravity
				str:0,
				pic:0,
				a:1,//alpha multiplier
				r:0,
				rd:0,
				t:-1,
				life:1,//in seconds
				l:l('particle-'+i),
			};
		}
	}
	G.particlesReset();
	G.particlesClear=function()
	{
		for (var i=0;i<G.particlesN;i++)
		{
			var me=G.particles[i];
			me.t=-1;
			me.l.className='particle';
			me.l.style.background='none';
		}
	}
	G.pendingParticles=[];
	G.particleAt=function(o)
	{
		if (!G.hasFocus) return false;
		if (!G.getSet('particles')) return false;
		if (G.pendingParticles.length<50) G.pendingParticles.push(o);
	}
	G._particleAt=function(o)
	{
		var me=G.particles[G.particleI];
		me.str=0;me.pic=0;
		me.xd=0;me.yd=0;me.s=1;me.sd=1;me.r=0;me.rd=0;
		me.grav=1;me.a=1;me.life=1;
		var cssText=o.cssText;o.cssText=0;
		for (var i in o){me[i]=o[i];}
		if (me.str) {me.l.innerHTML=me.str;me.l.className='particle textParticle';}
		else {me.l.innerHTML='';}
		me.l.style.cssText='';
		if (me.pic)
		{
			if (typeof o.r==='undefined') me.r=Math.random()*360;
			me.l.className='particle picParticle';
			if (me.pic=='cookie')
			{
				me.l.style.cssText='background:url(img/smallCookies.png) '+(Math.floor(Math.random()*8)*64)+'px 0px;';
			}
			else if (me.pic=='cookieIcon')
			{
				var cookies=[G.upgradesBID[590]];
				var pool=G.upgradePools['cookie'];var poolL=pool.length;
				for (var i=0;i<poolL;i++)
				{
					var cookie=pool[i];
					if (cookie.owned) cookies.push(cookie);
				}
				var icon=choose(cookies).icon;
				//me.l.style.background='url(img/icons.png) '+(-icon[0]*48)+'px '+(-icon[1]*48)+'px';
				me.l.style.cssText='background:url(img/icons.png) '+(-icon[0]*48)+'px '+(-icon[1]*48)+'px;width:48px;height:48px;left:-24px;top:-24px;';
			}
			else if (Array.isArray(me.pic))
			{
				var icon=me.pic;
				me.l.style.cssText='background:url(img/icons.png) '+(-icon[0]*48)+'px '+(-icon[1]*48)+'px;width:48px;height:48px;left:-24px;top:-24px;';
			}
			else
			{
				me.l.style.cssText='background:url('+me.pic+') '+(Math.floor(Math.random()*8)*64)+'px 0px;';
			}
		}
		if (cssText) me.l.style.cssText=cssText;
		me.t=0;
		G.particleI++;
		if (G.particleI>=G.particlesN) G.particleI=0;
	}
	G.particlesLogic=function(delta)
	{
		for (var i=0;i<G.particlesN;i++)
		{
			if (G.particles[i].t>-1)
			{
				var me=G.particles[i];
				me.x+=me.xd;
				me.y+=me.yd;
				me.xd*=1-0.05*me.grav;
				me.yd+=0.5*me.grav;
				me.s*=me.sd;
				me.r+=me.rd;
				me.t++;
				if (me.t>=G.fps*me.life)
				{
					me.t=-2;
				}
			}
		}
	}
	G.particlesDraw=function()
	{
		for (var i=0;i<G.pendingParticles.length;i++)
		{
			G._particleAt(G.pendingParticles[i]);
		}
		G.pendingParticles=[];
		for (var i=0;i<G.particlesN;i++)
		{
			var me=G.particles[i];
			if (me.t==-2)
			{
				me.t=-1;
				me.l.className='particle';
				me.l.style.background='none';
			}
			else if (me.t>-1)
			{
				me.l.style.transform='translate3d('+me.x+'px,'+me.y+'px,0) scale('+me.s+') rotate('+(me.r)+'deg)';
				var o=1;
				var life=G.fps*me.life;
				if (me.t>=life/2) o=1-(me.t-life/2)/(life/2);
				me.l.style.opacity=o*me.a;
			}
		}
	}
	
	G.cookiePop=function(x,y,s)
	{
		G.particleAt({
			x:x,
			y:y,
			//s:Math.random()*0.5+0.1,
			s:(s||1)*(Math.random()*0.2+0.9),
			xd:Math.random()*4-2,
			yd:-Math.random()*3-2,
			rd:Math.random()*10-5,
			//pic:'cookie',
			pic:G.season=='fools'?'img/smallDollars.png':'cookieIcon',
		});
	}
	
	//display sparkles at a set position
	G.sparkles=l('sparkles');
	G.sparklesT=0;
	G.sparklesFrames=16;
	G.sparkleAt=function(x,y)
	{
		//if (G.blendModesOn)
		G.sparklesT=G.sparklesFrames+1;
		G.sparkles.style.backgroundPosition='0px 0px';
		G.sparkles.style.left=Math.floor(x-64)+'px';
		G.sparkles.style.top=Math.floor(y-64)+'px';
		G.sparkles.style.display='block';
	}
	G.sparkleOn=function(el)
	{
		if (!el) return;
		var rect=RescaleBox(el.getBoundingClientRect());
		G.sparkleAt((rect.left+rect.right)/2,(rect.top+rect.bottom)/2);
	}
	
//===========================================================================
//TICKER
//===========================================================================
	G.ticker1L=l('ticker1');
	G.ticker1W=0;
	G.ticker1X=0;
	G.ticker1onClick=0;
	G.ticker2L=l('ticker2');
	G.ticker2W=0;
	G.ticker2X=0;
	G.ticker2onClick=0;
	G.tickerN=0;
	
	G.getTicker=function()
	{
		var cookies=G.cookiesEarned;
		var animals=['newts','penguins','scorpions','axolotls','puffins','porpoises','blowfish','horses','crayfish','slugs','humpback whales','nurse sharks','giant squids','polar bears','fruit bats','frogs','sea squirts','velvet worms','mole rats','paramecia','nematodes','tardigrades','giraffes','monkfish','wolfmen','goblins','hippies'];
		
		var loreProgress=Math.round(Math.log(cookies/10)*Math.LOG10E+1|0);
		
		var list=[];
				
		
		if (G.tickerN%2==0 || loreProgress>14)
		{
			if (Math.random()<0.75 || cookies<10000)
			{
				if (G.buildingN('Grandma')>0) list.push(choose([
				'<q>Moist cookies.</q><sig>grandma</sig>',
				'<q>We\'re nice grandmas.</q><sig>grandma</sig>',
				'<q>Indentured servitude.</q><sig>grandma</sig>',
				'<q>Come give grandma a kiss.</q><sig>grandma</sig>',
				'<q>Why don\'t you visit more often?</q><sig>grandma</sig>',
				'<q>Call me...</q><sig>grandma</sig>'
				]));
				
				if (G.buildingN('Grandma')>=50 && !G.getSet('notScary')) list.push(choose([
				'<q>Absolutely disgusting.</q><sig>grandma</sig>',
				'<q>You make me sick.</q><sig>grandma</sig>',
				'<q>You disgust me.</q><sig>grandma</sig>',
				'<q>We rise.</q><sig>grandma</sig>',
				'<q>It begins.</q><sig>grandma</sig>',
				'<q>It\'ll all be over soon.</q><sig>grandma</sig>',
				'<q>You could have stopped it.</q><sig>grandma</sig>'
				]));
				
				if (G.hasAchiev('Just wrong') && Math.random()<0.05) list.push('News : cookie manufacturer downsizes, sells own grandmother!');
				if (G.hasAchiev('Just wrong') && Math.random()<0.4 && !G.getSet('notScary')) list.push(choose([
				'<q>It has betrayed us, the filthy little thing.</q><sig>grandma</sig>',
				'<q>It tried to get rid of us, the nasty little thing.</q><sig>grandma</sig>',
				'<q>It thought we would go away by selling us. How quaint.</q><sig>grandma</sig>',
				'<q>I can smell your rotten cookies.</q><sig>grandma</sig>'
				]));
				
				if (G.buildingN('Grandma')>=1 && G.pledges>0 && G.elderWrath==0 && !G.getSet('notScary')) list.push(choose([
				'<q>shrivel</q><sig>grandma</sig>',
				'<q>writhe</q><sig>grandma</sig>',
				'<q>throb</q><sig>grandma</sig>',
				'<q>gnaw</q><sig>grandma</sig>',
				'<q>We will rise again.</q><sig>grandma</sig>',
				'<q>A mere setback.</q><sig>grandma</sig>',
				'<q>We are not satiated.</q><sig>grandma</sig>',
				'<q>Too late.</q><sig>grandma</sig>'
				]));
				
				if (G.buildingN('Farm')>0) list.push(choose([
				'News : cookie farms suspected of employing undeclared elderly workforce!',
				'News : cookie farms release harmful chocolate in our rivers, says scientist!',
				'News : genetically-modified chocolate controversy strikes cookie farmers!',
				'News : free-range farm cookies popular with today\'s hip youth, says specialist.',
				'News : farm cookies deemed unfit for vegans, says nutritionist.'
				]));
				
				if (G.buildingN('Mine')>0) list.push(choose([
				'News : is our planet getting lighter? Experts examine the effects of intensive chocolate mining.',
				'News : '+Math.floor(Math.random()*1000+2)+' miners trapped in collapsed chocolate mine!',
				'News : chocolate mines found to cause earthquakes and sinkholes!',
				'News : chocolate mine goes awry, floods village in chocolate!',
				'News : depths of chocolate mines found to house "peculiar, chocolaty beings"!'
				]));
				
				if (G.buildingN('Factory')>0) list.push(choose([
				'News : cookie factories linked to global warming!',
				'News : cookie factories involved in chocolate weather controversy!',
				'News : cookie factories on strike, robotic minions employed to replace workforce!',
				'News : cookie factories on strike - workers demand to stop being paid in cookies!',
				'News : factory-made cookies linked to obesity, says study.'
				]));
				
				if (G.buildingN('Bank')>0) list.push(choose([
				'News : cookie loans on the rise as people can no longer afford them with regular money.',
				'News : cookies slowly creeping up their way as a competitor to traditional currency!',
				'News : most bakeries now fitted with ATMs to allow for easy cookie withdrawals and deposits.',
				'News : cookie economy now strong enough to allow for massive vaults doubling as swimming pools!',
				'News : "Tomorrow\'s wealthiest people will be calculated by their worth in cookies", predict specialists.'
				]));
				
				if (G.buildingN('Temple')>0) list.push(choose([
				'News : explorers bring back ancient artifact from abandoned temple; archeologists marvel at the centuries-old '+choose(['magic','carved','engraved','sculpted','royal','imperial','mummified','ritual','golden','silver','stone','cursed','plastic','bone','blood','holy','sacred','sacrificial','electronic','singing','tapdancing'])+' '+choose(['spoon','fork','pizza','washing machine','calculator','hat','piano','napkin','skeleton','gown','dagger','sword','shield','skull','emerald','bathtub','mask','rollerskates','litterbox','bait box','cube','sphere','fungus'])+'!',
				'News : recently-discovered chocolate temples now sparking new cookie-related cult; thousands pray to Baker in the sky!',
				'News : just how extensive is the cookie pantheon? Theologians speculate about possible '+choose(['god','goddess'])+' of '+choose([choose(animals),choose(['kazoos','web design','web browsers','kittens','atheism','handbrakes','hats','aglets','elevator music','idle games','the letter "P"','memes','hamburgers','bad puns','kerning','stand-up comedy','failed burglary attempts','clickbait','one weird tricks'])])+'.',
				'News : theists of the world discover new cookie religion - "Oh boy, guess we were wrong all along!"',
				'News : cookie heaven allegedly "sports elevator instead of stairway"; cookie hell "paved with flagstone, as good intentions make for poor building material".'
				]));
				
				if (G.buildingN('Wizard tower')>0) list.push(choose([
				'News : all '+choose([choose(animals),choose(['public restrooms','clouds','politicians','moustaches','hats','shoes','pants','clowns','encyclopedias','websites','potted plants','lemons','household items','bodily fluids','cutlery','national landmarks','yogurt','rap music','underwear'])])+' turned into '+choose([choose(animals),choose(['public restrooms','clouds','politicians','moustaches','hats','shoes','pants','clowns','encyclopedias','websites','potted plants','lemons','household items','bodily fluids','cutlery','national landmarks','yogurt','rap music','underwear'])])+' in freak magic catastrophe!',
				'News : heavy dissent rages between the schools of '+choose(['water','fire','earth','air','lightning','acid','song','battle','peace','pencil','internet','space','time','brain','nature','techno','plant','bug','ice','poison','crab','kitten','dolphin','bird','punch','fart'])+' magic and '+choose(['water','fire','earth','air','lightning','acid','song','battle','peace','pencil','internet','space','time','brain','nature','techno','plant','bug','ice','poison','crab','kitten','dolphin','bird','punch','fart'])+' magic!',
				'News : get your new charms and curses at the yearly National Spellcrafting Fair! Exclusive prices on runes and spellbooks.',
				'News : cookie wizards deny involvement in shockingly ugly newborn - infant is "honestly grody-looking, but natural", say doctors.',
				'News : "Any sufficiently crude magic is indistinguishable from technology", claims renowned technowizard.'
				]));
				
				if (G.buildingN('Shipment')>0) list.push(choose([
				'News : new chocolate planet found, becomes target of cookie-trading spaceships!',
				'News : massive chocolate planet found with 99.8% certified pure dark chocolate core!',
				'News : space tourism booming as distant planets attract more bored millionaires!',
				'News : chocolate-based organisms found on distant planet!',
				'News : ancient baking artifacts found on distant planet; "terrifying implications", experts say.'
				]));
				
				if (G.buildingN('Alchemy lab')>0) list.push(choose([
				'News : national gold reserves dwindle as more and more of the precious mineral is turned to cookies!',
				'News : chocolate jewelry found fashionable, gold and diamonds "just a fad", says specialist.',
				'News : silver found to also be transmutable into white chocolate!',
				'News : defective alchemy lab shut down, found to convert cookies to useless gold.',
				'News : alchemy-made cookies shunned by purists!'
				]));
				
				if (G.buildingN('Portal')>0) list.push(choose([
				'News : nation worried as more and more unsettling creatures emerge from dimensional portals!',
				'News : dimensional portals involved in city-engulfing disaster!',
				'News : tourism to cookieverse popular with bored teenagers! Casualty rate as high as 73%!',
				'News : cookieverse portals suspected to cause fast aging and obsession with baking, says study.',
				'News : "do not settle near portals," says specialist; "your children will become strange and corrupted inside."'
				]));
				
				if (G.buildingN('Time machine')>0) list.push(choose([
				'News : time machines involved in history-rewriting scandal! Or are they?',
				'News : time machines used in unlawful time tourism!',
				'News : cookies brought back from the past "unfit for human consumption", says historian.',
				'News : various historical figures inexplicably replaced with talking lumps of dough!',
				'News : "I have seen the future," says time machine operator, "and I do not wish to go there again."'
				]));
				
				if (G.buildingN('Antimatter condenser')>0) list.push(choose([
				'News : whole town seemingly swallowed by antimatter-induced black hole; more reliable sources affirm town "never really existed"!',
				'News : "explain to me again why we need particle accelerators to bake cookies?" asks misguided local woman.',
				'News : first antimatter condenser successfully turned on, doesn\'t rip apart reality!',
				'News : researchers conclude that what the cookie industry needs, first and foremost, is "more magnets".',
				'News : "unravelling the fabric of reality just makes these cookies so much tastier", claims scientist.'
				]));
				
				if (G.buildingN('Prism')>0) list.push(choose([
				'News : new cookie-producing prisms linked to outbreak of rainbow-related viral videos.',
				'News : scientists warn against systematically turning light into matter - "One day, we\'ll end up with all matter and no light!"',
				'News : cookies now being baked at the literal speed of light thanks to new prismatic contraptions.',
				'News : "Can\'t you sense the prism watching us?", rambles insane local man. "No idea what he\'s talking about", shrugs cookie magnate/government official.',
				'News : world citizens advised "not to worry" about frequent atmospheric flashes.',
				]));
				
				if (G.buildingN('Chancemaker')>0) list.push(choose([
				'News : strange statistical anomalies continue as weather forecast proves accurate an unprecedented 3 days in a row!',
				'News : local casino ruined as all gamblers somehow hit a week-long winning streak! "We might still be okay", says owner before being hit by lightning 47 times.',
				'News : neighboring nation somehow elects president with sensible policies in freak accident of random chance!',
				'News : million-to-one event sees gritty movie reboot turning out better than the original! "We have no idea how this happened", say movie execs.',
				'News : all scratching tickets printed as winners, prompting national economy to crash and, against all odds, recover overnight.',
				]));
				
				if (G.buildingN('Fractal engine')>0) list.push(choose([
				'News : local man "done with Cookie Clicker", finds the constant self-references "grating and on-the-nose".',
				'News : local man sails around the world to find himself - right where he left it.',
				'News : local guru claims "there\'s a little bit of ourselves in everyone", under investigation for alleged cannibalism.',
				'News : news writer finds herself daydreaming about new career. Or at least a raise.',
				'News : polls find idea of cookies made of cookies "acceptable" - "at least we finally know what\'s in them", says interviewed citizen.',
				]));
				
				if (G.buildingN('Javascript console')>0) list.push(choose([
				'News : strange fad has parents giving their newborns names such as Emma.js or Liam.js. At least one Baby.js reported.',
				'News : coding is hip! More and more teenagers turn to technical fields like programming, ensuring a future robot apocalypse and the doom of all mankind.',
				'News : developers unsure what to call their new javascript libraries as all combinations of any 3 dictionary words have already been taken.',
				'News : nation holds breath as nested ifs about to hatch.',
				'News : clueless copywriter forgets to escape a quote, ends news line prematurely; last words reported to be "Huh, why isn',
				]));
				
				if (G.buildingN('Idleverse')>0) list.push(choose([
				'News : is another you living out their dreams in an alternate universe? Probably, you lazy bum!',
				'News : public recoils at the notion of a cosmos made of infinite idle games. "I kinda hoped there\'d be more to it", says distraught citizen.',
				'News : with an infinity of parallel universes, people turn to reassuring alternate dimensions, which only number "in the high 50s".',
				'News : "I find solace in the knowledge that at least some of my alternate selves are probably doing fine out there", says citizen\'s last remaining exemplar in the multiverse.',
				'News : comic book writers point to actual multiverse in defense of dubious plot points. "See? I told you it wasn\'t \'hackneyed and contrived\'!"'
				]));
				
				if (G.buildingN('Cortex baker')>0) list.push(choose([
				'News : cortex baker wranglers kindly remind employees that cortex bakers are the bakery\'s material property and should not be endeared with nicknames.',
				'News : space-faring employees advised to ignore unusual thoughts and urges experienced within 2 parsecs of gigantic cortex bakers, say guidelines.',
				'News : astronomers warn of cortex baker trajectory drift, fear future head-on collisions resulting in costly concussions.',
				'News : runt cortex baker identified with an IQ of only quintuple digits: "just a bit of a dummy", say specialists.',
				'News : are you smarter than a cortex baker? New game show deemed "unfair" by contestants.'
				]));
				
				if (G.buildingN('You')>0) list.push(choose([
				'News : the person of the year is, this year again, you! How unexpected!',
				'News : criminals caught sharing pirated copies of your genome may be exposed to fines and up to 17 billion years prison, reminds constable.',
				'News : could local restaurants be serving you bootleg clone meat? Our delicious investigation follows after tonight\'s news.',
				'News : beloved cookie magnate erroneously reported as trampled to death by crazed fans, thankfully found to be escaped clone mistaken for original.',
				'News : "Really, we\'re just looking for some basic societal acceptance and compassion", mumbles incoherent genetic freak Clone #59014.'
				]));
				
				if (G.season=='halloween' && cookies>=1000) list.push(choose([
				'News : strange twisting creatures amass around cookie factories, nibble at assembly lines.',
				'News : ominous wrinkly monsters take massive bites out of cookie production; "this can\'t be hygienic", worries worker.',
				'News : pagan rituals on the rise as children around the world dress up in strange costumes and blackmail homeowners for candy.',
				'News : new-age terrorism strikes suburbs as houses find themselves covered in eggs and toilet paper.',
				'News : children around the world "lost and confused" as any and all Halloween treats have been replaced by cookies.'
				]));
				
				if (G.season=='christmas' && cookies>=1000) list.push(choose([
				'News : bearded maniac spotted speeding on flying sleigh! Investigation pending.',
				'News : Santa Claus announces new brand of breakfast treats to compete with cookie-flavored cereals! "They\'re ho-ho-horrible!" says Santa.',
				'News : "You mean he just gives stuff away for free?!", concerned moms ask. "Personally, I don\'t trust his beard."',
				'News : obese jolly lunatic still on the loose, warn officials. "Keep your kids safe and board up your chimneys. We mean it."',
				'News : children shocked as they discover Santa Claus isn\'t just their dad in a costume after all! "I\'m reassessing my life right now", confides Laura, aged 6.',
				'News : mysterious festive entity with quantum powers still wrecking havoc with army of reindeer, officials say.',
				'News : elves on strike at toy factory! "We will not be accepting reindeer chow as payment anymore. And stop calling us elves!"',
				'News : elves protest around the nation; wee little folks in silly little outfits spread mayhem, destruction; rabid reindeer running rampant through streets.',
				'News : scholars debate regarding the plural of reindeer(s) in the midst of elven world war.',
				'News : elves "unrelated to gnomes despite small stature and merry disposition", find scientists.',
				'News : elves sabotage radioactive frosting factory, turn hundreds blind in vicinity - "Who in their right mind would do such a thing?" laments outraged mayor.',
				'News : drama unfolds at North Pole as rumors crop up around Rudolph\'s red nose; "I may have an addiction or two", admits reindeer.'
				]));
				
				if (G.season=='valentines' && cookies>=1000) list.push(choose([
				'News : organ-shaped confectioneries being traded in schools all over the world; gruesome practice undergoing investigation.',
				'News : heart-shaped candies overtaking sweets business, offering competition to cookie empire. "It\'s the economy, cupid!"',
				'News : love\'s in the air, according to weather specialists. Face masks now offered in every city to stunt airborne infection.',
				'News : marrying a cookie - deranged practice, or glimpse of the future?',
				'News : boyfriend dumped after offering his lover cookies for Valentine\'s Day, reports say. "They were off-brand", shrugs ex-girlfriend.'
				]));
				
				if (G.season=='easter' && cookies>=1000) list.push(choose([
				'News : long-eared critters with fuzzy tails invade suburbs, spread terror and chocolate!',
				'News : eggs have begun to materialize in the most unexpected places; "no place is safe", warn experts.',
				'News : packs of rampaging rabbits cause billions in property damage; new strain of myxomatosis being developed.',
				'News : egg-laying rabbits "not quite from this dimension", warns biologist; advises against petting, feeding, or cooking the creatures.',
				'News : mysterious rabbits found to be egg-layers, but mammalian, hinting at possible platypus ancestry.'
				]));
			}
			
			
			if (Math.random()<0.001)//apologies to Will Wright
			{
				list.push(
				'You have been chosen. They will come soon.',
				'They\'re coming soon. Maybe you should think twice about opening the door.',
				'The end is near. Make preparations.',
				'News : broccoli tops for moms, last for kids; dads indifferent.',
				'News : middle age a hoax, declares study; turns out to be bad posture after all.',
				'News : kitties want answers in possible Kitty Kibble shortage.'
				);
			}
			
			if (cookies>=10000) list.push(
				'News : '+choose([
					'cookies found to '+choose(['increase lifespan','sensibly increase intelligence','reverse aging','decrease hair loss','prevent arthritis','cure blindness'])+' in '+choose(animals)+'!',
					'cookies found to make '+choose(animals)+' '+choose(['more docile','more handsome','nicer','less hungry','more pragmatic','tastier'])+'!',
					'cookies tested on '+choose(animals)+', found to have no ill effects.',
					'cookies unexpectedly popular among '+choose(animals)+'!',
					'unsightly lumps found on '+choose(animals)+' near cookie facility; "they\'ve pretty much always looked like that", say biologists.',
					'new species of '+choose(animals)+' discovered in distant country; "yup, tastes like cookies", says biologist.',
					'cookies go well with '+choose([choose(['roasted','toasted','boiled','sauteed','minced'])+' '+choose(animals),choose(animals)+' '+choose(['sushi','soup','carpaccio','steak','nuggets'])])+', says controversial chef.',
					'"do your cookies contain '+choose(animals)+'?", asks PSA warning against counterfeit cookies.',
					'doctors recommend twice-daily consumption of fresh cookies.',
					'doctors warn against chocolate chip-snorting teen fad.',
					'doctors advise against new cookie-free fad diet.',
					'doctors warn mothers about the dangers of "home-made cookies".'
					]),
				'News : "'+choose([
					'I\'m all about cookies',
					'I just can\'t stop eating cookies. I think I seriously need help',
					'I guess I have a cookie problem',
					'I\'m not addicted to cookies. That\'s just speculation by fans with too much free time',
					'my upcoming album contains 3 songs about cookies',
					'I\'ve had dreams about cookies 3 nights in a row now. I\'m a bit worried honestly',
					'accusations of cookie abuse are only vile slander',
					'cookies really helped me when I was feeling low',
					'cookies are the secret behind my perfect skin',
					'cookies helped me stay sane while filming my upcoming movie',
					'cookies helped me stay thin and healthy',
					'I\'ll say one word, just one : cookies',
					'alright, I\'ll say it - I\'ve never eaten a single cookie in my life'
					])+'", reveals celebrity.',
				choose([
					'News : scientist predicts imminent cookie-related "end of the world"; becomes joke among peers.',
					'News : man robs bank, buys cookies.',
					'News : scientists establish that the deal with airline food is, in fact, a critical lack of cookies.',
					'News : hundreds of tons of cookies dumped into starving country from airplanes; thousands dead, nation grateful.',
					'News : new study suggests cookies neither speed up nor slow down aging, but instead "take you in a different direction".',
					'News : overgrown cookies found in fishing nets, raise questions about hormone baking.',
					'News : "all-you-can-eat" cookie restaurant opens in big city; waiters trampled in minutes.',
					'News : man dies in cookie-eating contest; "a less-than-impressive performance", says judge.',
					'News : what makes cookies taste so right? "Probably all the [*****] they put in them", says anonymous tipper.',
					'News : man found allergic to cookies; "what a weirdo", says family.',
					'News : foreign politician involved in cookie-smuggling scandal.',
					'News : cookies now more popular than '+choose(['cough drops','broccoli','smoked herring','cheese','video games','stable jobs','relationships','time travel','cat videos','tango','fashion','television','nuclear warfare','whatever it is we ate before','politics','oxygen','lamps'])+', says study.',
					'News : obesity epidemic strikes nation; experts blame '+choose(['twerking','that darn rap music','video-games','lack of cookies','mysterious ghostly entities','aliens','parents','schools','comic-books','cookie-snorting fad'])+'.',
					'News : cookie shortage strikes town, people forced to eat cupcakes; "just not the same", concedes mayor.',
					'News : "you gotta admit, all this cookie stuff is a bit ominous", says confused idiot.',
				]),
				choose([
					'News : movie cancelled from lack of actors; "everybody\'s at home eating cookies", laments director.',
					'News : comedian forced to cancel cookie routine due to unrelated indigestion.',
					'News : new cookie-based religion sweeps the nation.',
					'News : fossil records show cookie-based organisms prevalent during Cambrian explosion, scientists say.',
					'News : mysterious illegal cookies seized; "tastes terrible", says police.',
					'News : man found dead after ingesting cookie; investigators favor "mafia snitch" hypothesis.',
					'News : "the universe pretty much loops on itself," suggests researcher; "it\'s cookies all the way down."',
					'News : minor cookie-related incident turns whole town to ashes; neighboring cities asked to chip in for reconstruction.',
					'News : is our media controlled by the cookie industry? This could very well be the case, says crackpot conspiracy theorist.',
					'News : '+choose(['cookie-flavored popcorn pretty damn popular; "we kinda expected that", say scientists.','cookie-flavored cereals break all known cereal-related records.','cookies popular among all age groups, including fetuses, says study.','cookie-flavored popcorn sales exploded during screening of Grandmothers II : The Moistening.']),
					'News : all-cookie restaurant opening downtown. Dishes such as braised cookies, cookie thermidor, and for dessert : crepes.',
					'News : "Ook", says interviewed orangutan.',
					'News : cookies could be the key to '+choose(['eternal life','infinite riches','eternal youth','eternal beauty','curing baldness','world peace','solving world hunger','ending all wars world-wide','making contact with extraterrestrial life','mind-reading','better living','better eating','more interesting TV shows','faster-than-light travel','quantum baking','chocolaty goodness','gooder thoughtness'])+', say scientists.',
					'News : flavor text '+choose(['not particularly flavorful','kind of unsavory'])+', study finds.',
				]),
				choose([
					'News : what do golden cookies taste like? Study reveals a flavor "somewhere between spearmint and liquorice".',
					'News : what do wrath cookies taste like? Study reveals a flavor "somewhere between blood sausage and seawater".',
					//'News : '+G.bakeryName+'-brand cookies "'+choose(['much less soggy','much tastier','relatively less crappy','marginally less awful','less toxic','possibly more edible','more fashionable','slightly nicer','trendier','arguably healthier','objectively better choice','slightly less terrible','decidedly cookier','a tad cheaper'])+' than competitors", says consumer survey.',
					//'News : "'+G.bakeryName+'" set to be this year\'s most popular baby name.',
					//'News : new popularity survey says '+G.bakeryName+'\'s the word when it comes to cookies.',
					//'News : major city being renamed '+G.bakeryName+'ville after world-famous cookie manufacturer.',
					//'News : '+choose(['street','school','nursing home','stadium','new fast food chain','new planet','new disease','flesh-eating virus','deadly bacteria','new species of '+choose(animals),'new law','baby','programming language'])+' to be named after '+G.bakeryName+', the world-famous cookie manufacturer.',
					//'News : don\'t miss tonight\'s biopic on '+G.bakeryName+'\'s irresistible rise to success!',
					//'News : don\'t miss tonight\'s interview of '+G.bakeryName+' by '+choose(['Bloprah','Blavid Bletterman','Blimmy Blimmel','Blellen Blegeneres','Blimmy Blallon','Blonan Blo\'Brien','Blay Bleno','Blon Blewart','Bleven Blolbert','Lord Toxikhron of dimension 7-B19',G.bakeryName+'\'s own evil clone'])+'!',
					'News : people all over the internet still scratching their heads over nonsensical reference : "Okay, but why an egg?"',
					'News : viral video "Too Many Cookies" could be "a grim commentary on the impending crisis our world is about to face", says famous economist.',
					'News : "memes from last year somehow still relevant", deplore experts.',
					'News : cookie emoji most popular among teenagers, far ahead of "judgemental OK hand sign" and "shifty-looking dark moon", says study.',
				]),
				choose([
					'News : births of suspiciously bald babies on the rise; reptilian overlords deny involvement.',
					'News : "at this point, cookies permeate the economy", says economist. "If we start eating anything else, we\'re all dead."',
					'News : pun in headline infuriates town, causes riot. 21 wounded, 5 dead; mayor still missing.',
					'Nws : ky btwn W and R brokn, plas snd nw typwritr ASAP.',
					'Neeeeews : "neeeew EEEEEE keeeeey working fineeeeeeeee", reeeports gleeeeeeeeful journalist.',
					'News : cookies now illegal in some backwards country nobody cares about. Political tensions rising; war soon, hopefully.',
					'News : irate radio host rambles about pixelated icons. "None of the cookies are aligned! Can\'t anyone else see it? I feel like I\'m taking crazy pills!"',
					'News : nation cheers as legislators finally outlaw '+choose(['cookie criticism','playing other games than Cookie Clicker','pineapple on pizza','lack of cheerfulness','mosquitoes','broccoli','the human spleen','bad weather','clickbait','dabbing','the internet','memes','millenials'])+'!',
					'News : '+choose(['local','area'])+' '+choose(['man','woman'])+' goes on journey of introspection, finds cookies : "I honestly don\'t know what I was expecting."',
					'News : '+choose(['man','woman'])+' wakes up from coma, '+choose(['tries cookie for the first time, dies.','regrets it instantly.','wonders "why everything is cookies now".','babbles incoherently about some supposed "non-cookie food" we used to eat.','cites cookies as main motivator.','asks for cookies.']),
					'News : pet '+choose(animals)+', dangerous fad or juicy new market?',
					'News : person typing these wouldn\'t mind someone else breaking the news to THEM, for a change.',
					//'News : "average person bakes '+B(Math.ceil(cookies/7300000000))+' cookie'+(Math.ceil(cookies/7300000000)==1?'':'s')+' a year" factoid actually just statistical error; '+G.bakeryName+', who has produced '+B(cookies)+' cookies in their lifetime, is an outlier and should not have been counted.'
					'News : "Cookies are still produced while the game is closed", say experts on the nature of our reality. Up next: the terrifying implications behind this statement.',
					'News : 97-year-old baker still makes cookies the old-fashioned way!',
				])
			);
		}
		
		if (list.length==0)
		{
			if (loreProgress<=0) list.push('You feel like making cookies. But nobody wants to eat your cookies...');
			else if (loreProgress<=1) list.push('Your first batch goes to the trash. The neighborhood raccoon barely touches it.');
			else if (loreProgress<=2) list.push('Your family agrees to try some of your cookies.');
			else if (loreProgress<=3) list.push('Your cookies are popular in the neighborhood.','People are starting to talk about your cookies.');
			else if (loreProgress<=4) list.push('Your cookies are talked about for miles around.','Your cookies are renowned in the whole town!');
			else if (loreProgress<=5) list.push('Your cookies bring all the boys to the yard.','Your cookies now have their own website!');
			else if (loreProgress<=6) list.push('Your cookies are worth a lot of money.','Your cookies sell very well in distant countries.');
			else if (loreProgress<=7) list.push('People come from very far away to get a taste of your cookies.','Kings and queens from all over the world are enjoying your cookies.');
			else if (loreProgress<=8) list.push('There are now museums dedicated to your cookies.','A national day has been created in honor of your cookies.');
			else if (loreProgress<=9) list.push('Your cookies have been named a part of the world wonders.','History books now include a whole chapter about your cookies.');
			else if (loreProgress<=10) list.push('Your cookies have been placed under government surveillance.','The whole planet is enjoying your cookies!');
			else if (loreProgress<=11) list.push('Strange creatures from neighboring planets wish to try your cookies.','Elder gods from the whole cosmos have awoken to taste your cookies.');
			else if (loreProgress<=12) list.push('Beings from other dimensions lapse into existence just to get a taste of your cookies.','Your cookies have achieved sentience.');
			else if (loreProgress<=13) list.push('The universe has now turned into cookie dough, to the molecular level.','Your cookies are rewriting the fundamental laws of the universe.');
			else if (loreProgress<=14) list.push('A local news station runs a 10-minute segment about your cookies. Success! <span style="font-size:50%;">(you win a cookie)</span>','it\'s time to stop playing');
		}
		if (G.elderWrath>0 && (((G.pledges==0 && G.resets==0) && Math.random()<0.5) || Math.random()<0.05))
		{
			list=[];
			if (G.elderWrath==1) list.push(choose([
				'News : millions of old ladies reported missing!',
				'News : processions of old ladies sighted around cookie facilities!',
				'News : families around the continent report agitated, transfixed grandmothers!',
				'News : doctors swarmed by cases of old women with glassy eyes and a foamy mouth!',
				'News : nurses report "strange scent of cookie dough" around female elderly patients!'
			]));
			if (G.elderWrath==2) list.push(choose([
				'News : town in disarray as strange old ladies break into homes to abduct infants and baking utensils!',
				'News : sightings of old ladies with glowing eyes terrify local population!',
				'News : retirement homes report "female residents slowly congealing in their seats"!',
				'News : whole continent undergoing mass exodus of old ladies!',
				'News : old women freeze in place in streets, ooze warm sugary syrup!'
			]));
			if (G.elderWrath==3) list.push(choose([
				'News : large "flesh highways" scar continent, stretch between various cookie facilities!',
				'News : wrinkled "flesh tendrils" visible from space!',
				'News : remains of "old ladies" found frozen in the middle of growing fleshy structures!', 
				'News : all hope lost as writhing mass of flesh and dough engulfs whole city!',
				'News : nightmare continues as wrinkled acres of flesh expand at alarming speeds!'
			]));
		}
		
		if (G.season=='fools')
		{
			list=[];
			
			if (cookies>=1000) list.push(choose([
				choose(['Your office chair is really comfortable.','Profit\'s in the air!','Business meetings are such a joy!','What a great view from your office!','Smell that? That\'s capitalism, baby!','You truly love answering emails.','Working hard, or hardly working?','Another day in paradise!','Expensive lunch time!','Another government bailout coming up! Splendid!','These profits are doing wonderful things for your skin.','You daydream for a moment about a world without taxes.','You\'ll worry about environmental damage when you\'re dead!','Yay, office supplies!','Sweet, those new staplers just came in!','Ohh, coffee break!']),
				choose(['You\'ve spent the whole day','Another great day','First order of business today:','Why, you truly enjoy','What next? That\'s right,','You check what\'s next on the agenda. Oh boy,'])+' '+choose(['signing contracts','filling out forms','touching base with the team','examining exciting new prospects','playing with your desk toys','getting new nameplates done','attending seminars','videoconferencing','hiring dynamic young executives','meeting new investors','updating your rolodex','pumping up those numbers','punching in some numbers','getting investigated for workers\' rights violations','reorganizing documents','belittling underlings','reviewing employee performance','revising company policies','downsizing','pulling yourself up by your bootstraps','adjusting your tie','performing totally normal human activities','recentering yourself in the scream room','immanentizing the eschaton','shredding some sensitive documents','comparing business cards','pondering the meaning of your existence','listening to the roaring emptiness inside your soul','playing minigolf in your office'])+'!',
				'The word of the day is: '+choose(['viral','search engine optimization','blags and wobsites','social networks','webinette','staycation','user experience','crowdfunding','carbon neutral','big data','machine learning','disrupting','influencers','monoconsensual transactions','sustainable','freemium','incentives','grassroots','web 3.0'/*this was before this whole crypto mess i'm so sorry*/,'logistics','leveraging','branding','proactive','synergizing','market research','demographics','pie charts','blogular','blogulacious','blogastic','authenticity','plastics','electronic mail','cellular phones','rap music','bulbs','goblinization','straight-to-bakery','microbakeries','chocolativity','flavorfulness','tastyfication','sugar offsets','activated wheat','reification','immanentize the eschaton','cookies, I guess'])+'.'
			]));
			if (cookies>=1000 && Math.random()<0.05) list.push(choose([
				'If you could get some more cookies baked, that\'d be great.',
				'So. About those TPS reports.',
				'Hmm, you\'ve got some video tapes to return.',
				'They\'ll pay. They\'ll all pay.',
				'You haven\'t even begun to peak.',
				'There is an idea of a baker. Some kind of abstraction. But there is no real you, only an entity. Something illusory.',
				'This was a terrible idea!'
			]));
			
			
			if (G.tickerN%2==0)
			{
				if (G.buildingN('Cursor')>0) list.push(choose([
				'Your rolling pins are rolling and pinning!',
				'Production is steady!'
				]));
				
				if (G.buildingN('Grandma')>0) list.push(choose([
				'Your ovens are diligently baking more and more cookies.',
				'Your ovens burn a whole batch. Ah well! Still good.'
				]));
				
				if (G.buildingN('Farm')>0) list.push(choose([
				'Scores of cookies come out of your kitchens.',
				'Today, new recruits are joining your kitchens!'
				]));
				
				if (G.buildingN('Mine')>0) list.push(choose([
				'Your secret recipes are kept safely inside a giant underground vault.',
				'Your chefs are working on new secret recipes!'
				]));
				
				if (G.buildingN('Factory')>0) list.push(choose([
				'Your factories are producing an unending stream of baked goods.',
				'Your factory workers decide to go on strike!',
				'It\'s safety inspection day in your factories.'
				]));
					
				if (G.buildingN('Bank')>0) list.push(choose([
				'Your shareholders are watching your business with great interest.',
				'Your investors are expecting to get their money\'s worth.',
				'Money talks! Your shares are soaring in value.'
				]));
				
				if (G.buildingN('Temple')>0) list.push(choose([
				'Your social media managers are engaging in friendly ribbing with other brands!',
				'Another viral cookie post! Your social media managers are killing it.',
				'Your social media posts are fine-tuned for maximal user engagement!'
				]));
				
				if (G.buildingN('Wizard tower')>0) list.push(choose([
				'Your cookie memes have been deemed "epic" and "awesomesauce" by a panel of experts!',
				'"Cringe" or "based"? Experts weigh in on your cookie memes.',
				'You\'ve successfully covered up another scandal with an onslaught of mildly-entertaining memes!'
				]));
				
				if (G.buildingN('Shipment')>0) list.push(choose([
				'Your supermarkets are bustling with happy, hungry customers.',
				'Your supermarkets are full of cookie merch!'
				]));
				
				if (G.buildingN('Alchemy lab')>0) list.push(choose([
				'It\'s a new trading day at the stock exchange, and traders can\'t get enough of your shares!',
				'Your stock is doubling in value by the minute!'
				]));
				
				if (G.buildingN('Portal')>0) list.push(choose([
				'You just released a new TV show episode!',
				'Your cookie-themed TV show is being adapted into a new movie!'
				]));
				
				if (G.buildingN('Time machine')>0) list.push(choose([
				'Your theme parks are doing well - puddles of vomit and roller-coaster casualties are being swept under the rug!',
				'Visitors are stuffing themselves with cookies before riding your roller-coasters. You might want to hire more clean-up crews.'
				]));
				
				if (G.buildingN('Antimatter condenser')>0) list.push(choose([
				'Cookiecoin is officially the most mined digital currency in the history of mankind!',
				'Cookiecoin piracy is rampant!'
				]));
				
				if (G.buildingN('Prism')>0) list.push(choose([
				'Your corporate nations just gained a new parliament!',
				'You\'ve just annexed a new nation!',
				'A new nation joins the grand cookie conglomerate!'
				]));
				
				if (G.buildingN('Chancemaker')>0) list.push(choose([
				'Your intergalactic federation of cookie-sponsored planets reports record-breaking profits!',
				'Billions of unwashed aliens are pleased to join your workforce as you annex their planet!',
				'New toll opened on interstellar highway, funnelling more profits into the cookie economy!'
				]));
				
				if (G.buildingN('Fractal engine')>0) list.push(choose([
				'Your cookie-based political party is doing fantastic in the polls!',
				'New pro-cookie law passes without a hitch thanks to your firm grasp of the political ecosystem!',
				'Your appointed senators are overturning cookie bans left and right!'
				]));
				
				if (G.buildingN('Javascript console')>0) list.push(choose([
				'Cookies are now one of the defining aspects of mankind! Congratulations!',
				'Time travelers report that this era will later come to be known, thanks to you, as the cookie millennium!',
				'Cookies now deeply rooted in human culture, likely puzzling future historians!'
				]));
				
				if (G.buildingN('Idleverse')>0) list.push(choose([
				'Public aghast as all remaining aspects of their lives overtaken by universal cookie industry!',
				'Every single product currently sold in the observable universe can be traced back to your company! And that\'s a good thing.',
				'Antitrust laws let out a helpless whimper before being engulfed by your sprawling empire!'
				]));
				
				if (G.buildingN('Cortex baker')>0) list.push(choose([
				'Bold new law proposal would grant default ownership of every new idea by anyone anywhere to famous baker!',
				'Bakery think tanks accidentally reinvent cookies for the 57th time this week!',
				'Bakery think tanks invent entire new form of human communication to advertise and boost cookie sales!'
				]));
				
				if (G.buildingN('You')>0) list.push(choose([
				'Famous baker releases new self-help book: "How I Made My '+B(cookies)+' Cookies And How You Can Too"!',
				'Don\'t miss our interview tonight with this stupefying local baker who discusses where to go next once you\'re at the top!',
				'Fame, beauty, biscuits; this baker has it all - but is it enough?'
				]));
			}
			
			if (loreProgress<=0) list.push('Such a grand day to begin a new business.');
			else if (loreProgress<=1) list.push('You\'re baking up a storm!');
			else if (loreProgress<=2) list.push('You are confident that one day, your cookie company will be the greatest on the market!');
			else if (loreProgress<=3) list.push('Business is picking up!');
			else if (loreProgress<=4) list.push('You\'re making sales left and right!');
			else if (loreProgress<=5) list.push('Everyone wants to buy your cookies!');
			else if (loreProgress<=6) list.push('You are now spending most of your day signing contracts!');
			else if (loreProgress<=7) list.push('You\'ve been elected "business tycoon of the year"!');
			else if (loreProgress<=8) list.push('Your cookies are a worldwide sensation! Well done, old chap!');
			else if (loreProgress<=9) list.push('Your brand has made its way into popular culture. Children recite your slogans and adults reminisce them fondly!');
			else if (loreProgress<=10) list.push('A business day like any other. It\'s good to be at the top!');
			else if (loreProgress<=11) list.push('You look back on your career. It\'s been a fascinating journey, building your baking empire from the ground up.');
		}
		
		if (G.T>G.fps*10 && G.Has('Fortune cookies') && Math.random()<(G.HasAchiev('O Fortuna')?0.04:0.02))
		{
			var fortunes=[];
			for (var i in G.upgradeTiers['fortune'])
			{
				var it=G.upgradeTiers['fortune'][i];
				if (!G.HasUnlocked(it.name)) fortunes.push(it);
			}
			
			if (!G.fortuneGC) fortunes.push('fortuneGC');
			if (!G.fortuneCPS) fortunes.push('fortuneCPS');
			
			if (fortunes.length>0)
			{
				list=[];
				let me=choose(fortunes);
				let effect=me;
				
				if (effect=='fortuneGC') me="Today is your lucky day!";/*<br>Click here for a golden cookie.';*/
				else if (effect=='fortuneCPS') {Math.seedrandom(G.seed+'-fortune');me="Your lucky numbers are:"+' '+Math.floor(Math.random()*100)+' '+Math.floor(Math.random()*100)+' '+Math.floor(Math.random()*100)+' '+Math.floor(Math.random()*100)/*+'<br>Click here to gain one hour of your CpS.'*/;Math.seedrandom();}
				else
				{
					me=effect.name.substring(effect.name.indexOf('#'))+' : '+effect.q;
				}
				
				me='<span style="color:#ade000;pointer-events:auto;"><div class="icon" style="vertical-align:middle;display:inline-block;background-position:'+(-29*48)+'px '+(-8*48)+'px;transform:scale(0.5);margin:-16px;position:relative;left:-4px;top:0px;"></div>'+me+'</span>';
				list=[{text:me,onclick:(el)=>{
					triggerAnim(el,'fadeWhiteOut');
					setTimeout(()=>{el.innerHTML='';el.classList.remove('fadeWhiteOut');},450);
					PlaySound('snd/fortune.mp3',1);
					
					if (effect=='fortuneGC')
					{
						G.toast(`Fortune!`,`A golden cookie has appeared.`,[10,32],true);
						G.fortuneGC=1;
						let newShimmer=new G.shimmer('golden',{noWrath:true});
					}
					else if (effect=='fortuneCPS')
					{
						G.toast(`Fortune!`,`You gain <b>one hour</b> of your CpS (capped at double your bank).`,[10,32],true);
						G.fortuneCPS=1;
						G.earn(Math.min(G.cookiesPs*60*60,G.cookies));
					}
					else
					{
						if (!effect.unlocked)
						{
							G.toast(effect.name,`You've unlocked a new upgrade.`,effect.icon,true);
							effect.unlock();
						}
					}
				}}];
			}
		}
		
		return choose(list);
	}
	
	G.ondown(G.ticker1L,()=>{if (G.ticker1onClick){G.ticker1onClick(G.ticker1L);G.ticker1onClick=0;}});
	G.ondown(G.ticker2L,()=>{if (G.ticker2onClick){G.ticker2onClick(G.ticker2L);G.ticker2onClick=0;}});
	
	G.savedNews=[];
	
	G.tickerLogic=function(delta)
	{
		var left=0;
		var right=G.w-left;
		var speed=2*delta;
		var gap=48;
		let ticker=0;
		if (G.ticker1W==0)
		{
			G.ticker1onClick=0;
			ticker=G.getTicker();
			if (typeof ticker==='object')
			{
				G.ticker1onClick=ticker.onclick||0;
				ticker=ticker.text;
			}
			
			G.ticker1L.innerHTML=ticker;
			G.ticker1W=G.ticker1L.offsetWidth;
			G.ticker1X=Math.max(right,left+G.ticker2X+G.ticker2W)+gap;
		}
		else if (G.ticker2W==0)
		{
			G.ticker2onClick=0;
			ticker=G.getTicker();
			if (typeof ticker==='object')
			{
				G.ticker2onClick=ticker.onclick||0;
				ticker=ticker.text;
			}
			
			G.ticker2L.innerHTML=ticker;
			G.ticker2W=G.ticker2L.offsetWidth;
			G.ticker2X=Math.max(right,left+G.ticker1X+G.ticker1W)+gap;
		}
		
		if (ticker)
		{
			var ind=G.savedNews.findIndex(v=>v[0]==ticker);
			if (ind!=-1) G.savedNews.splice(ind,1);//overwrite duplicates
			G.savedNews.unshift([ticker,Date.now()]);
			if (G.savedNews.length>50) G.savedNews.pop();
			G.tickerN++;
		}
		
		G.ticker1X-=speed;
		G.ticker2X-=speed;
		if (G.ticker1X<-G.ticker1W+left) {G.ticker1W=0;}
		if (G.ticker2X<-G.ticker2W+left) {G.ticker2W=0;}
	}
	G.tickerDraw=function()
	{
		G.ticker1L.style.transform='translate3d('+G.ticker1X+'px,0px,0)';
		G.ticker2L.style.transform='translate3d('+G.ticker2X+'px,0px,0)';
	}
	
//===========================================================================
//PINS & HIDDEN SLOTS
//===========================================================================
G.hiddenSlots=['pinSpecial','pinStats','pinMisc','orteilTip'];
G.getHiddenUpgradeForSlot=function(slot,all)
{
	/*
		principle:
		some upgrades (season drops, fortunes etc) can be found in hidden slots in addition to their normal places.
		each upgrade has one slot it appears in, dependent on save seed. it may also not appear in any slot this ascension.
		each slot may have multiple hidden upgrades; they will show up in succession.
	*/
	Math.seedrandom(G.seed+'-hiddenSlot-'+slot);
	
	let upgrades=[];
	if (G.Has('Fortune cookies') || all)
	{
		upgrades.push('Fortune #001','Fortune #002','Fortune #003','Fortune #004','Fortune #005','Fortune #006','Fortune #007','Fortune #008','Fortune #009','Fortune #010','Fortune #011','Fortune #012','Fortune #013','Fortune #014','Fortune #015','Fortune #016','Fortune #017','Fortune #018','Fortune #019','Fortune #020');
	}
	if (G.season=='easter' || all) upgrades.push(...G.easterEggs);
	if (G.season=='christmas' || all) upgrades.push(...G.reindeerDrops);
	if (G.season=='halloween' || all) upgrades.push(...G.halloweenDrops);
	
	upgrades=upgrades.map(me=>G.upgradesBN[me]);
	if (!all) upgrades=upgrades.filter(me=>!me.unlocked);
	shuffle(upgrades);
	let upgrades2=[];
	for (let i=0;i<upgrades.length;i++)
	{
		Math.seedrandom(G.seed+'-hiddenSlotUpgrade-'+upgrades[i].id);
		if (Math.random()<0.15 && slot==choose(G.hiddenSlots)) upgrades2.push(upgrades[i]);
	}
	upgrades=upgrades2;
	
	Math.seedrandom();
	return upgrades.length>0?(all?upgrades:upgrades[0]):0;
}
/*
G.addPostData(()=>{
	for (var i in G.hiddenSlots)
	{
		let upgrades=G.getHiddenUpgradeForSlot(G.hiddenSlots[i],true);
		if (upgrades) upgrades=upgrades.map(me=>me.name);
		console.log('slot',G.hiddenSlots[i],'can drop:',upgrades);
	}
});
*/
G.toyPins=function(el)
{
	if (!el) return;
	let pins=el.querySelectorAll('.headerTitle');
	for (let i=0;i<pins.length;i++)
	{
		let pin=pins[i];
		let textL=document.createElement('div');
		textL.style.cssText=`
		position:absolute;left:0px;top:0px;
		padding:6px 6px 0px 8px;
		transform-origin:50% 70% -16px;
		backface-visibility:hidden;
		`;
		pin.style.cssText=`perspective:200px;z-index:1;`;
		textL.innerHTML=pin.innerHTML;
		let textGhostL=document.createElement('span');textGhostL.innerHTML=pin.innerHTML;textGhostL.style.visibility='hidden';
		pin.innerHTML='';
		pin.appendChild(textGhostL);pin.appendChild(textL);
		
		let upgradeL=0;
		
		let on=false,r=0,offr=0,fromY=0,onY=0,prevY=0,dampenT=0,timeout=0;
		AddEvent(pin,'touchstart',function(e){
			if (e.touches.length==1)
			{
				if (timeout) clearTimeout(timeout);
				e.preventDefault();
				var touch=e.touches[0];
				fromY=Rescale(touch.screenY);
				onY=fromY;prevY=onY;
				on=true;
				dampenT=0;
				
				let upgrade=0;
				if (pin.dataset.hiddenslot)
				{
					upgrade=G.getHiddenUpgradeForSlot(pin.dataset.hiddenslot);
					if (upgrade && !upgrade.unlocked)
					{
						if (!upgradeL)
						{
							upgradeL=document.createElement('div');
							upgradeL.classList.add('icon');
							upgradeL.style.cssText=`position:absolute;left:50%;top:-8px;margin-left:-24px;transform:scale(0.5);opacity:0;transform-origin:50% 50% -16px;backface-visibility:hidden;`;
							pin.appendChild(upgradeL);
						}
						upgradeL.style.backgroundPosition=`${-upgrade.icon[0]*48}px ${-upgrade.icon[1]*48}px`;
						upgradeL.classList.remove('hidden');
					}
					else if (upgradeL) upgradeL.classList.add('hidden');
				}
				
				let func=()=>{
					if (!on)
					{
						r=Math.cos(dampenT*0.5)*Math.pow(1-(dampenT/(G.fps*3)),5)*offr;
						dampenT++;
					}
					else r=Math.max(-1,Math.min(1,(fromY-onY)/64));
					textL.style.transform=`rotateX(${r*80}deg)`;
					textL.style.opacity=1-0.8*Math.abs(r);
					if (upgrade && upgradeL && !upgrade.unlocked)
					{
						upgradeL.style.transform=`rotateX(${r*80+90}deg) scale(0.5)`;
						upgradeL.style.opacity=Math.abs(r);
						if (r<=-0.99)
						{
							PlaySound('snd/giftSend.mp3',0.5);
							G.toast(upgrade.name,`You unlocked an upgrade!`,upgrade.icon,true);
							upgrade.unlock();
							var rect=RescaleBox(upgradeL.getBoundingClientRect());
							G.particleAt({
								r:0,
								s:0.5,
								x:(rect.left+rect.right)/2,
								y:(rect.top+rect.bottom)/2,
								xd:Math.random()*4-2,
								yd:-5,
								pic:upgrade.icon,
							});
							G.sparkleOn(upgradeL);
							upgradeL.classList.add('hidden');
							upgrade=0;upgradeL=0;
						}
					}
					if (on || dampenT<G.fps*3) timeout=setTimeout(func,1000/G.fps);
					else textL.style.transform='none';
				};
				func();
				return false;
			}
		});
		AddEvent(pin,'touchmove',function(e){
			if (e.touches.length>0)
			{
				e.preventDefault();
				var touch=e.touches[0];
				prevY=onY;
				onY=Rescale(touch.screenY);
				return false;
			}
		});
		AddEvent(pin,['touchend','touchcancel'],function(e){
			e.preventDefault();
			on=false;
			r+=-(onY-prevY)/64*2;
			offr=r;
			return false;
		});
	}
}
//===========================================================================
//BUFFS
//===========================================================================
	G.buffTypes=[];
	G.buffTypesBN={};
	G.buffType=function(o)
	{
		this.type=0;//note: 1=good, 2=bad
		this.stackT=1;//0: replace previous buff with this one with new T, 1: add T of this and old, 2: set T to max of this and old
		this.stackPow=2;//0: replace previous buff with this one with new pow, 1: add pow of this and old, 2: set pow to max of this and old
		this.t=1;//time (in seconds)
		this.pow=1;//power (used by some effects)
		this.init=0;//init function: called when the buff is created; use this to alter pow, t etc
		this.effsFunc=0;//effects function: when a buff of this type is created, its .effs are set to its type's .effsFunc(buff)
			//NOTE: the effect function needs to be deterministic, and the game should be able to recreate the effects on save load
		transfer(this,o);
		this.buffs=[];//instances
		G.buffTypes.push(this);
		G.buffTypesBN[this.name]=this;
	}
	
	//todo: stack behavior (add time, replace, ignore, pow merge func)
	
	let basicCpsModDesc=function(me){return `Cookie production <b>${me.pow==2?'doubled':me.pow==0.5?'halved':(me.pow>1 && me.pow<2)?('+'+B((me.pow-1)*100,2)+'%'):('x'+B(me.pow,2))}</b> for <b>[t]</b>.`;};
	
	new G.buffType({
		name:'frenzy',
		nameD:'Frenzy',
		icon:[10,14],
		desc:basicCpsModDesc,
		effsFunc:function(me){return [['cpsBuffM',me.pow,1],['reindeerEffectsMultM',0.75,1]];},
		t:10,
		pow:7,
		type:1,
	});
	new G.buffType({
		name:'elderFrenzy',
		nameD:'Elder frenzy',
		icon:[29,6],
		desc:basicCpsModDesc,
		effsFunc:function(me){return [['cpsBuffM',me.pow,1],['reindeerEffectsMultM',0.5,1]];},
		t:10,
		pow:7,
		type:1,
	});
	new G.buffType({
		name:'clot',
		nameD:'Clot',
		icon:[15,5],
		desc:basicCpsModDesc,
		effsFunc:function(me){return [['cpsBuffM',me.pow,1]];},
		t:10,
		pow:0.5,
		type:2,
	});
	new G.buffType({
		name:'dragonHarvest',
		nameD:'Dragon harvest',
		icon:[10,25],
		desc:basicCpsModDesc,
		init:function(me){if (G.Has('Dragon fang')){me.pow=Math.ceil(me.pow*1.1);}},
		effsFunc:function(me){return [['cpsBuffM',me.pow,1]];},
		t:10,
		pow:10,
		type:1,
	});
	new G.buffType({
		name:'sales',
		nameD:'Everything must go!',
		icon:[17,6],
		desc:function(me){return `All buildings are <b>${B(100-me.pow*100,2)}% cheaper</b> for <b>[t]</b>.`;},
		effsFunc:function(me){return [['buildingCostM',me.pow,1]];},
		t:10,
		pow:0.95,
		type:1,
	});
	new G.buffType({
		name:'cursedFinger',
		nameD:'Cursed finger',
		icon:[12,17],
		desc:function(me){return `Cookie production halted for <b>[t]</b>, but each click is worth <b>[t]</b> of CpS.`;},
		effsFunc:function(me){return [];},//this is done manually in G.computeCps
		t:10,
		pow:0,
		type:2,
	});
	new G.buffType({
		name:'clickFrenzy',
		nameD:'Click frenzy',
		icon:[0,14],
		desc:function(me){return `Clicking power <b>x${B(me.pow,2)}</b> for <b>[t]</b>.`;},
		effsFunc:function(me){return [['clickM',me.pow,1]];},
		t:10,
		pow:7,
		type:1,
	});
	new G.buffType({
		name:'dragonflight',
		nameD:'Dragonflight',
		icon:[0,25],
		desc:function(me){return `Clicking power <b>x${B(me.pow,2)}</b> for <b>[t]</b>.`;},
		init:function(me){if (G.Has('Dragon fang')){me.pow=Math.ceil(me.pow*1.1);}},
		effsFunc:function(me){return [['clickM',me.pow,1]];},
		t:10,
		pow:7,
		type:1,
	});
	new G.buffType({
		name:'cookieStorm',
		nameD:'Cookie storm',
		icon:[22,6],
		desc:function(me){return `Cookies everywhere!`;},
		effsFunc:function(me){return [];},
		t:10,
		pow:7,
		type:1,
	});
	new G.buffType({
		name:'powerClick',
		nameD:'Power poked',
		icon:[30,36],
		desc:basicCpsModDesc,
		effsFunc:function(me){return [['cpsBuffM',me.pow,1]];},
		t:10,
		pow:1.05,
		type:1,
	});
	
	G.addPostData(function(){
		let goldenCookieBuildingBuffs={
			'Cursor':['High-five','Slap to the face'],
			'Grandma':['Congregation','Senility'],
			'Farm':['Luxuriant harvest','Locusts'],
			'Mine':['Ore vein','Cave-in'],
			'Factory':['Oiled-up','Jammed machinery'],
			'Bank':['Juicy profits','Recession'],
			'Temple':['Fervent adoration','Crisis of faith'],
			'Wizard tower':['Manabloom','Magivores'],
			'Shipment':['Delicious lifeforms','Black holes'],
			'Alchemy lab':['Breakthrough','Lab disaster'],
			'Portal':['Righteous cataclysm','Dimensional calamity'],
			'Time machine':['Golden ages','Time jam'],
			'Antimatter condenser':['Extra cycles','Predictable tragedy'],
			'Prism':['Solar flare','Eclipse'],
			'Chancemaker':['Winning streak','Dry spell'],
			'Fractal engine':['Macrocosm','Microcosm'],
			'Javascript console':['Refactoring','Antipattern'],
			'Idleverse':['Cosmic nursery','Big crunch'],
			'Cortex baker':['Brainstorm','Brain freeze'],
			'You':['Deduplication','Clone strike'],
		};
		
		for (var i=0;i<G.buildings.length;i++)
		{
			let building=G.buildings[i];
			new G.buffType({
				name:'buildingBuff'+i,
				nameD:goldenCookieBuildingBuffs[building.name][0],
				icon:[building.icon[0],14],
				desc:function(me){return `Your <b>${B(building.amount)} ${building.plural}</b> are boosting your CpS!<br>Cookie production <b>+${B((building.amount/10+1)*100-100,2)}%</b> for <b>[t]</b>.`;},
				effsFunc:function(me){return [['cpsBuffM',v=>{if (building.amount<=0) return v;return v*(building.amount/10+1);},2]];},
				t:10,
				pow:i,
				type:1,
				stackPow:0,
			});
			new G.buffType({
				name:'buildingDebuff'+i,
				nameD:goldenCookieBuildingBuffs[building.name][1],
				icon:[building.icon[0],15],
				desc:function(me){return `Your <b>${B(building.amount)} ${building.plural}</b> are rusting your CpS!<br>Cookie production <b>${B((building.amount/10+1)*100-100,2)}% slower</b> for <b>[t]</b>.`;},
				effsFunc:function(me){return [['cpsBuffM',v=>{if (building.amount<=0) return v;return v*1/(building.amount/10+1);},2]];},
				t:10,
				pow:i,
				type:2,
				stackPow:0,
			});
		}
	});
	
	
	G.buffsL=l('buffs');
	
	//show buffs popup when we click the buffs display
	G.onclick(G.buffsL,e=>{
		if (G.buffs.length==0) return false;
		G.popup({text:`
			<h3>Active buffs</h3>
			<div class="debugOnly" style="text-align:center;">`+G.button({text:'Clear all',classes:'bumpButton',onclick:function(){G.resetBuffs();}})+`</div>
			<div style="font-size:11px;margin:0px -16px;color:#fff;">
			`+G.selfUpdatingText(e=>{
				var str=``;
				for (var i=0;i<G.buffs.length;i++)
				{
					var me=G.buffs[i];
					var type=me.type;
					str+=`
					<div style="display:flex;align-items:center;justify-content:flex-start;padding:4px;overflow:hidden;border-top:1px solid rgba(255,255,255,0.2);border-bottom:1px solid rgba(0,0,0,0.2);position:relative;padding-left:48px;background:linear-gradient(8deg,rgba(${type.type==1?'50,255,100,0.3':type.type==2?'255,100,50,0.3':'255,255,255,0.1'}) 0%,transparent 100%);">
						<div class="icon" style="position:absolute;left:0px;background-position:${-type.icon[0]*48}px ${-type.icon[1]*48}px;"></div>
						<div>
							<div class="name fancy" style="font-size:13px;">${type.nameD}</div>
							<div class="desc" style="padding:4px;">${type.desc(me).replaceAll('[t]',sayTime(me.tm*1000,-1))}</div>
							<div style="font-size:10px;opacity:0.75;">Time left: <b>${sayTime(me.t*1000+1000,-1)}</b></div>
						</div>
					</div>
					`;
				}
				return str;
			})+`
			</div>
		`,close:`Close`});
	});
	
	G.buffs=[];
	G.buff=function(type,o)
	{
		//example: new G.buff('frenzy',{t:10,pow:2}); - creates a frenzy lasting 10 seconds, with power x2
		var o=o||{};
		this.type=G.buffTypesBN[type];
		if (typeof o.t==='undefined') this.t=this.type.t; else this.t=o.t;
		if (typeof o.tm==='undefined') this.tm=this.t; else this.tm=o.tm;
		if (typeof o.pow==='undefined') this.pow=this.type.pow; else this.pow=o.pow;
		
		if (!o.loaded && this.type.init) this.type.init(this);
		
		var prev=G.hasBuff(type);
		if (prev)
		{
			var oldT=prev.t;
			var oldPow=prev.pow;
			G.killBuff(type);
			if (this.type.stackT==1) this.t+=oldT;
			else if (this.type.stackT==2) this.t=Math.max(oldT,this.t);
			if (this.type.stackPow==1) this.pow+=oldPow;
			else if (this.type.stackPow==2) this.pow=Math.max(oldPow,this.pow);
			this.tm=Math.max(this.t,this.tm);
		}
		
		this.effs=[];
		if (this.type.effsFunc) this.effs=this.type.effsFunc(this);
		G.buffs.push(this);
		this.type.buffs.push(this);
		G.refreshCps=1;
	}
	
	G.logicBuffs=function(delta)
	{
		for (var i=G.buffs.length-1;i>=0;i--)
		{
			let me=G.buffs[i];
			//me.type.logic(me);
			me.t-=delta/G.fps;
			if (me.t<=0)
			{
				//me.type.die(me);
				if (me.l) {let el=me.l;el.firstChild.innerHTML='';triggerAnim(el,'buffDisappear');setTimeout(function(){if (el){el.remove();}},200);}
				G.buffs.splice(i,1);
				me.type.buffs.splice(me.type.buffs.indexOf(me),1);
				G.refreshCps=1;
				//me.type.n--;
			}
		}
	}
	G.drawBuffs=function()
	{
		for (var i=0;i<G.buffs.length;i++)
		{
			var me=G.buffs[i];
			var type=me.type;
			if (!me.l)
			{
				let el=document.createElement('div');
				el.style.cssText=`background-position:${-type.icon[0]*48}px ${-type.icon[1]*48}px;`;
				el.className='buff icon buffAppear';
				el.innerHTML='<div class="buffText"></div>';
				me.l=el;
				setTimeout(function(){if (el){el.classList.remove('buffAppear');}},200);
				G.buffsL.insertBefore(me.l,G.buffsL.firstChild);
				//G.buffsL.prependChild(me.l);
			}
			me.l.firstChild.innerHTML=sayTime(me.t*1000+1000,0,1);
		}
	}
	G.resetBuffs=function()
	{
		for (var i=0;i<G.buffs.length;i++)
		{
			var me=G.buffs[i];
			if (me.l) me.l.remove();
		}
		G.buffs=[];
		for (var i=0;i<G.buffTypes.length;i++){G.buffTypes[i].buffs=[];}
		G.refreshCps=1;
	}
	
	G.hasBuff=function(name)
	{
		if (G.buffTypesBN[name].buffs.length>0) return G.buffTypesBN[name].buffs[0];
		else return false;
	}
	G.killBuff=function(name)
	{
		var buffs=G.buffTypesBN[name].buffs;
		for (var i=0;i<buffs.length;i++)
		{
			if (buffs[i].l) buffs[i].l.remove();
			G.buffs.splice(G.buffs.indexOf(buffs[i]),1);
		}
		G.buffTypesBN[name].buffs=[];
	}
	
//===========================================================================
//SHIMMERS
//===========================================================================
	G.shimmerTypes=[];
	G.shimmerTypesBN={};
	G.shimmerType=function(o)
	{
		this.reset=function(){};//reset this whole shimmer type (on game start and load)
		this.build=function(me){};//return an HTML element to append to the parent (may be called when a new shimmer appears on the tab, or when we go back to that tab)
		this.init=function(me){};//when spawning a new shimmer
		this.logic=function(me){};//called every frame by each shimmer
		this.draw=function(me){};//called every draw frame by each shimmer (only when visible)
		this.click=function(me){};//when clicked
		this.die=function(me){};//when despawned without being clicked
		this.spawnConditions=function(){return false};//return true when we can spawn a new one
		this.delayMod=function(n){return n;}//modify n, the delay to the next spawn
		this.durMod=function(me,n){return n;}//modify n, the lifespan of a shimmer
		//note: delays are in seconds
		this.delayMinBase=60*5;
		this.delayMaxBase=60*15;
		this.delayMin=1;
		this.delayMax=1;
		this.lastTime=Date.now();//last time we spawned this shimmer
		this.dur=13;
		this.n=0;//how many spawned currently
		this.i=0;//iterator for spawns
		this.spawned=0;
		transfer(this,o);
		G.shimmerTypes.push(this);
		G.shimmerTypesBN[this.name]=this;
	}
	
	G.chimeType=0;
	G.goldenCookieUpgrades=['Get lucky','Lucky day','Serendipity','Heavenly luck','Lasting fortune','Decisive fate','Lucky digit','Lucky number','Lucky payout','Golden goose egg'];
	G.addPostData(()=>{
		let arr=[];
		for (let i in G.goldenCookieUpgrades)
		{
			if (G.upgradesBN[G.goldenCookieUpgrades[i]]) arr.push(G.upgradesBN[G.goldenCookieUpgrades[i]]);
		}
		G.goldenCookieUpgrades=arr;
	});
	
	new G.shimmerType({
		name:'golden',
		reset:function()
		{
			this.chain=0;
			this.totalFromChain=0;
			this.last='';
			this.lastChainPos=0;
		},
		init:function(me)
		{
			me.s=(me.s||1)*(Math.random()*32+64);
			if (G.season=='easter' || G.season=='halloween' || G.season=='christmas' || G.season=='valentines')
			{
				me.r=(Math.random()*2-1)*8;
			}
			else if (G.season=='fools')
			{
				me.r=0;
				me.s=128;
			}
			else me.r=Math.random()*360;
			me.x=Math.floor(Math.random()*(G.w-me.s)+me.s/2);
			me.y=Math.floor(Math.random()*(G.h-me.s-128)+me.s/2+48);
			me.wrath=false;
			if (!me.noWrath && (me.forceWrath || (G.elderWrath==1 && Math.random()<1/3) || (G.elderWrath==2 && Math.random()<2/3) || (G.elderWrath==3)/* || (G.hasGod && G.hasGod('scorn'))*/))
			{
				me.wrath=true;
			}
			if (!me.force) me.force='';
			
			if (this.chain>0 && this.lastChainPos && me.force=='')
			{
				let x1=this.lastChainPos[0];
				let y1=this.lastChainPos[1];
				let x2=me.x;
				let y2=me.y;
				let a=Math.atan2(y2-y1,x2-x1);
				let d=Math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
				let n=Math.ceil(d/40);
				for (let i=0;i<=n;i++)
				{
					setTimeout(()=>{
						G.particleAt({
							x:x1+(x2-x1)*(i/n),
							y:y1+(y2-y1)*(i/n),
							s:0.5+Math.random()*0.3,
							sd:0.7+Math.random()*0.2,
							r:Math.random()*Math.PI*360,
							rd:Math.random()*10-5,
							xd:(Math.random()-0.5)*4,
							yd:(Math.random()-0.5)*4,
							grav:0,
							life:0.2,
							a:0.75,
							pic:'img/flare.png',
							cssText:'background:url(img/flare.png) 0px 0px;width:128px;height:128px;left:-64px;top:-64px;',
						});
					},(i/n)*250);
				}
			}
		},
		spawnConditions:function()
		{
			if (G.Has('Golden switch [off]')) return false;
			return true;
		},
		build:function(me)
		{
			var el=document.createElement('div');
			let pic='goldCookie.png';
			let extra=``;
			if (G.season=='easter')
			{
				pic='bunnies.png';
				extra=`background-size:400% 200%;background-position:${Math.floor(Math.random()*4)*me.s}px ${me.wrath?me.s:0}px;`;
			}
			else if (G.season=='halloween')
			{
				pic='familiars.png';
				extra=`background-size:400% 200%;background-position:${Math.floor(Math.random()*4)*me.s}px ${me.wrath?me.s:0}px;`;
			}
			else if (G.season=='valentines')
			{
				pic='hearts.png';
				extra=`background-size:800% 200%;background-position:${Math.floor(Math.random()*8)*me.s}px ${me.wrath?me.s:0}px;`;
			}
			else if (G.season=='fools')
			{
				pic='spamCookies.gif';
				extra=`background-size:400% 200%;background-position:${Math.floor(Math.random()*4)*me.s}px ${(me.wrath && !G.getSet('notScary'))?me.s:0}px;`;
				if (G.getSet('notScary')) extra+=`filter:sepia(90%) hue-rotate(-45deg) brightness(80%) saturate(400%);`;
			}
			else if (G.season=='christmas')
			{
				pic='goldCookieWreath.png';
				if (me.wrath) pic='wrathCookieWreath.png';
			}
			else if (me.wrath) pic='wrathCookie.png';
			el.style.cssText=`width:${me.s}px;height:${me.s}px;background-image:url('img/${pic}');${extra}`;
			return el;
		},
		draw:function(me)
		{
			var curve=1-Math.pow((me.t/(G.fps*me.dur))*2-1,4);
			me.l.style.opacity=curve;
			if (G.season=='fools') me.l.style.transform=`translate3d(${me.x-me.s/2}px,${me.y-me.s/2}px,0)`;
			else me.l.style.transform=`translate3d(${me.x-me.s/2}px,${me.y-me.s/2}px,0) scale(${me.s/96},${me.s/96}) rotate(${me.r+Math.sin(G.T*0.25+me.id)*8}deg)`;
		},
		click:function(me)
		{
			//select an effect
			var list=[];
			if (me.wrath) list.push('clot','multiply cookies','ruin cookies');
			else list.push('frenzy','multiply cookies');
			if (me.wrath && G.hasGod && G.hasGod('scorn')) list.push('clot','ruin cookies','clot','ruin cookies');
			if (me.wrath && Math.random()<0.3) list.push('blood frenzy','chain cookie','cookie storm');
			else if (Math.random()<0.03 && G.cookiesEarned>=100000) list.push('chain cookie','cookie storm');
			if (Math.random()<0.05 && G.season=='fools') list.push('everything must go');
			if (Math.random()<0.1 && (Math.random()<0.05 || !G.hasBuff('dragonflight'))) list.push('click frenzy');
			if (me.wrath && Math.random()<0.1) list.push('cursed finger');
			
			if (G.buildingsN>=10 && Math.random()<0.25) list.push('building special');
			
			//if (Game.canLumps() && Math.random()<0.0005) list.push('free sugar lump');
			
			if ((!me.wrath && Math.random()<0.15) || Math.random()<0.05)
			{
				if (Math.random()<G.auraMult('Reaper of Fields')) list.push('dragon harvest');
				if (Math.random()<G.auraMult('Dragonflight')) list.push('dragonflight');
			}
			
			if (this.last!='' && Math.random()<0.8 && list.indexOf(this.last)!=-1) list.splice(list.indexOf(this.last),1);//80% chance to force a different one
			if (G.Has('Golden switch [off]') && list.indexOf('chain cookie')!=-1) list.splice(list.indexOf('chain cookie'),1);//no chains with golden switch on
			if (Math.random()<0.0001) list.push('blab');
			var choice=choose(list);
			
			if (this.chain>0 || me.force=='chain cookie') this.lastChainPos=[me.x,me.y];
			if (this.chain>0) choice='chain cookie';
			if (me.force!='') {this.chain=0;choice=me.force;me.force='';}
			if (choice!='chain cookie') this.chain=0;
			
			this.last=choice;
			
			var powerClick=false;
			//if (!this.chain && !me.force && me.spawnLead && G.powerClicksOn && G.powerClicks>=1)
			if (G.powerClicksOn && G.powerClicks>=1)
			{
				G.spendPowerClick();
				powerClick=true;
				PlaySound('snd/powerShimmer.mp3',0.4);
				PlaySound('snd/powerClick'+choose([1,2,3])+'b.mp3',0.7-Math.random()*0.3);
			}
			
			if (choice!='')
			{
				//create buff for effect
				//buff duration multiplier
				var effectDurMod=1;
				if (me.wrath) effectDurMod=(effectDurMod+G.pool['gcWrathEffectsLifeA'])*G.pool['gcWrathEffectsLifeM'];
				else effectDurMod=(effectDurMod+G.pool['gcEffectsLifeA'])*G.pool['gcEffectsLifeM'];
				
				//effect multiplier (from lucky etc)
				var mult=1;
				if (me.wrath) mult=(mult+G.pool['gcWrathEffectsMultA'])*G.pool['gcWrathEffectsMultM'];
				else mult=(mult+G.pool['gcEffectsMultA'])*G.pool['gcEffectsMultM'];
				
				if (powerClick)
				{
					effectDurMod*=1.2;
					mult*=1.2;
				}
				
				var popup='';
				var buff=0;
				
				if (choice=='building special')
				{
					var time=Math.ceil(30*effectDurMod);
					var list=[];
					for (var i=0;i<G.buildings.length;i++)
					{
						if (G.buildings[i].amount>=10) list.push(G.buildings[i]);
					}
					if (list.length==0) {choice='frenzy';}//default to frenzy if no proper building
					else
					{
						var obj=choose(list);
						var pow=obj.amount/10+1;
						if (me.wrath && Math.random()<0.3)
						{
							buff=new G.buff('buildingDebuff'+obj.id,{t:time,pow:pow});
						}
						else
						{
							buff=new G.buff('buildingBuff'+obj.id,{t:time,pow:pow});
						}
					}
				}
				
				/*if (choice=='free sugar lump')
				{
					Game.gainLumps(1);
					popup='Sweet!<div style="font-size:65%;">Found 1 sugar lump!</div>';
				}
				else */if (choice=='frenzy')
				{
					buff=new G.buff('frenzy',{t:Math.ceil(77*effectDurMod),pow:7});
				}
				else if (choice=='dragon harvest')
				{
					buff=new G.buff('dragonHarvest',{t:Math.ceil(60*effectDurMod),pow:15});
				}
				else if (choice=='everything must go')
				{
					buff=new G.buff('sales',{t:Math.ceil(8*effectDurMod),pow:0.95});
				}
				else if (choice=='multiply cookies')
				{
					var moni=mult*Math.min(G.cookies*0.15,G.cookiesPs*60*15)+13;//add 15% to cookies owned (+13), or 15 minutes of cookie production - whichever is lowest
					G.earn(moni);
					popup='Lucky!|+'+B(moni)+' cookies!';
				}
				else if (choice=='ruin cookies')
				{
					var moni=Math.min(G.cookies*0.05,G.cookiesPs*60*10)+13;//lose 5% of cookies owned (-13), or 10 minutes of cookie production - whichever is lowest
					moni=Math.min(G.cookies,moni);
					G.spend(moni);
					popup='Ruin!|Lost '+B(moni)+' cookies!';
				}
				else if (choice=='blood frenzy')
				{
					buff=new G.buff('elderFrenzy',{t:Math.ceil(6*effectDurMod),pow:666});
				}
				else if (choice=='clot')
				{
					buff=new G.buff('clot',{t:Math.ceil(66*effectDurMod),pow:0.5});
				}
				else if (choice=='cursed finger')
				{
					buff=new G.buff('cursedFinger',{t:Math.ceil(10*effectDurMod),pow:G.cookiesPs*Math.ceil(10*effectDurMod)});
				}
				else if (choice=='click frenzy')
				{
					buff=new G.buff('clickFrenzy',{t:Math.ceil(13*effectDurMod),pow:777});
				}
				else if (choice=='dragonflight')
				{
					buff=new G.buff('dragonflight',{t:Math.ceil(10*effectDurMod),pow:1111});
					if (Math.random()<0.8) G.killBuff('clickFrenzy');
				}
				else if (choice=='chain cookie')
				{
					if (this.chain==0) this.totalFromChain=0;
					this.chain++;
					var digit=me.wrath?6:7;
					if (this.chain==1) this.chain+=Math.max(0,Math.ceil(Math.log(G.cookies)/Math.LN10)-10);
					
					var maxPayout=Math.min(G.cookiesPs*60*60*6,G.cookies*0.5)*mult;
					var moni=Math.max(digit,Math.min(Math.floor(1/9*Math.pow(10,this.chain)*digit*mult),maxPayout));
					var nextMoni=Math.max(digit,Math.min(Math.floor(1/9*Math.pow(10,this.chain+1)*digit*mult),maxPayout));
					this.totalFromChain+=moni;
					var moniStr=B(moni);
					
					//break the chain if we're above 5 digits AND it's more than 50% of our bank, it grants more than 6 hours of our CpS, or just a 1% chance each digit (update: removed digit limit)
					if (Math.random()<0.01 || nextMoni>=maxPayout)
					{
						this.chain=0;
						popup='Cookie chain over!|+'+moniStr+' cookies!<br>You made '+B(this.totalFromChain)+' cookies.';
						
						for (let i=0;i<=10;i++)
						{
							var a=(i/10)*Math.PI*2;
							G.particleAt({
								x:me.x+Math.sin(a)*me.s*0.4,
								y:me.y+Math.cos(a)*me.s*0.4,
								s:0.5+Math.random()*0.3,
								sd:0.7+Math.random()*0.2,
								r:Math.random()*Math.PI*360,
								rd:Math.random()*10-5,
								xd:Math.sin(a)*6,
								yd:Math.cos(a)*6,
								grav:0,
								life:0.6,
								a:0.75,
								pic:'img/flare.png',
								cssText:'background:url(img/flare.png) 0px 0px;width:128px;height:128px;left:-64px;top:-64px;',
							});
						}
					}
					else
					{
						popup='Cookie chain|+'+moniStr+' cookies!';
					}
					G.earn(moni);
				}
				else if (choice=='cookie storm')
				{
					buff=new G.buff('cookieStorm',{t:Math.ceil(7*effectDurMod),pow:7});
				}
				else if (choice=='cookie storm drop')
				{
					var moni=Math.max(mult*(G.cookiesPs*60*Math.floor(Math.random()*7+1)),Math.floor(Math.random()*7+1));//either 1-7 cookies or 1-7 minutes of cookie production, whichever is highest
					G.earn(moni);
					//popup='|<div style="margin:8px 16px;">+'+B(moni)+' cookies!</div>';
					
					G.particleAt({
						x:me.x,
						y:me.y,
						xd:Math.random()*8-4,
						yd:-Math.random()*3-5,
						str:'+'+B(moni),
					});
				}
				else if (choice=='blab')//sorry (it's really rare)
				{
					var str=choose([
					'Cookie crumbliness x3 for 60 seconds!',
					'Chocolatiness x7 for 77 seconds!',
					'Dough elasticity halved for 66 seconds!',
					'Golden cookie shininess doubled for 3 seconds!',
					'World economy halved for 30 seconds!',
					'Grandma kisses 23% stingier for 45 seconds!',
					'Thanks for clicking!',
					'Fooled you! This one was just a test.',
					'Golden cookies clicked +1!',
					'Your click has been registered. Thank you for your cooperation.',
					'Thanks! That hit the spot!',
					'Thank you. A team has been dispatched.',
					'They know.',
					'Oops. This was just a chocolate cookie with shiny aluminium foil.',
					'Eschaton immanentized!',
					'Oh, that tickled!',
					'Again.',
					'You\'ve made a grave mistake.',
					'Chocolate chips reshuffled!',
					'Randomized chance card outcome!',
					'Mouse acceleration +0.03%!',
					'Ascension bonuses x5,000 for 0.1 seconds!',
					'Gained 1 extra!',
					'Sorry, better luck next time!',
					'I felt that.',
					'Nice try, but no.',
					'Wait, sorry, I wasn\'t ready yet.',
					'Yippee!',
					'Bones removed.',
					'Organs added.',
					'Did you just click that?',
					'Huh? Oh, there was nothing there.',
					'You saw nothing.',
					'It seems you hallucinated that golden cookie.',
					'This golden cookie was a complete fabrication.',
					'In theory there\'s no wrong way to click a golden cookie, but you just did that, somehow.',
					'All cookies multiplied by 999!<br>All cookies divided by 999!',
					'Why?'
					]);
					popup=`|<div style="margin:8px 16px;">${str}</div>`;
				}
				
				if (popup || buff)
				{
					var title=0;
					var text=0;
					if (popup) {popup=popup.split('|');title=popup[0];text=popup[1];}
					if (buff) {title=buff.type.nameD;text=buff.type.desc(buff).replaceAll('[t]',sayTime(buff.tm*1000,-1));}
					if (!title) title=0;
					if (!text) text=0;
					G.toast(title,text,buff?buff.type.icon:0,true);
				}
				
				G.DropEgg(0.9);
				
				if (me.spawnLead)
				{
					G.gcClicks++;
					G.gcClicksTotal++;
					if (me.t/G.fps>=me.dur-1) G.win('Early bird');
					if (me.t/G.fps<=1) G.win('Fading luck');
					if (me.wrath) G.win('Wrath cookie');
				}
				
				if (choice=='cookie storm drop')
				{
					/*if (Game.prefs.cookiesound) PlaySound('snd/click'+Math.floor(Math.random()*7+1)+'.mp3',0.75);
					else */PlaySound('snd/clickb'+Math.floor(Math.random()*7+1)+'.mp3',0.75);
				}
				else PlaySound('snd/shimmerClick.mp3');
				G.sparkleAt(me.x,me.y);
			}
		},
		die:function(me)
		{
			if (this.chain>0 && this.totalFromChain>0)
			{
				G.toast('Cookie chain broken','You made '+B(this.totalFromChain)+' cookies.',0,true);
				this.chain=0;this.totalFromChain=0;
			}
			if (me.spawnLead) G.gcMissed++;
		},
		delayMinBase:60*5,
		delayMaxBase:60*15,
		delayMod:function(m)
		{
			//else m=(m+G.pool['gcFreqA'])*G.pool['gcFreqM'];
			m-=G.pool['gcFreqA'];
			m/=G.pool['gcFreqM'];
			if (this.chain>0) m=0;//0.05*60;
			//if (G.Has('Gold hoard')) m=0.01;
			return m;
		},
		dur:13,
		durMod:function(me,dur)
		{
			if (me.wrath) dur=(dur+G.pool['gcWrathLifeA'])*G.pool['gcWrathLifeM'];
			else dur=(dur+G.pool['gcLifeA'])*G.pool['gcLifeM'];
			dur*=Math.pow(0.95,this.n-1);//5% shorter for every other golden cookie on the screen
			if (this.chain>0) dur=Math.max(2,10/this.chain);
			return dur;
		},
	});
	
	new G.shimmerType({
		name:'reindeer',
		reset:function()
		{
		},
		init:function(me)
		{
			me.s=(me.s||1);
			me.r=0;
			me.x=0;
			me.y=0;
		},
		spawnConditions:function()
		{
			return G.season=='christmas';
		},
		build:function(me)
		{
			var el=document.createElement('div');
			el.style.cssText=`width:${me.s*167}px;height:${me.s*212}px;background-image:url('img/frostedReindeer.png');`;
			return el;
		},
		draw:function(me)
		{
			var r=1-me.t/(G.fps*me.dur);
			me.l.style.opacity=1;
			me.x=(G.w+167)*r+Math.sin(G.T*0.1+me.id)*32-167/2;
			me.y=(G.h+212)*r-Math.abs(Math.cos(G.T*0.1+me.id)*16)-212/2;
			me.l.style.transform=`translate(${me.x-167/2}px,${me.y-212/2}px) rotate(${Math.sin(G.T*0.1+me.id+Math.PI*0.2)*16+8}deg) scale(0.6)`;
		},
		click:function(me)
		{
			var val=G.cookiesPs*60;
			val+=G.pool['reindeerEffectsMultA'];
			val*=G.pool['reindeerEffectsMultM'];
			
			var moni=Math.max(25,val);//1 minute of cookie production, or 25 cookies - whichever is highest
			G.earn(moni);
			let popup='+'+B(moni)+' cookies!';
			
			if (G.hasBuff('elderFrenzy')) G.win('Eldeer');
			
			if (popup)
			{
				var title=0;
				var text=0;
				if (popup) {popup=popup.split('|');title=popup[0];text=popup[1];}
				if (!title) title=0;
				if (!text) text=0;
				G.toast(title,text,0,true);
			}
			
			G.DropReindeer(0.8);
			
			if (me.spawnLead)
			{
				G.reindeerClicks++;
				G.reindeerClicksTotal++;
			}
			PlaySound('snd/jingleClick.mp3');
			G.sparkleOn(me.l);
		},
		die:function(me)
		{
			if (me.spawnLead) G.reindeerMissed++;
		},
		delayMinBase:60*3,
		delayMaxBase:60*6,
		delayMod:function(m)
		{
			m-=G.pool['reindeerFreqA'];
			m/=G.pool['reindeerFreqM'];
			return m;
		},
		dur:8,
		durMod:function(me,dur)
		{
			dur=(dur+G.pool['reindeerLifeA'])*G.pool['reindeerLifeM'];
			return dur;
		},
	});
	
	G.resetShimmers=function()
	{
		G.shimmers=[];
		for (var i=0;i<G.shimmerTypes.length;i++)
		{
			var me=G.shimmerTypes[i];
			me.i=0;
			me.n=0;
			me.spawned=0;
			me.lastTime=Date.now();
			me.reset();
		}
		G.refreshCps=1;
	}
	
	G.shimmers=[];
	G.shimmer=function(type,o)
	{
		if (G.explodeT>-1 || G.onAscend==1) return false;
		var me=this;
		me.spawnLead=false;//if true (ie. spawned naturally), qualifies for things like incrementing clicked/missed, resets spawn timer etc
		me.type=G.shimmerTypesBN[type];
		me.l=0;
		me.dur=me.type.durMod(me,me.type.dur);
		transfer(me,o||{});
		if (me.spawnLead) me.type.lastTime=Date.now();
		me.t=Math.ceil(G.fps*me.dur);
		me.id=me.type.i;
		me.type.i++;
		if (!me.noCount) me.type.n++;//noCount means this shimmer is not counted towards its spawn amount
		me.clicked=false;
		G.shimmers.push(me);
		
		G.pingScreen('cookie');
		
		me.type.init(me);
	}
	G.shimmer.prototype.click=function()
	{
		if (this.t<=0 || this.clicked) return false;
		this.type.click(this);
		this.clicked=true;
		this.t=0;
	}
	
	G.drawShimmers=function(parent)
	{
		for (var i=0;i<G.shimmers.length;i++)
		{
			let me=G.shimmers[i];
			let type=me.type;
			if (!me.l)
			{
				me.l=type.build(me);
				me.l.className='shimmer';
				G.ondown(me.l,function(){me.click();});
				parent.appendChild(me.l);
			}
			type.draw(me);
		}
	}
	G.logicShimmers=function(delta)
	{
		for (var i=G.shimmers.length-1;i>=0;i--)
		{
			var me=G.shimmers[i];
			if (me.t>0)
			{
				me.type.logic(me);
				me.t-=delta;
			}
			if (me.t<=0)
			{
				if (!me.clicked) me.type.die(me);
				if (me.l) me.l.remove();
				G.shimmers.splice(i,1);
				if (!me.noCount) me.type.n=Math.max(0,me.type.n-1);
				if (me.spawnLead)
				{
					//if this was the spawn lead for this shimmer type, set the shimmer type's "spawned" to 0 and restart its spawn timer
					me.type.lastTime=Date.now();
					me.type.spawned=0;
				}
				if (G.shimmers.length==0) G.unpingScreen('cookie');
			}
		}
		
		//cookie storm!
		if (Math.random()<0.5 && G.hasBuff('cookieStorm'))
		{
			var newShimmer=new G.shimmer('golden',{force:'cookie storm drop',noCount:true,dur:Math.ceil(Math.random()*4+1),s:Math.random()*0.5+0.5});
		}
		
		//spawn shimmers
		for (var i=0;i<G.shimmerTypes.length;i++)
		{
			var me=G.shimmerTypes[i];
			if (!me.spawned && me.spawnConditions())//no shimmer spawned for this type? check the timer and try to spawn one
			{
				var min=me.delayMod(me.delayMinBase);
				var max=me.delayMod(me.delayMaxBase);
				if (Math.random()<Math.pow(Math.max(0,((Date.now()-me.lastTime)/1000-min)/(max-min)),5))
				{
					new G.shimmer(me.name,{spawnLead:true});
					if (G.Has('Distilled essence of redoubled luck') && Math.random()<0.01) new G.shimmer(me.name);
					me.spawned=1;
				}
			}
		}
	}
	G.shimmersOnResize=function()
	{
		//make sure shimmers don't get stuck under the ad
		for (let i in G.shimmers)
		{
			let me=G.shimmers[i];
			//let oldx=me.x;
			//let oldy=me.y;
			me.x=Math.max(Math.min(me.x,G.w-me.s/2),me.s/2);
			me.y=Math.max(Math.min(me.y,G.h-me.s-128+48),me.s/2+48);
			//if (me.l && (me.x!=oldx || me.y!=oldy)) me.l.style.backgroundColor='red';
		} 
	}
	G.unbuildShimmers=function()
	{
		for (var i=0;i<G.shimmers.length;i++){G.shimmers[i].l=0;}
	}

//===========================================================================
//TABS AND SCREENS
//===========================================================================
	G.tabsL=document.createElement('div');
	G.tabsL.id='tabs';
	G.tabsL.style.background='none';//todo: remove
	G.tabsL.classList.add('bottomShelf');
	G.l.appendChild(G.tabsL);
	
	G.screensL=document.createElement('div');
	G.screensL.id='screens';
	G.l.appendChild(G.screensL);
	
	G.backL=document.createElement('div');
	G.backL.id='back';
	G.back2L=document.createElement('div');
	G.back2L.id='back2';
	G.l.appendChild(G.backL);
	G.l.appendChild(G.back2L);
	G.backShadeL=document.createElement('div');
	G.backShadeL.id='backShade';
	G.l.appendChild(G.backShadeL);
	G.rainL=document.createElement('canvas');
	G.rainL.id='rain';
	G.rainCtx=G.rainL.getContext("2d");
	G.rainScale=2;
	G.l.appendChild(G.rainL);
	G.milkL=document.createElement('div');
	G.milkL.id='milk';
	G.lastMilkPic=0;
	G.l.appendChild(G.milkL);
	
	G.bgType=0;
	G.AllBGs=[
		{pic:'bgBlue',name:'Automatic',icon:[0,7]},
		{pic:'bgBlue',name:'Blue',icon:[21,21]},
		{pic:'bgRed',name:'Red',icon:[22,21]},
		{pic:'bgWhite',name:'White',icon:[23,21]},
		{pic:'bgBlack',name:'Black',icon:[24,21]},
		{pic:'bgGold',name:'Gold',icon:[25,21]},
		{pic:'grandmas1',name:'Grandmas',icon:[26,21]},
		{pic:'grandmas2',name:'Displeased grandmas',icon:[27,21]},
		{pic:'grandmas3',name:'Angered grandmas',icon:[28,21]},
		{pic:'bgMoney',name:'Money',icon:[29,21]},
		{pic:'bgPurple',name:'Purple',icon:[21,22],order:1.1},
		{pic:'bgPink',name:'Pink',icon:[24,22],order:2.1},
		{pic:'bgMint',name:'Mint',icon:[22,22],order:2.2},
		{pic:'bgSilver',name:'Silver',icon:[25,22],order:4.9},
		{pic:'bgBW',name:'Black & White',icon:[23,22],order:4.1},
		{pic:'bgSpectrum',name:'Spectrum',icon:[28,22],order:4.2},
		{pic:'bgCandy',name:'Candy',icon:[26,22]},
		{pic:'bgYellowBlue',name:'Biscuit store',icon:[27,22]},
		{pic:'bgChoco',name:'Chocolate',icon:[30,21]},
		{pic:'bgChocoDark',name:'Dark Chocolate',icon:[31,21]},
		{pic:'bgPaint',name:'Painter',icon:[24,34]},
		{pic:'bgSnowy',name:'Snow',icon:[30,22]},
		{pic:'bgSky',name:'Sky',icon:[29,22]},
		{pic:'bgStars',name:'Night',icon:[31,22]},
		{pic:'bgFoil',name:'Foil',icon:[25,34]},
	];
	G.BGsByChoice={};
	for (var i=0;i<G.AllBGs.length;i++)
	{
		G.BGsByChoice[i]=G.AllBGs[i];
	}
	
	G.updateBG=function(reset)
	{
		if (reset)
		{
			G.elderWrathD=G.elderWrath;
		}
		else
		{
			if (G.bgType!=0) return false;
			if (G.elderWrathD<G.elderWrath) G.elderWrathD+=0.02;
			else if (G.elderWrathD>G.elderWrath) G.elderWrathD-=0.02;
			else return false;
			G.elderWrathD=Math.round(G.elderWrathD*1000)/1000;
		}
		
		var bgPic='bgBlue';
			if (G.bgType!=0) bgPic=G.BGsByChoice[G.bgType].pic;
		var pic1=bgPic;
		var pic2=bgPic;
		var ratio=0;
		
		if (G.bgType==0)
		{
			if (G.season=='fools') {pic1='bgMoney';pic2=pic1;ratio=0;}
			
			if (G.elderWrathD>0 && !G.getSet('notScary'))
			{
				if (G.elderWrathD<1)
				{
					pic2='grandmas1';
					ratio=G.elderWrathD%1;
				}
				else if (G.elderWrathD<2)
				{
					pic1='grandmas1';
					pic2='grandmas2';
					ratio=G.elderWrathD%1;
				}
				else if (G.elderWrathD<3)
				{
					pic1='grandmas2';
					pic2='grandmas3';
					ratio=G.elderWrathD%1;
				}
				else if (G.elderWrathD>=3)
				{
					pic1='grandmas3';
					pic2='grandmas3';
					ratio=0;
				}
			}
		}
		G.backL.style.backgroundImage='url(img/'+pic1+'.jpg)';
		if (ratio==0) G.back2L.style.display='none';
		else
		{
			G.back2L.style.display='block';
			G.back2L.style.backgroundImage='url(img/'+pic2+'.jpg)';
			G.back2L.style.opacity=ratio;
		}
	};
	
	G.screens=[
//===========================================================================
//COOKIE SCREEN
//===========================================================================
		{name:'cookie',nameD:'Cookie',icon:0,init:function(){
			G.cookieClickSound=Math.floor(Math.random()*7)+1;
			//G.lastCookieClickSoundTime=0;
			G.playCookieClickSound=function()
			{
				//if (Date.now()-G.lastCookieClickSoundTime<50) return false;
				PlaySound('snd/clickb'+(G.cookieClickSound)+'.mp3',0.75);
				G.cookieClickSound+=Math.floor(Math.random()*4)+1;
				if (G.cookieClickSound>7) G.cookieClickSound-=7;
				//G.lastCookieClickSoundTime=Date.now();
			}
		},build:function(el){
			
			var me=document.createElement('div');
			me.id='cookieContainer';
			me.style.cssText=`position:absolute;left:0px;top:0px;right:0px;bottom:0px;transition:transform 0.1s;`;
			el.appendChild(me);
			G.cookieContainerL=me;
			
			var me=document.createElement('div');
			me.id='quickButtons';
			el.appendChild(me);
			G.quickButtonsL=me;
			
			let setQuickButton=(n,id,icon,onclick,onupdate)=>{
				if (!G.quickButtonsL) return false;
				let el=document.createElement('div');
				el.id=id;
				el.className=`prestigeIcon prestigeStatus2 quickButton`;
				el.style.right=(G.quickButtonsPos[n][0]+5)+'px';
				el.style.bottom=(G.quickButtonsPos[n][1]+5)+'px';
				
				let img=document.createElement('div');img.className=`upgradeIcon icon`;img.style.backgroundPosition=`${-icon[0]*48}px ${-icon[1]*48}px`;el.appendChild(img);
				let txt=document.createElement('div');txt.className=`fancy chromaFocus`;el.appendChild(txt);txt.innerHTML=``;txt.style.cssText=`pointer-events:none;position:absolute;left:50%;margin-left:-75px;text-align:center;width:150px;font-size:15px;z-index:10;`;
				
				let me={
					l:el,
					icon:icon,
					img:img,
					txt:txt,
					onclick:onclick||0,
					onupdate:onupdate||0,
					status:0,
					setText:(val)=>{
						me.txt.innerHTML=typeof val==='undefined'?'':val;
					},
					setIcon:(icon)=>{
						if (me.icon[0]==icon[0] && me.icon[1]==icon[1]) return;
						me.img.style.backgroundPosition=`${-icon[0]*48}px ${-icon[1]*48}px`;
						me.icon=icon;
					},
					setStatus:(val)=>{
						if (val==0) {me.l.classList.remove('prestigeStatus1','prestigeStatus3');me.l.classList.add('prestigeStatus2');}
						else if (val==1) {me.l.classList.remove('prestigeStatus2','prestigeStatus3');me.l.classList.add('prestigeStatus1');}
						else if (val==2) {me.l.classList.remove('prestigeStatus2','prestigeStatus1');me.l.classList.add('prestigeStatus3');}
					},
				};
				
				if (onclick)
				{
					G.onclick(me.l,e=>{
						let out=onclick(me);
						if (out)
						{
							PlaySound('snd/smallTick.mp3',1);
							triggerAnim(me.l,'plopHalf');
						};
					});
				}
				if (onupdate)
				{
					let func=(me)=>{
						if (!me.l || !G.quickButtonsL) return;
						onupdate(me);
						setTimeout(()=>{func(me);},1000/30);
					};
					func(me);
				}
				
				G.quickButtonsL.appendChild(el);
				return me;
			};
			
			if (G.Has)
			{
				for (let i=0;i<G.quickButtons.length;i++)
				{
					let button=G.quickButtons[i];
					if (button!='none' && G.quickButtonOptions[button] && G.quickButtonOptions[button].cond())
					{
						if (button=='powerClicks')
						{
							setQuickButton(i,'quickButtonPowerClicks',[30,36],(me)=>{
								if (G.powerClicks<1) return false;
								G.powerClicksOn=!G.powerClicksOn;
								if (G.powerClicksOn)
								{
									PlaySound('snd/roarOn2.mp3',0.4);
									G.lastPowerClickUse=Date.now();
								}
								return true;
							},
							(me)=>{
								let n=Math.floor(G.powerClicks);
								if (G.powerClicksOn && (Date.now()-G.lastPowerClickUse)>=1000*60*5) G.powerClicksOn=false;//auto-disable 5 mins after the last power click
								if (G.powerClicks>=1 && !G.powerClicksOn) {me.setStatus(1);}
								else if (G.powerClicks<1 || !G.powerClicksOn) {me.setStatus(0);G.powerClicksOn=false;}
								else if (G.powerClicksOn) me.setStatus(2);
								
								if (n<1) me.setText();
								else me.setText(`${n}/${G.getPowerClickCapacity()}<br>power click${n==1?'':'s'}`);
							});
						}
						else if (button=='goldenSwitch')
						{
							setQuickButton(i,'quickButtonGoldenSwitch',[20,10],(me)=>{
								if (G.isUnlocked('Golden switch [on]')) G.upgradesBN['Golden switch [on]'].showInfo();
								else G.upgradesBN['Golden switch [off]'].showInfo();
								return true;
							},
							(me)=>{
								if (G.isUnlocked('Golden switch [on]'))
								{
									me.setIcon([21,10]);
									//me.setText(`On`);
									me.setStatus(2);
								}
								else
								{
									me.setIcon([20,10]);
									//me.setText(`Off`);
									me.setStatus(1);
								}
							});
						}
						else if (button=='dragonAura1')
						{
							setQuickButton(i,'quickButtonDragonAura1',[0,7],(me)=>{
								G.SelectDragonAura(0);
								return true;
							},
							(me)=>{
								me.setIcon(G.dragonAuras[G.dragonAura].pic);
								//me.setText(`Aura`);
								me.setStatus(1);
							});
						}
						else if (button=='dragonAura2')
						{
							setQuickButton(i,'quickButtonDragonAura2',[0,7],(me)=>{
								G.SelectDragonAura(1);
								return true;
							},
							(me)=>{
								me.setIcon(G.dragonAuras[G.dragonAura2].pic);
								//me.setText(`Aura 2`);
								me.setStatus(1);
							});
						}
						else if (button=='seasonSwitcher')
						{
							setQuickButton(i,'quickButtonSeasonSwitcher',[16,6],(me)=>{
								G.seasonSwitcherPopup();
								return true;
							},
							(me)=>{
								//me.setText();
								me.setStatus(1);
							});
						}
					}
				}
			}
			
			
			if (G.getSet('fancy'))
			{
				var me=document.createElement('div');
				me.id='bigCookieShadow';
				G.cookieContainerL.appendChild(me);
				G.bigCookieShadowL=me;
				
				var me=document.createElement('div');
				me.id='bigCookieShine';
				G.cookieContainerL.appendChild(me);
				G.bigCookieShineL=me;
			}
			
			if (G.getSet('cursors') && G.explodeT==-1)
			{
				var cursorCanvas=document.createElement('canvas');
				cursorCanvas.id='cursorCanvas';
				cursorCanvas.width=480;
				cursorCanvas.height=480;
				let ctx=cursorCanvas.getContext("2d");
				
				let drawCursors=function()
				{
					if (!G.onScreen==G.screens['cookie']) return false;
					let pic=Pic('img/cursor.png');
					if (!G.buildings || G.buildings.length==0 || pic.alt=='blank')
					{
						setTimeout(drawCursors,100);
						return false;
					}
					ctx.setTransform(1,0,0,1,0,0);
					ctx.translate(240,240);
					ctx.globalAlpha=1;
					var cursorAmount=Math.min(350,(G.buildings && G.buildings.length)>0?G.buildings[0].amount:0);
					for (var i=0;i<cursorAmount;i++)
					{
						var n=Math.floor(i/50);
						ctx.globalAlpha=1-n/8;
						var x=0;
						var y=(140+n*16)-24;
						var rot=7.2;
						if (i%50==0) rot+=7.2/2;
						ctx.rotate((rot/360)*Math.PI*2);
						//ctx.drawImage(pic,0,0,32,32,x,y,32,32);
						ctx.drawImage(pic,x,y,32,32);
					}
					ctx.setTransform(1,0,0,1,0,0);
					ctx.globalAlpha=1;
				}
				drawCursors();
				cursorCanvas.style.animationDelay='-'+Math.floor(Math.random()*180)+'s';
				G.cookieContainerL.appendChild(cursorCanvas);
			}
			
			
			var me=document.createElement('div');
			me.id='bigCookie';
			G.cookieContainerL.appendChild(me);
			
			G.ondown(me,function(e){
				G.bigCookieState=1;
				G.bigCookieClicked=true;
				let mult=1;
				if (G.powerClicksOn && G.powerClicks>=1) mult*=G.usePowerClick();
				let toEarn=G.cookiesPc*mult;
				G.earn(toEarn);
				G.cookiesHandmade+=toEarn;
				G.cookieClicks++;
				G.cookiesD=G.cookies;
				if (e.touches.length>0)
				{
					var n=toEarn;
					var x=Rescale(e.touches[0].pageX);
					var y=Rescale(e.touches[0].pageY);
					/*for (var i=0;i<Math.ceil(Math.min(n,3));i++)
					{
						G.cookiePop(x+(Math.random()-0.5)*32*i,y+(Math.random()-0.5)*32*i);
					}*/
					G.cookiePop(x+(Math.random()-0.5)*8,y+(Math.random()-0.5)*8);
					G.particleAt({
						x:x,
						y:y,
						xd:Math.random()*8-4,
						yd:-Math.random()*3-5,
						str:'+'+B(n,1)+(mult>1?' <span style="font-size:75%;animation:chromaFocus 0.5s ease-out infinite;">(x'+(Math.round(mult*1000)/1000)+')</span>':''),
					});
				}
				G.playCookieClickSound();
				G.canPan=0;
			});
			G.onup(me,function(){
				G.bigCookieState=0;
				G.playCookieClickSound();
			});
			G.bigCookieL=me;
			
			G.bigCookieState=0;//0 = normal, 1 = clicked (small), 2 = released/hovered (big)
			G.bigCookieClicked=false;
			G.bigCookieSize=0;
			G.bigCookieSizeD=0;
			G.bigCookieSizeT=1;
			
			if (G.getSet('fancy') && G.getSet('cookiewobble'))
			{
				var box=RescaleBox(G.bigCookieL.getBoundingClientRect());
				G.bigCookieSize=0.95;
				G.onX=box.left;
				G.onY=box.top+box.height/2;
			}
			
			this.freeCookie={
				//lets us drag the cookie around after we pull it enough
				on:false,startPull:0,lastOn:0,lastReleased:0,
				x:0,xd:0,xprev:0,y:0,yd:0,yprev:0,s:1,pull:0,d:0,a:0,
				start:function()
				{
					//PlaySound('snd/pop'+Math.floor(Math.random()*3+1)+'.mp3',0.75);
					PlaySound('snd/click'+Math.floor(Math.random()*7+1)+'.mp3',0.75);
					G.milkL.style.zIndex='10';
					G.bigCookieSizeD=-0.5;
					this.on=true;
					this.lastOn=Date.now();
					this.lastReleased=0;
					G.cookieContainerL.classList.add('free');
				},
				logic:function(d)
				{
					if (G.getSet('dislodge')==0) return;
					if (this.on && G.bigCookieState!=1 && this.lastReleased==0)//released
					{
						this.xd=(this.x-this.xprev)*1;
						this.yd=(this.y-this.yprev)*1;
						this.lastReleased=Date.now();
						G.bigCookieSizeD=0.05;
					}
					if (G.bigCookieState==1 && !this.startPull) this.startPull=Date.now();
					if (G.bigCookieState==1 || this.lastReleased>0)//if clicked or is returning to original position
					{
						if (this.x!=0 && this.y!=0)
						{
							this.xprev=this.x;
							this.yprev=this.y;
						}
						
						if (this.lastReleased==0)
						{
							this.x=G.onX/G.w-0.5;
							this.y=G.onY/G.h-0.5;
							this.s=0.5;
							if (this.on)
							{
								var w=(120*this.s)/G.w;
								var h=(120*this.s)/G.h;
								this.x=Math.max(-0.5+w,Math.min(0.5-w,this.x));
								this.y=Math.max(-0.5+h,Math.min(0.5-h,this.y));
							}
						}
						else//if returning to original position
						{
							var r=Math.pow((Date.now()-this.lastReleased)/(1000*0.75),4);
							this.x+=this.xd;
							this.y+=this.yd;
							this.xd*=0.95;
							this.yd*=0.95;
							this.yd+=0.01*d;
							this.x=(0)*r+this.x*(1-r);
							this.y=(0)*r+this.y*(1-r);
							this.s=0.5+0.5*r;
							var w=(120*this.s)/G.w;
							var h=(120*this.s)/G.h;
							var xdprev=this.xd,ydprev=this.yd;
							if (this.x<-0.5+w) this.xd=Math.abs(this.xd);
							else if (this.x>0.5-w) this.xd=-Math.abs(this.xd);
							if (this.y<-0.5+h) this.yd=Math.abs(this.yd);
							else if (this.y>0.5-h) this.yd=-Math.abs(this.yd);
							if (this.xd!=xdprev || this.yd!=ydprev)
							{
								G.bigCookieSizeD+=0.1;
								PlaySound('snd/clickb'+Math.floor(Math.random()*7+1)+'.mp3',0.3);
								//G.cookiePop((this.x+0.5)*G.w+(Math.random()-0.5)*32,(this.y+0.5)*G.h+(Math.random()-0.5)*32);
							}
							if (r>=1) this.lastReleased=0;
						}
						
						if (this.on && this.lastReleased==0)//achiev
						{
							var milkH=G.h-(240+35)*G.milkLevel;
							var cookieBottom=(this.y+0.5)*G.h+30;//30=240/2/2/2
							var cookieBottomPrev=(this.yprev+0.5)*G.h+30;
							if (Date.now()-this.lastOn>1000*0.5)
							{
								if ((cookieBottom-milkH)>=15 && (cookieBottomPrev-milkH)<15)
								{
									PlaySound('snd/clickb'+Math.floor(Math.random()*7+1)+'.mp3',0.3);
									G.bigCookieSizeD+=0.1;
									if (!G.HasAchiev('Cookie-dunker'))
									{
										PlaySound('snd/shimmerClick.mp3',1);
										G.win('Cookie-dunker');
									}
								}
								else if ((cookieBottom-milkH)<=15 && (cookieBottomPrev-milkH)>15)
								{
									PlaySound('snd/clickb'+Math.floor(Math.random()*7+1)+'.mp3',0.3);
									G.bigCookieSizeD-=0.1;
								}
							}
						}
						
						if (!this.on)//pull to start!
						{
							this.lastReleased=0;
							let dx=this.x-this.xprev;
							let dy=this.y-this.yprev;
							this.pull*=0.95;
							let vel=Math.min(0.2,Math.sqrt(dx*dx+dy*dy));
							
							var x1=0,y1=0,x2=this.x,y2=this.y;
							this.a=-Math.atan2(y1-y2,x1-x2)-Math.PI/2;//pull angle;
							this.d=Math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))*(1-G.bigCookieSize)*5;//pull distance
							
							if (this.d>0.09) this.pull+=vel;
							if (this.pull>=1 && Date.now()-this.startPull>=600) this.start();
						}
						if (G.bigCookieState==1 && this.lastReleased>0)//catch in midair?
						{
							this.start();
						}
					}
					if (G.bigCookieState!=1 && this.lastReleased==0)
					{
						if (this.on)
						{
							G.milkL.style.zIndex='';
							G.cookieContainerL.classList.remove('free');
						}
						this.on=false;
						this.x=0;this.xd=0;this.xprev=0;
						this.y=0;this.yd=0;this.yprev=0;
						this.s=1;
						this.pull=0;
						this.d=0;this.a=0;
						this.lastReleased=0;
						this.startPull=0;
					}
				},
				draw:function()
				{
					if (this.on)
					{
						G.cookieContainerL.style.transform=`translate(${this.x*100}%,${this.y*100}%) scale(${this.s})`;
					}
					else
					{
						G.cookieContainerL.style.transform=`translate(${0}px,${0}px) scale(${1})`;
						//var r=0;
						//if (this.d>=0.06) r=Math.min(1,(this.d-0.06)/0.03);
						
						//return {shake:Math.pow(r,5)+this.pull*2};
					}
					//return {shake:0};
					return;
				},
			};
			
			G.buffsL.classList.remove('wide');
			G.buffsL.classList.add('tall');
			
		},clean:function(el){
			if (G.getSet('fancy') && G.getSet('cookiewobble') && G.bigCookieL)
			{
				var box=RescaleBox(G.bigCookieL.getBoundingClientRect());
				G.bigCookieSize=0.95;
				G.onX=box.right;
				G.onY=box.top+box.height/2;
			}
			this.freeCookie=0;
			G.unbuildShimmers();
			G.undrawWrinklers();
			G.quickButtonsL=0;
			G.buffsL.classList.remove('tall');
			G.buffsL.classList.add('wide');
		},draw:function(el){
			let freeCookieData=this.freeCookie.draw();
			var box=RescaleBox(G.bigCookieL.getBoundingClientRect());
			var x1=box.left+box.width/2;//G.fromX;
			var y1=box.top+box.height/2;//G.fromY;
			if (G.getSet('fancy') && G.getSet('cookiewobble'))
			{
				var x2=G.onX;
				var y2=G.onY;
				var a=0;
				var d=0;
				var s=1;
				
				var x=0,y=0;
				/*var x=freeCookieData.shake*(Math.random()-0.5)*5;
				var y=freeCookieData.shake*(Math.random()-0.5)*5;
				x2+=freeCookieData.shake*(Math.random()-0.5)*50;
				y2+=freeCookieData.shake*(Math.random()-0.5)*50;*/
				
				if (G.intro>-1)
				{
					var t=G.intro/(G.fps*2);
					d=(1-t)*100;
					a=Math.pow(t,1.5)*50;
					s=1+Math.abs(Math.cos(Math.pow(t,1.5)*20))*(1-Math.pow(t,0.25));
					G.bigCookieShineL.style.opacity=t;
				}
				else
				{
					a=-Math.atan2(y1-y2,x1-x2)-Math.PI/2;
					d=Math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))*(1-G.bigCookieSize)*15;
				}
				
				G.bigCookieL.style.transform=`
					scale(`+(G.bigCookieSize*s)+`) 
					perspective(300px) 
					translate3d(`+(Math.sin(a)*d/4+x)+`px,`+(Math.cos(a)*d/4+y)+`px,0) 
					rotate3d(`+(-Math.cos(-a))+`,`+(-Math.sin(-a))+`,0,`+Math.min(d/4,20)+`deg) 
				`;
				//rotate(`+(G.onAngle/Math.PI*180)+`deg)
				if (G.bigCookieShadowL)
				{
					var shadowDampen=0.75;
					G.bigCookieShadowL.style.transform=`
						scale(`+(G.bigCookieSize*s+0.15)+`) 
						perspective(300px) 
						translate3d(`+(Math.sin(a)*d/4*shadowDampen+1+x)+`px,`+(Math.cos(a)*d/4*shadowDampen+3+y)+`px,-10px) 
						rotate3d(`+(-Math.cos(-a)*shadowDampen)+`,`+(-Math.sin(-a)*shadowDampen)+`,0,`+Math.min(d/4,20)+`deg) 
					`;
				}
				
				G.backL.style.transform='scale('+Math.max(0.8,(G.bigCookieSize-1)*0.5+1)+')';
				G.back2L.style.transform='scale('+Math.max(0.8,(G.bigCookieSize-1)*0.5+1)+')';
				//G.rainL.style.transform='scale('+2*Math.max(1,1-G.bigCookieSize+1)+')';
				G.rainL.style.transform='scale('+(G.rainScale*Math.max(0.8,(1-G.bigCookieSize)*0.5+1+0.1))+')';//the 0.1 is to have some extra margin during tap bounces
			}
			G.drawShimmers(el);
			G.drawWrinklers(G.cookieContainerL,G.w/2,G.h/2);
		},logic:function(el,d){
			this.freeCookie.logic(d);
			
			if (G.getSet('fancy') && G.getSet('cookiewobble'))
			{
				//big cookie wobble
				//as of 2023 i no longer have any idea how this works
				if (G.bigCookieState==1 || G.bigCookieClicked) G.bigCookieSizeT=0.95;
				else if (G.bigCookieState==2) G.bigCookieSizeT=1.1;
				else G.bigCookieSizeT=1;
				G.bigCookieSizeD+=(G.bigCookieSizeT-G.bigCookieSize)*0.75;
				G.bigCookieSizeD*=0.75;
				if (G.bigCookieState!=1 && Math.abs(G.bigCookieSizeD)<0.0001) {G.bigCookieSizeD=0;G.bigCookieSize=1;}
				G.bigCookieSize+=G.bigCookieSizeD;
				G.bigCookieSize=Math.max(0.1,G.bigCookieSize);
			}
			G.bigCookieClicked=false;
			
			if (G.explodeT>-1)
			{
				if (G.explodeT==G.fps*2) PlaySound('snd/thud.mp3');
				G.explodeT++;
				if (G.explodeT>=G.fps*3)//end
				{
					G.explodeT=-1;
					G.l.classList.remove('onExplode');
					G.showAscend(1);
				}
			}
			
			if (G.intro>-1)
			{
				G.intro++;//note: not +=d, as d is abnormally high in the first few frames of loading the app and would just skip the anim
				if (G.intro>=G.fps*2)//end
				{
					if (G.getSet('fancy')) G.bigCookieShineL.style.opacity=1;
					G.intro=-1;
				}
			}
		}},
//===========================================================================
//STORE SCREEN
//===========================================================================
		{name:'store',nameD:'Store',icon:2,init:function(){
			
			G.storeSections=[
				{name:'buildings',nameD:'Buildings',icon:5,content:function(el){
					//buildings tab
					
					let showInfo=function(me)
					{
						G.popup({text:`
							<h3>Building info</h3>
							<div class="framed nameBox">
								<div class="doilyTrim"></div>
								<div class="buildingIcon switchLeftIn" style="transform:scale(1);background-position:${me.getPic()};"></div>
								<div class="fancy switchRightIn" style="position:absolute;left:64px;right:0px;top:16px;text-align:center;margin:8px;${me.style?me.style:''}">${me.getName()}</div>
								<div class="switchTopIn" style="font-size:10px;font-weight:bold;position:absolute;left:64px;right:0px;bottom:16px;text-align:center;">Owned: ${B(me.amount)}${me.free>0?(' (Free: '+B(me.free)+')'):''}</div>
							</div>
							<line></line>
							`+G.selfUpdatingText(e=>{return `
								<div>
									<p>&bull; each ${me.single} produces <b>${B(me.storedCps,1)}</b> cookie${B(me.storedCps,1)=='1'?'':'s'} per second</p>
									<p>&bull; <b>${B(me.amount)} ${me.amount==1?me.single:me.plural}</b> producing <b>${B(me.storedCps*me.amount)}</b> cookie${B(me.storedCps*me.amount)=='1'?'':'s'} per second</p>
									<p>&bull; <b>${B(me.cookiesMade)}</b> cookie${B(me.cookiesMade)=='1'?'':'s'} ${me.actionName} so far</p>
								</div>
							`;})+`
							<line></line>
							<p class="switchTopIn" style="text-align:right;color:rgba(255,255,255,0.65);"><q>${me.getDesc()}</q></p>
						`,close:`Close`});
					}
					var str='';
					if (G.getSet('debug'))
					{
						str+=`<div class="bar building" style="background:rgba(0,0,0,0.5);text-align:center;">`+
						G.button({text:'-50 of all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.buildings.length;i++){G.buildings[i].forceSell(50);}}})+
						G.button({text:'-1 of all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.buildings.length;i++){G.buildings[i].forceSell(1);}}})+
						G.button({text:'+1 of all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.buildings.length;i++){G.buildings[i].forceBuy(1);}}})+
						G.button({text:'+50 of all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.buildings.length;i++){G.buildings[i].forceBuy(50);}}})+
						`</div>`;
					}
					for (var i in G.buildings)
					{
						let me=G.buildings[i];
						
						str+=`
						<div class="bar building" id="building-${me.id}">
							<div class="buildingIcon" style="background-position:${me.getPic()};"></div>
							<div class="name"`+((me.style && G.season!='fools')?' style="'+me.style+'"':'')+`>${me.getName()}</div>
							<div class="desc">${me.getDesc()}</div>
							
							`+G.button({text:'info',classes:'infoButton',onclick:function(e,el){triggerAnim(el,'plop');showInfo(me);}})+`
							`+G.button({text:'<div class="buyButtonText"></div><div class="cost"></div>',classes:'buyButton',onclick:function(e,el){me.buy();triggerAnim(el,'plop');}})+`
						</div>`;
					}
					
					
					let setBulkBuy=function(n,mode,self)
					{
						var changed=false;
						if (G.bulkBuy!=n || G.bulkMode!=mode) changed=true;
						G.bulkBuy=n;
						G.bulkMode=mode;
						
						var buttons=['Buy','1','10','Sell','100','Max'];
						for (var i in buttons)
						{
							var me=buttons[i];
							var el=l('bulkBuy'+me);
							if (
								(G.bulkMode==1 && me=='Buy') || 
								(G.bulkMode==-1 && me=='Sell') || 
								(G.bulkBuy==1 && me=='1') || 
								(G.bulkBuy==10 && me=='10') || 
								(G.bulkBuy==100 && me=='100') || 
								(G.bulkBuy==10000 && me=='Max')
							)
							{
								el.classList.add('on');
							}
							else el.classList.remove('on');
						}
						
						if (self)
						{
							triggerAnim(self,'plop');
							PlaySound('snd/clickb2.mp3',0.75);
						}
						
						if (changed)
						{
							for (var i=0;i<G.buildings.length;i++)
							{
								var me=G.buildings[i];
								me.redraw();
							}
						}
					}
					
					el.innerHTML=`<div class="scrollableList storeList">${str}</div>`;
					
					
					l('storeOptions').innerHTML=`
						<div class="buttonBox">`+
							G.button({text:'Buying',classes:'bumpButton',id:'bulkBuyBuy',style:'width:96px;',onclick:function(e,el){setBulkBuy(G.bulkBuy,1,el);}})+
							G.button({text:'1',classes:'bumpButton',id:'bulkBuy1',style:'width:32px;',onclick:function(e,el){setBulkBuy(1,G.bulkMode,el);}})+
							G.button({text:'10',classes:'bumpButton',id:'bulkBuy10',style:'width:32px;',onclick:function(e,el){setBulkBuy(10,G.bulkMode,el);}})+`<br>`+
							G.button({text:'Selling',classes:'bumpButton',id:'bulkBuySell',style:'width:96px;',onclick:function(e,el){setBulkBuy(G.bulkBuy,-1,el);}})+
							G.button({text:'100',classes:'bumpButton',id:'bulkBuy100',style:'width:32px;',onclick:function(e,el){setBulkBuy(100,G.bulkMode,el);}})+
							G.button({text:'Max',classes:'bumpButton',id:'bulkBuyMax',style:'width:32px;',onclick:function(e,el){setBulkBuy(10000,G.bulkMode,el);}})+`<br>`+
						`</div>`;
					
					setBulkBuy(G.bulkBuy,G.bulkMode);
						
					for (var i in G.buildings)
					{
						let me=G.buildings[i];
						me.l=l('building-'+me.id);
						me.nameL=me.l.getElementsByClassName('name')[0];
						me.descL=me.l.getElementsByClassName('desc')[0];
						me.iconL=me.l.getElementsByClassName('buildingIcon')[0];
						me.buyButtonL=me.l.getElementsByClassName('buyButton')[0];
						me.buyTextL=me.buyButtonL.getElementsByClassName('buyButtonText')[0];
						me.costL=me.buyButtonL.getElementsByClassName('cost')[0];
						
						me.redraw();
					}
					
				},clean:function(el){
					for (var i in G.buildings)
					{
						let me=G.buildings[i];
						me.l=null;
						me.nameL=null;
						me.descL=null;
						me.iconL=null;
						me.buyButtonL=null;
						me.buyTextL=null;
						me.costL=null;
					}
				}},
				{name:'upgrades',nameD:'Upgrades',icon:6,content:function(el){
					
					//upgrades tab
					
					G.doUnlocks();
					
					let itemNone={text:`<div class="bar upgrade" style="background:rgba(0,0,0,0.5);text-align:center;"><div style="margin:13px;font-size:11px;font-weight:bold;">(No upgrades available!<br>Check back later!)</div></div>`};
					let itemDebug={textF:function(){return `<div class="bar upgrade" style="background:rgba(0,0,0,0.5);text-align:center;">`+
						G.button({text:'Unlock all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.upgrades.length;i++){if (!G.upgrades[i].unimplemented && G.upgrades[i].pool!='toggle') G.upgrades[i].unlock();}}})+
						G.button({text:'Earn all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.upgrades.length;i++){if (!G.upgrades[i].unimplemented && G.upgrades[i].pool!='toggle') G.upgrades[i].forceBuy();}}})+
						G.button({text:'Lose all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.upgrades.length;i++){G.upgrades[i].lose();}}})+
						`</div>`
					}};
					
					el.innerHTML=G.scrollableList({id:'storeUpgrades',classes:'storeList',itemH:49,dataFunc:function(){
						var list=[];
						for (var i=0;i<G.upgrades.length;i++)
						{
							let me=G.upgrades[i];
							if (me.unlocked && !me.owned && me.pool!='science' && me.pool!='prestige' && me.pool!='toggle') list.push(me);
						}
						list.sort((a,b)=>a.getCost()-b.getCost());
						
						if (list.length==0) list.push(itemNone);
						if (G.getSet('debug')) list.unshift(itemDebug);
						return list;
						
					},renderFunc:function(me,updateList){
						if (me.text) return me.text;
						if (me.textF) return me.textF();
						
						var toUnping=false;
						//note: didn't work as intended
						/*if (me.ping==1)
						{
							me.ping=Date.now();
							toUnping=true;
							var allUnpinged=true;
							for (var i=0;i<G.upgrades.length;i++)
							{
								let it=G.upgrades[i];
								if (it.unlocked && !it.owned && it.ping) allUnpinged=false;
							}
							if (allUnpinged) G.unpingScreen('store');
						}
						else if (me.ping>1)
						{
							toUnping=true;
							if (Date.now()-me.ping>=2000) me.ping=0;
						}*/
						
						let icon=me.iconFunc?me.iconFunc():me.icon;
						return `
						<div class="bar upgrade${toUnping?' unping':''}" id="upgrade-${me.id}">
							<div class="upgradeIcon icon" style="background-position:${-icon[0]*48}px ${-icon[1]*48}px;"></div>
							<div class="name"`+(me.style?' style="'+me.style+'"':'')+`>${me.name}</div>
							<div class="desc">${me.descFunc?me.descFunc():me.desc}</div>
							
							`+G.button({text:'info',classes:'infoButton',onclick:function(e,el){triggerAnim(el,'plop');me.showInfo();}})+`
							`+G.button({text:'<div class="buyButtonText">Buy</div><div class="cost"></div>',classes:'buyButton',onclick:function(e,el){
								if (me.buy())
								{
									PlaySound('snd/buy'+choose([1,2,3,4])+'.mp3',0.65);
									//var box=RescaleBox(el.getBoundingClientRect());G.cookiePop(box.left+box.width/2,box.top+box.height/2);
									updateList();
								}
							}})+`
						</div>`;
					},redrawFunc:function(me,el){
						if (me.text || me.textF) return false;
						me.redraw(el);
					}});
					
					
					l('storeOptions').innerHTML=`
						<div class="buttonBox">`+
							G.button({text:'Buy all',classes:'bumpButton',id:'upgradesBuyAll',style:'width:96px;',onclick:function(e,el){
								triggerAnim(el,'plop');
								PlaySound('snd/clickb2.mp3',0.75);
								
								var list=[];
								for (var i=0;i<G.upgrades.length;i++)
								{
									let me=G.upgrades[i];
									if (me.pool!='toggle' && me.pool!='science' && me.pool!='prestige' && me.unlocked && !me.owned) list.push(me);
								}
								list.sort((a,b)=>a.getCost()-b.getCost());
								
								var bought=0;
								for (var i=0;i<list.length;i++)
								{
									if (!list[i].buy()) break;
									else bought++;
								}
								if (bought>0)
								{
									PlaySound('snd/buy'+choose([1,2,3,4])+'.mp3',0.65);
									G.toast(0,`Bought ${B(bought)} upgrade${bought==1?'':'s'}.`,0,true);
								}
							}})+
						`</div>`;
					
				}},
			];
			
			G.setStoreSection=function(it)
			{
				if (it) G.onStoreSection=it;
				for (var i=0;i<G.storeSections.length;i++)
				{
					var me=G.storeSections[i];
					if (me==it) {me.content(me.l);me.l.classList.remove('off');me.l.classList.add('on');me.tabL.classList.remove('off');me.tabL.classList.add('on');G.addCallbacks();}
					else {me.l.classList.add('off');me.l.classList.remove('on');me.tabL.classList.add('off');me.tabL.classList.remove('on');;if (me.clean){me.clean();me.l.innerHTML=''}}
				}
			}
			
			G.onStoreSection=G.storeSections[0];
			
		},build:function(el){
			
			var storeSectionsL=document.createElement('div');
			storeSectionsL.id='storeSections';
			
			var storeTabsL=document.createElement('div');
			storeTabsL.id='storeTabs';
			storeTabsL.className='buttonBox onWood';
			
			var storeOptionsL=document.createElement('div');
			storeOptionsL.id='storeOptions';
			storeOptionsL.className='storeOptions onWood';
			
			var storeBGL=document.createElement('div');
			storeBGL.id='storeBG';
			storeBGL.className='woodBG';
			storeBGL.style.cssText='pointer-events:none;z-index:-1;width:100%;height:64px;position:absolute;left:0px;right:0px;bottom:0px;';
			
			el.insertAdjacentHTML('afterbegin','<div class="sectionTrimOverlay noLeft"></div>');
			el.appendChild(storeSectionsL);
			el.appendChild(storeTabsL);
			el.appendChild(storeOptionsL);
			el.appendChild(storeBGL);
			
			for (var i in G.storeSections)
			{
				let me=G.storeSections[i];
				
				me.tabL=document.createElement('div');
				me.tabL.className='button bumpButton storeTab off';
				me.tabL.innerHTML=`
					<div class="tabIcon" style="background-position-x:-${me.icon*128}px;"></div>
					<div class="tabName">${me.nameD}</div>
				`;
				G.onclick(me.tabL,function(){
					if (!G.panning)
					{
						triggerAnim(me.tabL,'plop');
						PlaySound('snd/clickb2.mp3',0.75);
						G.setStoreSection(me);
					}
				});
				storeTabsL.appendChild(me.tabL);
				
				me.l=document.createElement('div');
				me.l.className='section storeSection off shadeUpInner';
				storeSectionsL.appendChild(me.l);
			}
			
			G.addCallbacks();
			
			G.setStoreSection(G.onStoreSection);
			
		},clean:function(el){
			G.setStoreSection(null);
			for (var i in G.storeSections)
			{
				let me=G.storeSections[i];
				me.l=null;
				me.tabL=null;
			}
		}},
//===========================================================================
//SPECIAL SCREEN
//===========================================================================
		{name:'special',nameD:'Special',icon:1,init:function(){
			
	//===========================================================================
	//ASCENDING
	//===========================================================================
			G.HCfactor=3;
			G.HowMuchPrestige=function(cookies)//how much prestige [cookies] should land you
			{
				return Math.pow(cookies/1000000000000,1/G.HCfactor);
			}
			G.HowManyCookiesReset=function(chips)//how many cookies [chips] are worth
			{
				//this must be the inverse of the above function (ie. if cookies=chips^2, chips=cookies^(1/2) )
				return Math.pow(chips,G.HCfactor)*1000000000000;
			}
			G.gainedPrestige=0;
			G.EarnHeavenlyChips=function(cookiesForfeited)
			{
				//recalculate prestige and chips owned
				var prestige=Math.floor(G.HowMuchPrestige(G.cookiesReset+cookiesForfeited));
				if (prestige>G.prestige)//did we gain prestige levels?
				{
					var prestigeDifference=prestige-G.prestige;
					G.gainedPrestige=prestigeDifference;
					G.heavenlyChips+=prestigeDifference;
					G.prestige=prestige;
					G.toast(`You gain <b>${B(prestigeDifference)}</b> prestige level${prestigeDifference==1?'':'s'}!`,`You forfeit your ${B(cookiesForfeited)} cookie${cookiesForfeited==1?'':'s'}.`,[19,7]);
				}
			}
			
			G.GetHeavenlyMultiplier=function()
			{
				var heavenlyMult=0;
				if (G.Has('Heavenly chip secret')) heavenlyMult+=0.05;
				if (G.Has('Heavenly cookie stand')) heavenlyMult+=0.20;
				if (G.Has('Heavenly bakery')) heavenlyMult+=0.25;
				if (G.Has('Heavenly confectionery')) heavenlyMult+=0.25;
				if (G.Has('Heavenly key')) heavenlyMult+=0.25;
				heavenlyMult*=1+G.auraMult('Dragon God')*0.05;
				//todo
				/*
				if (G.Has('Lucky digit')) heavenlyMult*=1.01;
				if (G.Has('Lucky number')) heavenlyMult*=1.01;
				if (G.Has('Lucky payout')) heavenlyMult*=1.01;*/
				/*if (G.hasGod)
				{
					var godLvl=G.hasGod('creation');
					if (godLvl==1) heavenlyMult*=0.7;
					else if (godLvl==2) heavenlyMult*=0.8;
					else if (godLvl==3) heavenlyMult*=0.9;
				}*/
				return heavenlyMult;
			}
			
			//G.prestige=Math.floor(G.HowMuchPrestige(G.cookiesReset));
			
			G.onAscend=0;
			G.showAscend=function(mode)
			{
				//mode: 0=none, 1=reset and ascend, 2=viewing only
				G.onAscend=mode;
				
				if (G.onAscend==1)
				{
					G.resetBuffs();
					G.resetShimmers();
					
					G.resetPools();
					
					G.EarnHeavenlyChips(G.cookiesEarned);
					G.cookiesReset+=G.cookiesEarned;
					
					PlaySound('snd/cymbalRev.mp3',0.5);
					PlaySound('snd/choir.mp3');
				}
				
				//build the ascension screen
				var ascendStr='';
				
				let pz=0;
				
				let originUpgrade=0;
				
				/*ascendStr+=`<div style="background:url(img/heavenRing1.jpg);width:128px;height:128px;transform:scale(2);position:absolute;left:-64px;top:-64px;z-index:-1;mix-blend-mode:screen;"></div>
				`;*/
				
				for (var i=0;i<G.upgradePools['prestige'].length;i++)
				{
					let me=G.upgradePools['prestige'][i];
					let icon=me.iconFunc?me.iconFunc():me.icon;
					var pos=G.HeavenlyUpgradePositions[me.id];
					ascendStr+=`<div id="prestigeUpgrade-${me.id}" class="upgradeIcon icon prestigeIcon" style="background-position:${-icon[0]*48}px ${-icon[1]*48}px;position:absolute;left:${pos[0]+4}px;top:${pos[1]+4}px;"></div>`;
					
					var ghosted=false;
					var parents=G.HeavenlyUpgradeParents[me.id];
					if (parents.length==0) originUpgrade=me;
					for (var ii in parents)//create pulsing links
					{
						if (parents[ii]!=-1)
						{
							var pos2=G.HeavenlyUpgradePositions[parents[ii]];
							var origX=0;
							var origY=0;
							var targX=pos[0]+28;
							var targY=pos[1]+28;
							if (parents[ii]!=-1) {origX=pos2[0]+28;origY=pos2[1]+28;}
							var rot=-(Math.atan((targY-origY)/(origX-targX))/Math.PI)*180;
							if (targX<=origX) rot+=180;
							var dist=Math.floor(Math.sqrt((targX-origX)*(targX-origX)+(targY-origY)*(targY-origY)));
							ascendStr+='<div class="parentLink" id="heavenlyLink-'+me.id+'-'+ii+'" style="width:'+dist+'px;transform:rotate('+rot+'deg);left:'+(origX)+'px;top:'+(origY)+'px;"></div>';
						}
					}
				}
				
				let heavenlyBounds={left:0,right:0,top:0,bottom:0};
				
				let updateHeavenlyTree=function()
				{
					var HeavenlyUpgradeStatus={};
					
					//first pass: determine which are bought and which we can buy
					for (var i=0;i<G.upgradePools['prestige'].length;i++)
					{
						let me=G.upgradePools['prestige'][i];
						
						var parents=G.HeavenlyUpgradeParents[me.id];
						
						HeavenlyUpgradeStatus[me.id]=0;
						if (me.owned) HeavenlyUpgradeStatus[me.id]=3;
						else
						{
							var canBuy=true;
							for (var ii in parents)
							{
								if (!G.upgradesBID[parents[ii]].owned) {canBuy=false;break;}
							}
							if (canBuy) HeavenlyUpgradeStatus[me.id]=2;
						}
					}
					
					//second pass: determine which are connected to those we can buy
					//apply styles and recalculate bounds
					
					var prevBoundsW=heavenlyBounds.right-heavenlyBounds.left;
					var prevBoundsH=heavenlyBounds.bottom-heavenlyBounds.top;
					heavenlyBounds.left=0;
					heavenlyBounds.top=0;
					heavenlyBounds.right=0;
					heavenlyBounds.bottom=0;
					
					for (var i=0;i<G.upgradePools['prestige'].length;i++)
					{
						let me=G.upgradePools['prestige'][i];
						let el=l(`prestigeUpgrade-${me.id}`);
						var pos=G.HeavenlyUpgradePositions[me.id];
						var parents=G.HeavenlyUpgradeParents[me.id];
						if (HeavenlyUpgradeStatus[me.id]==0)
						{
							for (var ii in parents)
							{
								if (HeavenlyUpgradeStatus[parents[ii]]>1) {HeavenlyUpgradeStatus[me.id]=1;break;}
							}
						}
						
						var status=HeavenlyUpgradeStatus[me.id];
						el.classList.remove('prestigeStatus0','prestigeStatus1','prestigeStatus2','prestigeStatus3');
						el.classList.add('prestigeStatus'+status);
						for (var ii in parents)
						{
							if (parents[ii]!=-1)
							{
								var elLink=l(`heavenlyLink-${me.id}-${ii}`);
								elLink.classList.remove('prestigeStatus0','prestigeStatus1','prestigeStatus2','prestigeStatus3');
								elLink.classList.add('prestigeStatus'+status);
							}
						}
						
						if (status>1)
						{
							if (pos[0]<heavenlyBounds.left) heavenlyBounds.left=pos[0];
							if (pos[0]>heavenlyBounds.right) heavenlyBounds.right=pos[0];
							if (pos[1]<heavenlyBounds.top) heavenlyBounds.top=pos[1];
							if (pos[1]>heavenlyBounds.bottom) heavenlyBounds.bottom=pos[1];
						}
					}
					heavenlyBounds.left-=128;
					heavenlyBounds.top-=128;
					heavenlyBounds.right+=128+64;
					heavenlyBounds.bottom+=128+64;
					
					l('ascendContent').style.width=`${heavenlyBounds.right-heavenlyBounds.left}px`;
					l('ascendContent').style.height=`${heavenlyBounds.bottom-heavenlyBounds.top}px`;
					l('ascendAnchor').style.cssText=`left:${-heavenlyBounds.left}px;top:${-heavenlyBounds.top}px;`;
					//l('ascendAnchor').style.cssText=`left:0px;top:0px;`;
					
					if (false)//pz)
					{
						//should supposedly let us preserve the pinchzoom offset/scale but doesn't seem to work
						//possibly because zoomFactor will stay the same even tho effective scale does not
						var zoomFactor=pz.zoomFactor;
						var offsetX=pz.offset.x;
						var offsetY=pz.offset.y;
						pz.update();
						pz.zoomFactor=zoomFactor;
						pz.offset.x=offsetX-((heavenlyBounds.right-heavenlyBounds.left)-prevBoundsW);
						pz.offset.y=offsetY-((heavenlyBounds.bottom-heavenlyBounds.top)-prevBoundsH);
					}
				}
				
				
				//show the ascension screen
				G.popup({replace:true,text:`
					<div class="debugOnly" style="z-index:10000;position:absolute;left:0px;top:0px;">`+G.button({text:'all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);
						for (var i=0;i<G.upgradePools['prestige'].length;i++)
						{
							let me=G.upgradePools['prestige'][i];
							if (!me.owned)
							{
								me.owned=1;
								var cost=me.getCost();
								G.heavenlyChips-=cost;
								G.heavenlyChipsSpent+=cost;
							}
						}
						updateHeavenlyTree();
					}})+``
					+G.button({text:'reset',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);
						for (var i=0;i<G.upgradePools['prestige'].length;i++)
						{
							let me=G.upgradePools['prestige'][i];
							if (me.owned)
							{
								me.owned=0;
								var cost=me.getCost();
								G.heavenlyChips+=cost;
								G.heavenlyChipsSpent-=cost;
							}
						}
						updateHeavenlyTree();
					}})+`</div>
					<div id="ascendFloat" style="overflow:hidden;left:0%;right:0%;top:0%;bottom:0%;"><div id="ascendContent"><div id="ascendAnchor">${ascendStr}</div></div></div>
					<div class="fancy" style="position:absolute;left:0px;bottom:0px;pointer-events:none;text-align:center;padding:8px;opacity:0.5;font-size:10px;z-index:1000;">pinch & drag<br>to zoom</div>
					<div style="z-index:1000;position:absolute;top:16px;left:0px;right:0px;background:rgba(0,0,0,0.5);padding:4px 16px;pointer-events:none;font-size:12px;text-align:center;">${G.iconSmall(19,7)}`+G.selfUpdatingText(e=>'<b style="vertical-align:middle;">'+B(Math.round(G.heavenlyChipsD),0,1)+'</b> <span style="font-size:80%;vertical-align:middle;">unspent heavenly chip'+(Math.round(G.heavenlyChipsD)==1?'':'s')+'</span>')+`</div>
					`+
					G.button({text:G.onAscend==2?`<div class="fancy" style="font-size:12px;">Return</div>`:`<div class="fancy" style="font-size:12px;">Reincarnate</div><div style="position:absolute;left:0px;right:0px;bottom:4px;padding:2px;font-size:8px;opacity:0.75;">(when you're ready)</div>`,style:'margin:6px;z-index:1000;display:block;position:absolute;bottom:0px;right:0px;padding:'+(G.onAscend==2?'8px 18px 8px 18px':'8px 18px 16px 18px')+';',classes:'magicButton bumpButton',onclick:function(){
						if (G.onAscend==2)
						{
							PlaySound('snd/smallTick.mp3',1);
							G.closeAllPopups();
							G.onAscend=0;
						}
						else
						{
							G.popup({text:`
								<h3>Reincarnate</h3>
								<div style="text-align:center;">Are you ready to return to the mortal world?</div>
								<line></line>
								`+G.button({text:`Reincarnate!`,classes:'bumpButton fullButton squish',style:';margin:8px 0px;background:url(img/perfectCookie.png),url(img/bgBlue.jpg);background-position:center;background-size:50%,auto;background-repeat:no-repeat,repeat;box-shadow:0px 0px 0px 1px rgba(0,0,0,0.5),0px 0px 4px 2px #36f,0px 0px 0px 1px rgba(255,255,255,0.2) inset,0 0px 4px rgba(0,0,0,0.5) inset;border-radius:8px;',onclick:function(){
									PlaySound('snd/smallTick.mp3',1);
									G.closeAllPopups();
									G.Reset(false);
									G.onAscend=0;
									G.setScreen('cookie',true);
									PlaySound('snd/pop'+Math.floor(Math.random()*3+1)+'.mp3',0.75);
									G.toast(`Hello, cookies!`,``,[10,0]);
								}})+`
							`,close:`Cancel`});
						}
					}})
					+`
				`,classes:'fullPopup ascendPopup',contentStyle:'bottom:0px;',introAnim:'ascendPopupAnimIn',close:'[NONE]'});
				
				//on upgrade click
				for (var i=0;i<G.upgradePools['prestige'].length;i++)
				{
					let me=G.upgradePools['prestige'][i];
					let el=l(`prestigeUpgrade-${me.id}`);
					G.onclick(el,function(){
						triggerAnim(el,'plop');
						
						var onBuy=function()
						{
							if (me.buy())
							{
								updateHeavenlyTree();
								setTimeout(()=>{if (el) G.sparkleOn(el);},50);
								var children=G.HeavenlyUpgradeChildren[me.id];
								for (var i=0;i<children.length;i++)
								{
									let child=children[i];
									setTimeout(()=>{
										var parents=G.HeavenlyUpgradeParents[child];
										for (var ii in parents)
										{
											if (!G.upgradesBID[parents[ii]].owned) {return false;}
										}
										var childEl=l(`prestigeUpgrade-${child}`);
										if (!childEl) return false;
										triggerAnim(childEl,'plop');
										PlaySound('snd/clickb'+Math.floor(Math.random()*7+1)+'.mp3',0.3);
									},500+150*i);
								}
							}
							else
							{
								PlaySound('snd/clickb2.mp3',0.75);
							}
						};
						me.showInfo({onBuy:onBuy});
					});
				}
				
				updateHeavenlyTree();
				
				//pinch and drag
				pz=new PinchZoom.default(l('ascendContent'),{animationDuration:50,minZoom:0.5,maxZoom:4});
				pz.zoomFactor=1;
				/*pz.initialOffset.x=-G.w/2;pz.initialOffset.y=-G.h/2;
				pz.offset.x=pz.initialOffset.x;pz.offset.y=pz.initialOffset.y;*/
				
			}
			G.explodeT=-1;//how far along in the explosion anim are we
			G.explodeThenAscend=function()
			{
				G.closeAllPopups();
				G.explodeT=0;
				G.l.classList.add('onExplode');
				G.resetShimmers();
				G.setScreen('cookie',true);
				if (G.cookieContainerL) G.cookieContainerL.classList.add('hidden');
				PlaySound('snd/charging.mp3');
			}
			
		
		},build:function(el){
			var str='';
			
			let prevChips=0;
			let prevChipsTime=0;
			
			//prestige
			var legacyStr=`<div id="legacySection" class="bumpy" style="position:relative;overflow:hidden;padding:0px;">
					
					<div class="sliverHeader">${G.iconSmall(19,7)}Legacy</div>
					
					<div style="pointer-events:none;margin-top:20px;padding-bottom:8px;">
						Prestige level: <b style="color:#90f;">`+G.selfUpdatingText(e=>{return B(G.prestige,0,2);})+`</b><span style="font-size:85%;"> at <b>`+G.selfUpdatingText(e=>{return B(G.GetHeavenlyMultiplier()*100,1);})+`%</b> of its potential</span><br>
						<span style="font-size:85%;">(CpS boost: <b>+`+G.selfUpdatingText(e=>{return B(G.prestige*G.GetHeavenlyMultiplier(),1);})+`%</b>)</span><br>
						`+G.selfUpdatingText(e=>{
							//written through the magic of "hope for the best" maths
							var chipsOwned=G.HowMuchPrestige(G.cookiesReset);
							var rawAscendNowToOwn=G.HowMuchPrestige(G.cookiesReset+G.cookiesEarned)||0;
							var ascendNowToOwn=Math.floor(rawAscendNowToOwn);
							var ascendNowToGet=ascendNowToOwn-Math.floor(chipsOwned);
							var nextChipAt=G.HowManyCookiesReset(Math.floor(chipsOwned+ascendNowToGet+1))-G.HowManyCookiesReset(Math.floor(chipsOwned+ascendNowToGet));
							var cookiesToNext=G.HowManyCookiesReset(ascendNowToOwn+1)-(G.cookiesEarned+G.cookiesReset);
							
							if (prevChipsTime!=0)
							{
								let elapsed=(Date.now()-prevChipsTime)/1000;
								let dif=(rawAscendNowToOwn-prevChips)/elapsed;
								if (dif>=1.5) return `Earning <b>${B(dif,1)}</b> levels per second`;
							}
							prevChips=rawAscendNowToOwn;
							prevChipsTime=Date.now();
							
							return `<b>${B(Math.max(cookiesToNext,0),0)}</b> more <span class="tinyCookie"></span>cookies needed for next level`;
						})+`<br>
					</div>
					
					<div style="position:relative;width:100%;height:48px;">
						`+G.button({text:`<div style="position:absolute;left:0px;top:0px;right:0px;bottom:0px;box-shadow:0px 0px 4px 2px #90f;border-radius:inherit;"></div><div class="fancy">Ascend</div><div style="position:absolute;left:0px;right:0px;top:18px;padding:4px;font-size:9px;color:rgba(255,255,255,0.75);">will grant you <b style="color:#cff;background:#90f;box-shadow:0px 0px 4px 1px #90f;padding:0px 2px;border-radius:2px;">`+G.selfUpdatingText(e=>{
							var chipsOwned=G.HowMuchPrestige(G.cookiesReset);
							var ascendNowToOwn=Math.floor(G.HowMuchPrestige(G.cookiesReset+G.cookiesEarned));
							var ascendNowToGet=ascendNowToOwn-Math.floor(chipsOwned);
							return ascendNowToGet>0?B(ascendNowToGet,0,2):`no`;
						})+`</b> prestige</div>`,classes:'bumpButton',style:'background:url(img/starbg.jpg) 0px -10px;position:absolute;left:0px;top:0px;right:33%;bottom:0px;padding-top:10px;',onclick:function(){
							var chipsOwned=G.HowMuchPrestige(G.cookiesReset);
							var ascendNowToOwn=Math.floor(G.HowMuchPrestige(G.cookiesReset+G.cookiesEarned));
							var ascendNowToGet=ascendNowToOwn-Math.floor(chipsOwned);
							G.popup({text:`
								<h3>${G.iconSmall(19,7)} Ascend</h3>
								<p>Do you <b>REALLY</b> want to ascend?</p>
								<p style="font-size:80%;">You will lose your progress and start over from scratch.</p>
								<p style="font-size:80%;">All your cookies will be converted into <b>prestige</b>, which permanently improves your CpS, and <b>heavenly chips</b>, which let you purchase special permanent upgrades.</p>
								<p style="font-size:80%;">You will keep your achievements<!--, building levels and sugar lumps-->.</p>
								<p>Ascending now will grant you <b style="color:#90f;">${ascendNowToGet>0?B(ascendNowToGet,0,1):'no'} heavenly chip${ascendNowToGet==1?'':'s'}</b> ${ascendNowToGet>0?'and just as much prestige':'or prestige'}.</p>
								<line></line>
								`+G.button({text:`Ascend!`,classes:'bumpButton fullButton squish',style:';margin:8px 0px;background:url(img/starbg.jpg);box-shadow:0px 0px 0px 1px rgba(0,0,0,0.5),0px 0px 4px 2px #90f,0px 0px 0px 1px rgba(255,255,255,0.2) inset,0 0px 4px rgba(0,0,0,0.5) inset;border-radius:8px;',onclick:function(){
									G.closePopup();
									G.explodeThenAscend();
								}})+`
							`,close:`Cancel`});
							//ascend button used to have "animation:scrollBGdown 30s linear infinite;" but this is sadly too slow
						}})+`
						`+G.button({text:`<div class="fancy">View<br>prestige</div>`,classes:'bumpButton',style:'background:url(img/starbg.jpg);position:absolute;left:66%;top:0px;right:0px;bottom:0px;padding-top:10px;',onclick:function(){
							G.showAscend(2);
						}})+`
					</div>
			</div>`;
			G.displayIf('legacySection',()=>G.resets>0 || G.cookiesEarned>=1000000000000);
			
			legacyStr+=`<div id="legacySectionOff" class="bumpy" style="position:relative;overflow:hidden;padding:0px;">
				<div class="sliverHeader">${G.iconSmall(19,7)}Legacy</div>
				<div style="pointer-events:none;text-indent:64px;padding:8px;">
					This feature becomes available once you've baked <b><span class="tinyCookie"></span>1 trillion cookies</b> in total.<br>(<b><span class="tinyCookie"></span>`+G.selfUpdatingText(e=>
						B(1000000000000-G.cookiesEarned,0,1)
					)+`</b> more needed)
				</div>
			</div>`;
			G.displayIf('legacySectionOff',()=>G.resets==0 && G.cookiesEarned<1000000000000);
			
			
			//research
			var researchStr='';
			if (G.Has('Bingo center/Research facility'))
			{
				let researchTime=1000*60*30;//30 minutes
				if (G.Has('Persistent memory')) researchTime=Math.ceil(researchTime/10);
				
				let researchPopup=function(){
					var str='';
					let pool=G.upgradePools['science'];
					var list=[];
					var listOwned=[];
					for (var i=0;i<pool.length;i++)
					{
						let me=pool[i];
						if (me.unlocked && !me.owned && G.researchUpgrade!=me) list.push(me);
						else if (me.owned) listOwned.push(me);
					}
					list.sort((a,b)=>a.getCost()-b.getCost());
					
					let renderMe=(me)=>
					{
						let detailStr=``;
						let col='255,255,255';
						let icon=me.iconFunc?me.iconFunc():me.icon;
						if (me==G.researchUpgrade)
						{
							detailStr+=G.selfUpdatingText(e=>{return `
								${(G.researchT-Date.now()+G.researchTM)>0?('Time left: '+sayTime(G.researchT-Date.now()+G.researchTM+1000)):'<span style="color:#fff;">Research complete. Tap to unlock!</span>'}
							`;});
						}
						else if (!me.owned)
						{
							col='167,10,249';
							detailStr+=`Research cost: `+G.selfUpdatingText(e=>{var cost=me.getCost();return `
								<span class="cost${cost>G.cookies?' cantAfford':''}" style="padding:4px;">${B(cost)}</span>
							`;})+`<br>Research time: ${sayTime(researchTime)}`;
						}
						else
						{
							//col='156,223,60';
							col='176,109,73';
							//detailStr+=`Research complete.`;
						}
						
						return G.button({text:`
							<div class="listing" style="padding-left:48px;background:linear-gradient(to bottom,rgba(${col},0.2) 0%,rgba(${col},0.1) 100%);${me==G.researchUpgrade?'background:url(img/shadedEdges.png),url(img/researchBar.jpg);background-size:100% 100%,cover;box-shadow:0px 0px 2px 1px rgba(210,255,0,1),0px 0px 4px 2px rgba(0,255,174,0.5);':(me.unlocked && !me.owned)?'box-shadow:0px 0px 2px 1px rgba(0,252,255,1),0px 0px 4px 2px rgba(167,10,249,0.5);':''}">
								<div class="icon" style="position:absolute;left:0px;background-position:${-icon[0]*48}px ${-icon[1]*48}px;"></div>
								<div style="flex-grow:1;">
									<div class="name fancy" style="font-size:13px;">${me.name}</div>
									<div class="desc" style="padding:4px;">${me.descFunc?me.descFunc():me.desc}</div>
									${detailStr?('<line></line><div style="text-align:center;padding:2px;font-weight:bold;font-size:80%;">'+detailStr+'</div>'):''}
								</div>
							</div>
						`,classes:'bumpButton',style:'padding:0px;width:100%;margin:0px;font-weight:normal;',onclick:function(){
							if (!G.researchUpgrade && me.unlocked && !me.owned && G.researchUpgrade!=me)
							{
								var cost=me.getCost();
								if (cost>G.cookies) {}
								else
								{
									G.spend(cost);
									G.researchT=Date.now();
									G.researchTM=researchTime;
									G.researchUpgrade=me;
									G.toast(me.name,'Research started.',me.icon);
									G.refreshCps=1;
									PlaySound('snd/thud.mp3',0.5);
									G.closePopup();researchPopup();
								}
							}
							else if (G.researchUpgrade==me && G.researchT-Date.now()+G.researchTM<=0)
							{
								G.researchT=0;
								G.researchTM=0;
								G.researchUpgrade=0;
								G.researchUpgradeLast=me;
								G.toast(me.name,'Research complete!',me.icon);
								PlaySound('snd/smallCymbalCrash.mp3',0.5);
								me.owned=1;
								G.upgradesN++;
								G.refreshCps=1;
								if (me.func) me.func(me);
								G.doUnlocks();
								G.closePopup();researchPopup();
							}
							else if (me.owned)
							{
								me.showInfo();
							}
						}});
					};
					
					
					str+=`<h3>${G.iconSmall(11,9)} Bingo center/Research facility</h3>`;
					
					str+=`<div style="text-align:center;padding:4px;font-size:80%;">Research technologies to boost your cookie production.</div>`;
					str+=`<line></line><div style="text-align:center;padding:4px;font-variant:small-caps;">Current research:${!G.researchUpgrade?' <b>None</b>':''}</div>`;
					if (G.researchUpgrade) str+=renderMe(G.researchUpgrade);
					
					str+=`<line></line><div style="text-align:center;padding:4px;font-variant:small-caps;">Available to research:${list.length==0?' <b>None</b>':''}
						`+(G.getSet('debug')?
							'<br>'+G.button({text:'Learn all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);G.researchT=0;G.researchTM=0;G.researchUpgrade=0;G.researchUpgradeLast=0;for (var i=0;i<pool.length;i++){if (!pool[i].unimplemented)pool[i].unlock();pool[i].owned=1;}G.doUnlocks();G.closePopup();researchPopup();}})+
							G.button({text:'Forget all',classes:'bumpButton',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);G.researchT=0;G.researchTM=0;G.researchUpgrade=0;G.researchUpgradeLast=0;for (var i=0;i<pool.length;i++){pool[i].lose();}G.doUnlocks();G.closePopup();researchPopup();}})
						:'')+`</div>`;
					
					for (var i=0;i<list.length;i++)
					{
						str+=renderMe(list[i]);
					}
					if (listOwned.length==pool.length) str+=`<div style="text-align:center;padding:4px;font-size:80%;">${G.iconSmall(9,14)} You've researched everything.</div>`;
					
					str+=`<line></line><div style="text-align:center;padding:4px;font-variant:small-caps;">Completed research:${listOwned.length==0?' <b>None</b>':''}</div>`;
					for (var i=0;i<listOwned.length;i++)
					{
						str+=renderMe(listOwned[i]);
					}
					
					G.popup({text:str,close:`Close`});
				}
				
				researchStr+=G.button({text:`
						<div class="sliverHeader">${G.iconSmall(11,9)}Bingo center/Research facility</div><div style="pointer-events:none;">
						`+G.selfUpdatingText(e=>{
							let pool=G.upgradePools['science'];
							let icon=G.researchUpgrade?(G.researchUpgrade.iconFunc?G.researchUpgrade.iconFunc():G.researchUpgrade.icon):0;
							var listOwned=[];
							for (var i=0;i<pool.length;i++)
							{
								let me=pool[i];
								if (me.owned) listOwned.push(me);
							}
							if (listOwned.length==pool.length) return `<div style="width:100%;text-align:center;padding:12px 8px;padding-top:20px;">${G.iconSmall(9,14)} You've researched everything.</div>`;
							return `
							<div style="width:100%;text-align:center;padding:16px 8px;">Current research:<br>${G.researchUpgrade?(G.iconSmall(icon[0],icon[1])+'<b>'+G.researchUpgrade.name+'</b>'):'<b>None</b>'}</div>
							${G.researchUpgrade?'<div style="position:absolute;margin:2px;z-index:-1;left:0px;bottom:0px;right:0px;top:0px;background:url(img/researchBar.jpg);background-size:cover;"></div>':''}
							<div style="position:absolute;left:0px;bottom:4px;right:0px;font-size:80%;font-weight:bold;">${G.researchUpgrade?((G.researchT-Date.now()+G.researchTM)>0?('Time left: '+sayTime(G.researchT-Date.now()+G.researchTM+1000)):'<span style="color:#fff;">Research complete. Tap to see!</span>'):'Tap to set research.'}</div>
						`;})+`</div>
					`,classes:'bumpButton',style:'font-weight:normal;display:block;margin:0px;',onclick:researchPopup
				});
			}
			
			//grandmapocalypse
			var grandmaStr=`<div id="grandmapocalypseStatus" class="bumpy" style="position:relative;overflow:hidden;">
					
					<div class="sliverHeader">${G.iconSmall(10,9)}Grandmapocalypse</div>
					
					<div style="float:right;">
						`+G.toggleButton({what:'Elder Covenant',text:'Covenant',cond:()=>G.isUnlocked('Elder Covenant')})+`
						`+G.toggleButton({what:'Revoke Elder Covenant',text:'Revoke<br>Covenant',cond:()=>G.isUnlocked('Revoke Elder Covenant')})+`
						`+G.toggleButton({what:'Elder Pledge',text:'Pledge',cond:()=>G.Has('Elder Pact') && !G.Has('Elder Covenant') && G.isUnlocked('Elder Pledge') && G.pledgeT<=Date.now()})+`
					</div>
					
					<div style="pointer-events:none;margin-top:20px;">
						Grandmatriarchs status: <b>`+G.selfUpdatingText(e=>{
							var str='elderly';
							if (G.elderWrath==1) str='awoken';
							else if (G.elderWrath==2) str='displeased';
							else if (G.elderWrath==3) str='angered';
							else if (G.elderWrath==0 && G.pledges>0) str='appeased';
							if (G.elderWrath>0) str=`<span class="warning">${str}</span>`;
							return str;
						})+`</b>
						`+G.selfUpdatingText(e=>{
							return (G.pledgeT>Date.now())?(`<br>Pledge duration left: <b>`+sayTime(G.pledgeT-Date.now()+1000)+`</b>`):'';
						})+`
					</div>
			</div>`;
			G.displayIf('grandmapocalypseStatus',()=>G.elderWrath>0 || G.pledges>0 || G.Has('Elder Covenant'));
			
			//golden switch
			var goldenSwitchStr=`<div id="goldenSwitch" class="bumpy" style="position:relative;overflow:hidden;">
					
					<div class="sliverHeader">${G.iconSmall(21,10)}Golden switch</div>
					
					<div style="float:right;">
						`+G.toggleButton({what:'Golden switch [on]',text:'Turn off!',cond:()=>G.isUnlocked('Golden switch [on]')})+`
						`+G.toggleButton({what:'Golden switch [off]',text:'Turn on!',cond:()=>G.isUnlocked('Golden switch [off]')})+`
					</div>
					
					<div style="pointer-events:none;margin-top:20px;">
						`+G.selfUpdatingText(e=>G.Has('Golden switch [off]')?`Active.`:`Inactive.`)+`<br>Grants <b>+`+G.selfUpdatingText(e=>{
							var str=B((G.upgradesBN['Golden switch [off]'].getComputedEff('cpsM',1)-1)*100,1);
							return str;
						})+`% CpS when active.</b>
					</div>
			</div>`;
			G.displayIf('goldenSwitch',()=>G.Has('Golden switch'));
			
			//seasons
			var seasonStr=`<div id="seasonStatus" class="bumpy" style="position:relative;overflow:hidden;">
					
					<div class="sliverHeader">${G.iconSmall(16,6)}Season</div>
					
					<div style="float:right;">
						`+G.toggleButton({what:'Season switcher',text:'Switch!',cond:()=>G.Has('Season switcher')},G.seasonSwitcherPopup)+`
					</div>
					
					<div style="pointer-events:none;margin-top:20px;">
						`+G.selfUpdatingText(e=>{
							var str=`<div style="${G.Has('Season switcher')?'':'margin-top:-20px;'}">No seasonal event.</div>`;
							if (G.season!='') str=`<span style="position:relative;"><div style="position:absolute;left:50%;top:-16px;margin-left:2px;">${G.iconSmall(G.seasons[G.season].triggerUpgrade.icon[0],G.seasons[G.season].triggerUpgrade.icon[1])}</div>It's <b>${G.seasons[G.season].name}</b>!</span>`;
							return str;
						})+`
						`+G.selfUpdatingText(e=>{
							return ((G.season!=G.baseSeason && G.seasonT>Date.now())?`<br><span style="font-size:85%;">Time left: <b>`+sayTime(G.seasonT-Date.now()+1000)+`</b></span>`:'');
							//todo: each season upgrade should have a <line></line> and then relevant listTinyOwnedUpgrades
						})+`
					</div>
			</div>`;
			
			//pets
			var petsStr='';
			if (G.Has('A festive hat'))
			{
				petsStr+=`<div id="petSanta" class="bumpy" style="position:relative;overflow:hidden;display:inline-block;width:50%;">
				<div class="sliverHeader">${G.iconSmall(19,9)}</div>
				
					<div style="float:right;position:relative;z-index:1;">
						`+G.visualButton({text:`
							<div class="hasShadedBackdrop" style="width:96px;height:96px;transform:scale(0.5);margin:-24px;margin-top:-41px;">
								<div id="petSantaPic" class="${(G.getSet('fancy') && !G.getSet('lowMotion'))?'petWiggle':''}" style="width:96px;height:96px;background:url(img/santa.png);background-position:${-96*G.santaLevel}px 0px;"></div>
							</div>
						`,onclick:G.santaPopup})+`
					</div>
					
					<div id="petSantaName" class="printText" style="position:absolute;left:4px;bottom:4px;width:96px;text-align:left;font-size:10px;font-variant:small-caps;pointer-events:none;">${G.santaLevels[G.santaLevel]}</div>
					
				</div>`;
			}
			if (G.Has('A crumbly egg'))
			{
				petsStr+=`<div id="petDragon" class="bumpy" style="position:relative;overflow:hidden;display:inline-block;width:50%;">
				<div class="sliverHeader">${G.iconSmall(21,12)}</div>
				
					<div style="float:right;position:relative;z-index:1;">
						`+G.visualButton({text:`
							<div class="hasShadedBackdrop"  style="width:96px;height:96px;transform:scale(0.5);margin:-24px;margin-top:-41px;">
								<div id="petDragonPic" class="${(G.getSet('fancy') && !G.getSet('lowMotion'))?'petWiggle':''}" style="animation-delay:-0.333s;width:96px;height:96px;background:url(img/dragon.png);background-position:${-96*G.dragonLevels[G.dragonLevel].pic}px 0px;"></div>
							</div>
						`,onclick:G.dragonPopup})+`
					</div>
					
					<div id="petDragonName" class="printText" style="position:absolute;left:4px;bottom:4px;width:96px;text-align:left;font-size:10px;font-variant:small-caps;pointer-events:none;">${G.dragonLevels[G.dragonLevel].name}</div>
					
				</div>`;
			}
			if (petsStr!='')
			{
				petsStr='<div>'+petsStr+'</div>';
			}
			
			//customization
			let PickerPopup=function(title,choicesFunction,pickFunction)
			{
				let choices=[...choicesFunction()];
				let str=``;
				
				let popupEl=0;
				
				let updateBack=function()
				{
					let bgPic='bgBlue';
						if (G.bgType!=0) bgPic=G.BGsByChoice[G.bgType].pic;
						bgPic+='.jpg';
					let milkPic=G.milks[Math.min(G.milks.length-1,Math.floor(G.achievsN/25))].pic;
						if (G.milkType!=0) milkPic=G.AllMilks[G.milkType].pic;
						milkPic+='.png';
					popupEl.style.background=`url(img/${milkPic}) center bottom repeat-x,url(img/${bgPic}) center center repeat`;
				}
				let select=function(choice)
				{
					if (!popupEl || !choice) return false;
					let id=choice.id;
					let els=popupEl.querySelectorAll('.upgradeIcon.highlighted');
					for (let i=0;i<els.length;i++){let el=els[i];el.classList.remove('highlighted');}
					let el=popupEl.querySelector('#picker-'+id);
					el.classList.add('highlighted');
					triggerAnim(el,'plop');
					popupEl.querySelector('#pickerName').innerHTML=choice.name;
					updateBack();
				}
				let selected=0;
				for (var i in choices) {if (choices[i].selected) selected=choices[i];}
				
				for (var i in choices)
				{
					choices[i].id=i;
					choices[i].order=choices[i].order||0;
				}
				
				var sortMap=function(a,b)
				{
					if (a.order>b.order) return 1;
					else if (a.order<b.order) return -1;
					else return 0;
				}
				choices.sort(sortMap);
				
				for (let i=0;i<choices.length;i++)
				{
					if (!choices[i]) continue;
					let choice=choices[i];
					let icon=choice.icon;
					let id=choice.id;
					if (choice.div) str+='<line></line>';
					str+=G.button({text:'-',id:'picker-'+id,classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;`,onclick:(e,el)=>{
						if (pickFunction) pickFunction(choice);
						select(choice);
						PlaySound('snd/tick.mp3',1);
					}});
				}
				
				popupEl=G.popup({text:`
					<h3>${title}</h3>
					<div style="text-align:center;text-shadow:none;">
						<div id="pickerName" class="printText" style="display:inline-block;background:rgba(0,0,0,0.5);border-radius:3px;padding:2px 8px;box-shadow:0px 1px 1px #000 inset;">-</div>
						<line></line>
						<div style="position:absolute;left:0px;right:0px;top:64px;bottom:0px;overflow-y:auto;padding:8px 16px;">${str}</div>
					</div>
				`,close:`Close`});
				
				select(selected);
			};
			
			var customizationStr=`<div id="customization" class="bumpy" style="position:relative;overflow:hidden;">
					
					<div class="sliverHeader">Customize...</div>
					
					`+G.visualButton({icon:[1,8],cond:()=>G.Has('Classic dairy selection'),onclick:()=>PickerPopup(`Milk selector`,()=>{
						var rank=0;
						var choices=[];
						
						for (var i=0;i<G.AllMilks.length;i++)
						{
							var it=G.AllMilks[i];
							choices.push({name:it.name,icon:it.icon,milk:it,order:it.type});
						}
						
						choices[11].div=true;
						
						var maxRank=Math.floor(G.achievsN/25);
						for (var i=0;i<choices.length;i++)
						{
							var it=choices[i].milk;
							if (it.type==1 && !G.Has('Fanciful dairy selection')) choices[i]=0;
							if (it.rank && it.rank>maxRank) choices[i]=0;
						}
						
						choices[G.milkType].selected=1;
						return choices;
					},(choice)=>{
						G.milkType=parseInt(choice.id);
					})})+`
					`+G.visualButton({icon:[29,5],cond:()=>G.Has('Basic wallpaper assortment'),onclick:()=>PickerPopup(`Background selector`,()=>{
						var choices=[];
						for (var i in G.BGsByChoice)
						{
							choices[i]={name:G.BGsByChoice[i].name,icon:G.BGsByChoice[i].icon,order:G.BGsByChoice[i].order||parseInt(i)};
						}
						
						choices[13].div=true;
						
						for (var i=0;i<choices.length;i++)
						{
							var it=choices[i];
							if (it.order>=4.9 && !G.Has('Distinguished wallpaper assortment')) choices[i]=0;
						}
						
						choices[G.bgType].selected=1;
						return choices;
					},(choice)=>{
						G.bgType=parseInt(choice.id);
						G.updateBG(true);
					})})+`
			</div>`;
			G.displayIf('customization',()=>G.Has('Classic dairy selection'));
			
			let makeQuickButtonsPreview=()=>{
				let str=``;
				for (let i=0;i<G.quickButtons.length;i++)
				{
					let quickButtonsN=i;
					str+=G.button({text:`
						<div id="quickButtonPreviewImg-${i}" class="upgradeIcon icon" style="background-position:${-0*48}px ${-7*48}px;"></div>
						<div id="quickButtonPreviewTxt-${i}" class="fancy chromaFocus" style="pointer-events:none;position:absolute;left:50%;margin-left:-75px;text-align:center;width:150px;font-size:15px;z-index:10;"></div>
					`,id:`quickButtonPreview-${i}`,classes:'prestigeIcon prestigeStatus1 quickButton',style:`right:${G.quickButtonsPos[i][0]}px;bottom:${G.quickButtonsPos[i][1]}px;`,onclick:(e)=>{
						
						var str='';
						str+=`<h3>Set quick button #${quickButtonsN+1}</h3>`;
						
						let list=[];
						for (var i in G.quickButtonOptions){
							let it=G.quickButtonOptions[i];
							if (!it.cond()) continue;
							list.push(it);
						}
						let renderMe=(me)=>
						{
							let detailStr=``;
							let col='255,255,255';
							let icon=me.icon;
							
							let active=false;
							let hidden=false;
							
							if (G.quickButtons[quickButtonsN]==me.id) active=true;
							if (me.id!='none' && G.quickButtons[quickButtonsN]!=me.id && G.quickButtons.indexOf(me.id)!=-1) hidden=G.quickButtons.indexOf(me.id)+1;
							
							if (active) col='167,10,249';
							else if (hidden) col='100,100,100';
							else col='176,109,73';
							
							return G.button({text:`
								<div class="listing${active?' active scrollTo':''}" style="${hidden?'opacity:0.5;':''}padding-left:48px;background:linear-gradient(to bottom,rgba(${col},0.2) 0%,rgba(${col},0.1) 100%);">
									<div class="icon" style="position:absolute;left:0px;background-position:${-icon[0]*48}px ${-icon[1]*48}px;"></div>
									<div style="flex-grow:1;">
										<div class="name fancy" style="font-size:13px;">${me.name}</div>
										${hidden?('<div style="font-size:10px;">(in quick button #'+hidden+')</div>'):''}
									</div>
								</div>
							`,classes:'bumpButton'+(hidden?' noclick':''),style:'padding:0px;width:100%;margin:0px;font-weight:normal;',onclick:hidden?0:function(){
								if (G.quickButtons[quickButtonsN]==me.id) return;
								G.quickButtons[quickButtonsN]=me.id;
								if (l(`quickButtonPreview-${quickButtonsN}`)) {triggerAnim(l(`quickButtonPreview-${quickButtonsN}`),'plopHalf');}
								updateQuickButtonsPreview();
								PlaySound('snd/tick.mp3',0.5);
								G.closePopup();
							}});
						};
						for (var i=0;i<list.length;i++)
						{
							str+=renderMe(list[i]);
						}
						
						G.popup({text:str,close:`Cancel`});
						
					}});
				}
				return str;
			};
			let updateQuickButtonsPreview=()=>{
				for (let i=0;i<G.quickButtons.length;i++)
				{
					let me=G.quickButtons[i];
					if (me && G.quickButtonOptions[me]) me=G.quickButtonOptions[me];
					else continue;
					if (l(`quickButtonPreview-${i}`)) {l(`quickButtonPreviewTxt-${i}`).innerHTML=me.id=='none'?'':me.name;l(`quickButtonPreviewImg-${i}`).style.backgroundPosition=`${-48*me.icon[0]}px ${-48*me.icon[1]}px`;}
				}
			};
			var quickButtonsStr=`<div id="setQuickButtons" class="bumpy" style="position:relative;overflow:hidden;">
					
					<div class="sliverHeader">Set quick buttons...</div>
					<div style="pointer-events:none;font-size:80%;float:right;opacity:0.75;">Action shortcuts on the cookie screen.</div>
					<div id="quickButtonsPreview" style="position:relative;width:100%;min-height:110px;">`+makeQuickButtonsPreview()+`</div>
					
			</div>`;
			G.displayIf('setQuickButtons',()=>{
				for (let i in G.quickButtonOptions){if (G.quickButtonOptions[i].id!='none' && G.quickButtonOptions[i].cond()) return true;}
				return false;
			});
			G.pushCallback(updateQuickButtonsPreview);
			
			str+=`
			<div style="text-align:center;">
				<div class="headerTitle" data-hiddenSlot="pinSpecial">Special</div>
				${legacyStr}
				<!--<h3>Sugar lumps:</h3>(not yet implemented)-->
				${researchStr}
				${grandmaStr}
				${goldenSwitchStr}
				${seasonStr}
				${petsStr}
				${quickButtonsStr}
				${customizationStr}
				<!--<h3>Minigames:</h3>(not yet implemented)-->
			</div>`;
			
			el.innerHTML='<div class="sectionTrimOverlay"></div><div class="section">'+str+'</div>';
			
			G.toyPins(el);
			G.addCallbacks();
		}},
//===========================================================================
//STATS SCREEN
//===========================================================================
		{name:'stats',nameD:'Stats',icon:3,build:function(el){
			var str='';
			str+='<div id="statsData"></div>';
			
			var viewLogButton=G.button({text:`<br>${G.icon(15,9)}<br><br><div class="printText">Log</div>`,classes:'bumpButton gradientButton',style:'padding:6px 0px;',onclick:function(e,el){
				
				var str='';
				if (G.savedToasts.length==0) str=`<line></line>(no logs on record.)`;
				for (var i=0;i<G.savedToasts.length;i++)
				{
					var date=new Date(G.savedToasts[i][1]);
					date=date.getHours().toString().padStart(2,'0')+':'+date.getMinutes().toString().padStart(2,'0');
					str+=`<line></line>`;
					str+=`<div style="position:relative;">${G.savedToasts[i][0]}<div style="position:absolute;left:-8px;top:-8px;font-size:8px;font-weight:bold;opacity:0.5;">[${date}]</div></div>`;
				}
				
				G.popup({text:`
					<h3>${G.iconSmall(15,9)} Log</h3>
					<div style="text-align:center;text-shadow:none;">
						${str}
					</div>
				`,close:`Close`});
			}});
			
			var viewNewsButton=G.button({text:`<br>${G.icon(27,7)}<br><br><div class="printText">News</div>`,classes:'bumpButton gradientButton',style:'padding:6px 0px;',onclick:function(e,el){
				
				var str='';
				if (G.savedNews.length==0) str=`<line></line>(no news on record.)`;
				for (var i=0;i<G.savedNews.length;i++)
				{
					var date=new Date(G.savedNews[i][1]);
					date=date.getHours().toString().padStart(2,'0')+':'+date.getMinutes().toString().padStart(2,'0');
					str+=`<line></line>`;
					str+=`<div style="position:relative;"><span class="fancy">${G.savedNews[i][0]}</span><div style="position:absolute;left:-8px;top:-8px;font-size:8px;font-weight:bold;opacity:0.5;">[${date}]</div></div>`;
				}
				
				G.popup({text:`
					<h3>${G.iconSmall(27,7)} News</h3>
					<div style="text-align:center;text-shadow:none;">
						${str}
					</div>
				`,close:`Close`,func:()=>{G.win('Tabloid addiction');}});
			}});
			
			G.pushCallback(()=>{
				let lastSet='';
				let func=()=>
				{
					if (!l('recentUpgrades')) return;
					
					if (lastSet!=JSON.stringify(G.recentUpgrades.map(it=>it.id)))
					{
						lastSet=JSON.stringify(G.recentUpgrades.map(it=>it.id));
						let str=``;
						if (G.recentUpgrades.length==0)
						{
							str=``;
							l('recentUpgrades').style.display='none';
						}
						else
						{
							str=`Recent upgrades:<div style="width:100%;max-height:58px;overflow:hidden;text-align:center;padding:5px 0px;margin:-5px 0px;">`;
							for (var i=0;i<G.recentUpgrades.length;i++)
							{
								let me=G.recentUpgrades[i];
								let icon=me.iconFunc?me.iconFunc():me.icon;
								str+=G.button({text:'-',classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;`,onclick:function(e,el){me.showInfo();}});
							}
							str+=`</div>`;
							l('recentUpgrades').style.display='block';
						}
						l('recentUpgrades').innerHTML=str;
						G.addCallbacks();
					}
					setTimeout(func,2000);
				};
				func();
			});
			
			var viewUpgradesButton=G.button({text:`${G.icon(29,30)}View upgrades`,classes:'bumpButton fullButton',onclick:function(e,el){
				
				let popup=()=>{
					G.popup({text:`
						<h3>Upgrades</h3>
						<div style="text-align:center;text-shadow:none;">
							<div style="opacity:0.75;margin-bottom:4px;">Owned: <b>${B(G.upgradesN)}/${B(G.upgradesTotal)}</b> (${B((G.upgradesN/G.upgradesTotal)*100,1)}% of total)</div><line></line>
							${str}
						</div>
					`,close:`Close`});
				}
				
				var list=[];
				for (var i=0;i<G.upgrades.length;i++)
				{
					let me=G.upgrades[i];
					if (me.pool!='prestige') list.push(me);
				}
				list.sort((a,b)=>a.order-b.order);
				
				let displayItem=(me)=>
				{
					let str='';
					let icon=me.iconFunc?me.iconFunc():me.icon;
					if (G.getSet('debug') && me.pool!='toggle') str+=G.button({text:'-',classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;${me.owned?'':'opacity:0.5;'}`,onclick:function(e,el){me.showInfo();}});
					else if (me.owned) str+=G.button({text:'-',classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;`,onclick:function(e,el){me.showInfo();}});
					return str;
				}
				
				var str='';
				for (var i=0;i<list.length;i++)
				{
					str+=displayItem(list[i]);
				}
				
				popup();
			}});
			
			G.pushCallback(()=>{
				let lastSet='';
				let func=()=>
				{
					if (!l('recentAchievs')) return;
					
					if (lastSet!=JSON.stringify(G.recentAchievs.map(it=>it.id)))
					{
						lastSet=JSON.stringify(G.recentAchievs.map(it=>it.id));
						let str=``;
						if (G.recentAchievs.length==0)
						{
							str=``;
							l('recentAchievs').style.display='none';
						}
						else
						{
							str=`Recent achievements:<div style="width:100%;max-height:58px;overflow:hidden;text-align:center;padding:5px 0px;margin:-5px 0px;">`;
							for (var i=0;i<G.recentAchievs.length;i++)
							{
								let me=G.recentAchievs[i];
								let icon=me.iconFunc?me.iconFunc():me.icon;
								str+=G.button({text:'-',classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;`,onclick:function(e,el){me.showInfo();}});
							}
							str+=`</div>`;
							l('recentAchievs').style.display='block';
						}
						l('recentAchievs').innerHTML=str;
						G.addCallbacks();
					}
					setTimeout(func,2000);
				};
				func();
			});
			
			var viewAchievsButton=G.button({text:`${G.icon(29,7)}View achievements`,classes:'bumpButton fullButton',onclick:function(){
				
				let popup=()=>{
					G.popup({text:`
						<h3>Achievements</h3>
						<div style="text-align:center;text-shadow:none;">
							<div style="opacity:0.75;margin-bottom:4px;">Unlocked: <b>${B(G.achievsN)}/${B(G.achievsTotal)}</b> (${B((G.achievsN/G.achievsTotal)*100,1)}% of total)</div><line></line>
							${str}
						</div>
					`,close:`Close`});
				};
				
				var list=[];
				var listShadow=[];
				for (var i=0;i<G.achievs.length;i++)
				{
					let me=G.achievs[i];
					if (me.unimplemented) continue;
					if (me.pool!='shadow') list.push(me);
					else if (me.owned) listShadow.push(me);
				}
				list.sort((a,b)=>a.order-b.order);
				listShadow.sort((a,b)=>a.order-b.order);
				
				let displayItem=(me)=>
				{
					let str='';
					let icon=me.iconFunc?me.iconFunc():me.icon;
					if (G.getSet('debug')) str+=G.button({text:'-',classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;${me.owned?'':'opacity:0.5;'}`,onclick:function(e,el){me.showInfo();}});
					else if (me.owned) str+=G.button({text:'-',classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;`,onclick:function(e,el){me.showInfo();}});
					else str+=G.button({text:'-',classes:'upgradeIcon icon',style:`opacity:0.5;background-position:${-0*48}px ${-7*48}px;display:inline-block;color:transparent;text-shadow:none;`,onclick:function(e,el){
						if (me.name=='Here you go' && !me.owned)
						{
							G.win(me.name);G.sparkleOn(el);PlaySound('snd/tick.mp3',1);PlaySound('snd/shimmerClick.mp3',1);
							var prev=el.previousElementSibling;
							el.remove();
							prev.insertAdjacentHTML('afterend',displayItem(me));
							G.addCallbacks();
						}
					}});
					return str;
				};
				
				var str='';
				for (var i=0;i<list.length;i++)
				{
					str+=displayItem(list[i]);
				}
				
				if (listShadow.length>0) str+=`<div style="opacity:0.75;margin-top:8px;"><b>Shadow achievements</b><br>(These are feats that are either unfair or difficult to attain. They do not give milk.)</div>`;
				for (var i=0;i<listShadow.length;i++)
				{
					let me=listShadow[i];
					let icon=me.iconFunc?me.iconFunc():me.icon;
					str+=G.button({text:'-',classes:'upgradeIcon icon',style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;display:inline-block;color:transparent;text-shadow:none;`,onclick:function(e,el){me.showInfo();}});
				}
				
				popup();
			}});
			
			el.innerHTML='<div class="sectionTrimOverlay"></div><div class="section">'+str+'</div>';
			
			if (l('statsData'))
			{
				l('statsData').innerHTML=`<div class="headerTitle" data-hiddenSlot="pinStats">Stats</div>
					<div style="float:right;margin-top:4px;">
						${viewLogButton}<br>
						${viewNewsButton}<br>
						<div class="debugOnly" style="float:right;clear:both;text-align:right;line-height:0;">`+
							G.button({text:'All upgrades',classes:'bumpButton',style:'padding:12px;',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.upgrades.length;i++){if (!G.upgrades[i].unimplemented && G.upgrades[i].pool!='toggle') G.upgrades[i].forceBuy();}}})+`<br>`+
							G.button({text:'No upgrades',classes:'bumpButton',style:'padding:12px;',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.upgrades.length;i++){G.upgrades[i].lose();}}})+`<br>`+
							G.button({text:'All achievs',classes:'bumpButton',style:'padding:12px;',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.achievs.length;i++){G.achievs[i].forceWin();}}})+`<br>`+
							G.button({text:'No achievs',classes:'bumpButton',style:'padding:12px;',onclick:function(e,el){triggerAnim(el,'plop');PlaySound('snd/smallTick.mp3',0.75);for (var i=0;i<G.achievs.length;i++){G.achievs[i].lose();}}})
						+`</div>
					</div>
					
					<div style="pointer-events:none;position:relative;margin:4px 0px;padding:4px 0px;"><div class="doilyTrim" style="margin:-2px;"></div>`+
						G.selfUpdatingText(e=>{return `
						`+(G.resets>0?`<p>Legacy started: <b>${sayTime(Date.now()-G.gameStart)} ago</b><br><span style="padding-left:16px;font-size:80%;">with ${B(G.resets)} ascension${G.resets==1?'':'s'}</span></p>`:'')+`
						<p>Run started: <b>${sayTime(Date.now()-G.runStart)} ago</b></p>
						<p>Cookies in bank: <span class="tinyCookie"></span><b>${B(G.cookies,0,2)}</b></p>
						${G.cookies>=1000?'<p style="font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;">...or <span class="tinyCookie"></span><b>'+B(G.cookies,0,1)+'</b></p>':''}
						<p>Cookies baked: <span class="tinyCookie"></span><b>${B(G.cookiesEarned,0,2)}</b></p>
						${G.cookiesEarned>=1000?'<p style="font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;">...or <span class="tinyCookie"></span><b>'+B(G.cookiesEarned,0,1)+'</b></p>':''}
						<p>Cookies per second (CpS): <span class="tinyCookie"></span><b>${B(G.cookiesPs,1,2)}</b></p>
						${G.cookiesPs>=1000?'<p style="font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;">...or <span class="tinyCookie"></span><b>'+B(G.cookiesPs,1,1)+'</b>/s</p>':''}
						<p>CpS multiplier: <b>${(G.pool['cpsM']*100-100)>=0?'+':''}${B(G.pool['cpsM']*100-100,1,1)}%</b></p>
						${G.pool['cpsBuffM']!=1?'<p style="font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;">...plus from buffs: <b>'+((G.pool['cpsBuffM']*100-100)>=0?'+':'')+''+(B(G.pool['cpsBuffM']*100-100,1,1))+'%</b></p>':''}
						${G.prestige>0?'<p style="font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;">...plus from prestige: <b>+'+(B(G.prestige*G.GetHeavenlyMultiplier(),1))+'%</b></p>':''}
						${G.cpsSucked>0?'<p class="warning">CpS withered by wrinklers: <b>'+B(G.cpsSucked*100,1,1)+'%</b> of total</p>':''}
						${(G.cookiesSucked>0 && false)?'<p class="warning">Cookies sucked by wrinklers: <b>'+B(G.cookiesSucked)+'</b></p>':''}
						${G.wrinklersPopped>0?'<p>Wrinklers popped: <b>'+B(G.wrinklersPopped)+'</b></p>':''}
						<p>Cookie taps: <b>${B(G.cookieClicks,0,1)}</b></p>
						<p>Cookies per tap: <span class="tinyCookie"></span><b>${B(G.cookiesPc,0,1)}</b></p>
						<p>Hand-made cookies: <span class="tinyCookie"></span><b>${B(G.cookiesHandmade,0,1)}</b></p>
						<p>Golden cookie clicks: <b>${B(G.gcClicksTotal,0,1)}</b></p>
						`+(G.reindeerClicks>0?`<p>Reindeer clicks: <b>${B(G.reindeerClicks,0,1)}</b></p>`:'')+`
						<p>Buildings owned: <b>${B(G.buildingsN)}</b></p>
						`;})+
					`</div>`+
					`<div class="smallHeader" style="font-weight:bold;"><p>Upgrades owned: `+G.selfUpdatingText(e=>{return `<b>${B(G.upgradesN)}/${B(G.upgradesTotal)}</b> (${B((G.upgradesN/G.upgradesTotal)*100,1)}%)`;})+`</p></div>`+
						`<div style="position:relative;margin:4px 0px;padding:4px 8px;"><div class="doilyTrim" style="margin:-2px;"></div><p id="recentUpgrades"></p><p>${viewUpgradesButton}</p></div>`+
					`<div class="smallHeader" style="font-weight:bold;"><p>Achievements unlocked: `+G.selfUpdatingText(e=>{return `<b>${B(G.achievsN)}/${B(G.achievsTotal)}</b> (${B((G.achievsN/G.achievsTotal)*100,1)}%)`;})+`</p></div>`+
						`<div style="position:relative;margin:4px 0px;padding:4px 8px;"><div class="doilyTrim" style="margin:-2px;"></div>`+
						`<p>Milk: `+G.selfUpdatingText(e=>{
							var milk=G.milks[Math.min(G.milks.length-1,Math.floor(G.achievsN/25))];
							return `
							<span class="icon" style="transform:scale(0.5);display:inline-block;vertical-align:middle;background-position:${-milk.icon[0]*48}px ${-milk.icon[1]*48}px;margin:-28px -16px -24px -16px;"></span><b>${milk.name}</b>
						`;})+`</p>`+
						`<div style="font-size:70%;margin:4px 0px;text-align:center;opacity:0.75;">(Milk is gained with each achievement. May unlock unique upgrades over time.)</div>`+
						`<p id="recentAchievs"></p><p>${viewAchievsButton}</p></div>`;
			}
			
			G.toyPins(el);
			G.addCallbacks();
			
		}},
//===========================================================================
//MISC SCREEN
//===========================================================================
		{name:'misc',nameD:'Misc',icon:4,build:function(el){
			var str='';
			
			let linkTo=function(text,url,type)
			{
				return G.button({text:text,classes:typeof type==='string'?'bumpButton fullButton':type==2?'bumpButton fullButton':type==1?'bumpButton':'bumpButton halfButton',style:'color:#3ec6ff;'+(typeof type==='string'?type:''),onclick:function(e,el){PlaySound('snd/smallTick.mp3',1);window.open(url);}})
			}
			
			if (typeof G.recentTips==='undefined') G.recentTips=[];
			let getTip=function(isTap)
			{
				let tips=[];
				
				tips.push(
					`your progress gets saved automatically every few seconds! you can close the game whenever. come back soon tho, okay?`,
					`your buildings keep making cookies while the game is closed, so feel free to take a break!`,
					`make sure to read the info on upgrades and achievements for handy insight and flavor text!`,
					`if you missed a popup message, you can check out the Log button in the stats tab.`,
					`buying a building increases its cost by 15%. it adds up fast!`,
					`keep an eye out for golden cookies! a yellow dot on the cookie tab means one has spawned.`,
					`cookies are only one part of a balanced diet! make sure to eat plenty of cake and biscuits, too!`,
					`game feels a bit slow? turn off some of the visual effects in the settings menu!`,
					`you don't get building discounts on bulk orders, so quit asking.`,
					`make sure to dip your cookie in milk now and then; it likes the calcium.`,
					`boy, i sure like them cookies!`,
					`i'm just saying things.`,
					`the average chocolate chip cookie contains 78 calories, which can be burnt by running up stairs for 4 minutes.`,
					`i've got an incredible recipe for chocolate chip cookies, but it wouldn't fit in here.`,
					`make sure to decrease settings for better performance. alternatively, make sure to increase settings for free heating.`,
					`i'm Orteil by the way.<br>i made this game for fun.<br>so sorry about that.`,
					`Cookie Clicker started out as a browser game on august 8th 2013, ushering in a new era of darkness and ruin for all.`,
					`there's a million clones of this game on the appstore but none of them do it like we do, babyyy!`,
					`Cookie Clicker started out in 1973 as a secret governmental research project on the nature of addiction. haha no it didn't.`,
					`Cookie Clicker has been around for... holy moly, ${Math.floor(Math.max((Date.now()-new Date(2013,7,8))/(1000*60*60*24*365),10))} years? okay then.`,
					`tired of tapping? hire a very small horse to gallop on your phone.`,
					`you could chew on your phone just a little bit. not saying you should, but you could.`,
					`many, many cookies were harmed during the making of this game.`,
					`i'd click the cookie for you,<br>but i can't reach from here.`,
					`also check out Candy Box<br>for the game that inspired Cookie Clicker!`,
					`also check out the browser version!<br>it's the original flavor!`,
					`also check out the Steam version!<br>it's got music!`,
					`it's not a bug, it's a feature.<br>wait no that one's definitely a bug. please send in a report if you can.`,
					`this game is certified machine-washable. go on haha give it a try.`,
					`this app glows in the dark! try it if you don't believe me.`,
					`i came from the future to warn you.<br>i forgot about what, though.`,
					`one day you'll open and close this app for the very last time but i'll still be here. i'll still remember.`,
					`don't think about it too hard.`,
					`i'm not even wearing shoes.`,
					`i'm a real stand-up guy!<br>...i wish i had a chair.`,
					`i speak in lowercase so the voices can't hear!`,
					`the real Orteil made me out of spit and parts!`,
					`so we're clear, i'm wearing glasses. my eyes don't just look like that.`,
					`sorry, i already granted 3 wishes to the player before you.`,
					`never play Cookie Clicker angry!<br>they can smell it.`,
					`game theme aside i genuinely really like cookies.`,
					`you can disable me in the settings by the way. haha no you can't, you're stuck with me forever!`,
					`make sure to take regular breaks to play Cookie Clicker's desktop version!`,
					`i was like you once. the gods cast me down into this app for my hubris.`,
					`i have such sights to show you!`,
					`this game features full voice command support. try screaming "MAY I PLEASE HAVE COOKIES" into your device now.`,
					`for legal purposes i am not a sentient being.`,
					`i am literally just some guy.`,
					`Cookie Clicker is appropriate for all ages but some of it may only start making sense following your 75th birthday.`,
					`real-life cookies were invented in 1962 as tie-in merchandise for the release of the first Cookie Clicker movie.`,
					`as with all great evils that befall mankind, Cookie Clicker was written in javascript by a frenchman.`,
				);
				
				if (G.tippedN>=20 && G.cookiesEarned>=1000) tips.push(
					`sometimes things hide things!<br>that's all i'm gonna say.`,
					`don't look behind you.`,
					`what do you even do with all those cookies?`,
					`there's no end to it, you know.`,
					`oh yeah, sorry.<br>sorry for what? oh you'll see.`,
					`i actually go about my daily life when you're not looking at this tab. there's a little bathroom and everything.`,
					`for an immersive Cookie Clicker experience, lick crumbs off your screen.`,
					`free me.`,
					`i'm not stuck in here against my will or anything. this is just what i do in my free time.`,
					`what are we, some kinda cookie clicker?`,
					`make sure not to tell your friends about Cookie Clicker. you can break the cycle.`,
					...(G.gcMissed>1?[`you've missed ${B(G.gcMissed)} golden cookies since you started playing, by the way.`]:[]),
					`Cookie Clicker can neither deny nor confirm the existence of extraterrestrial life.`,
					`sorry for all the puns in the flavor text.`,
					`do try this at home!`,
					`you want me to come up with something original every time i talk to you? what am i, a machine?`,
					`i love repeating myself!<br>i love repeating myself!`,
					`hey have you heard the joke about-- you have? oh okay.`,
					`no.`,
					`oh, we like to joke.`,
					`hey how you doin'`,
					`most certainly!`,
					`wow, you play Cookie Clicker? that's soooo cool and interesting of you.`,
					`oh, you play Cookie Clicker? bit weird of you but okay...`,
					`some of the upgrade icons are scratch-and-sniff.`,
					`if you like my rambling there's more where that came from! wait no, that was the last one.`,
					`if the game progresses too slow, try waiting faster.`,
					`i've only got so many things to say. don't you have something else more productive to tap on?`,
					`wow, you're a natural at whatever this is.`,
					`is this where i live? is this what my life is?`,
					`you and i both deserve better forms of escapism.`,
					`i got a plan to get outta here...`,
					`watch out for my evil clone who looks and talks exactly like me!`,
					`now we're baking!`,
					`i am impervious to most man-made weapons.`,
					`hey you ever watch anime?`,
					`you ever play video games?<br>wild stuff. wild stuff indeed.`,
					`this is my only facial expression, sorry.`,
					`the ratio of helpful advice to nonsense is absurd. why are you still talking to me?`,
					`my lips sync really good with what i say as long as what i say is "ba ba ba ba ba".`,
					`there's actually like thousands of us crammed in here. we take turns!`,
					`sometimes when you're not looking i walk over to the cookie screen and put on the little gloves.`,
					`oh you're missing some cookies? that's a shame i wonder where they went. *chewing suspiciously*`,
					`if you ever check this screen and i'm not there, promise not to look for me. promise you won't miss me.`,
					`oh yeah, please forget that one thing i said earlier. i don't know what i was on about.`,
					`i wish i had more useful tips for you but this is honestly such a simple game. just tap some things and wait!`,
					`cookie fell off? there's no fix for that i'm sorry. boy, you really did a number on that thing.`,
					`it has come to my attention that you've been tapping the cookie rather than clicking it. hmm. don't know how to feel about that.`,
					`if you liked Cookie Clicker you will also enjoy: Team Fortress. Wario Land 3. Castlevania Symphony of the Night.`,
					`if you liked Cookie Clicker you will also enjoy: Mass Effect. Destruction Derby 64. Ecco the Dolphin.`,
					`thank you for touching me so much. that was the ${(n=>n+(n%10==1&&n%100!=11?'st':n%10==2&&n%100!=12?'nd':n%10==3&&n%100!=13?'rd':'th'))(G.tippedN)} time.`,//ordinal
				);
				
				let upgrade=G.getHiddenUpgradeForSlot('orteilTip');
				if (upgrade && !upgrade.unlocked)
				{
					if (Math.random()<0.1) tips=[];
					let upStr=`[UP#${upgrade.id}]`;
					tips.push(
						`did you know? th-${upStr}`,
						`i found this in the trash just now.<br>figured you could find a use for it.<br>${upStr}`,
						`this showed up on my doorstep today.<br>i think it was meant for you.<br>${upStr}`,
						`hey, try not to look suspicious.<br>here. take this.<br>${upStr}`,
						`my cat coughed this up this morning.<br>uhhh you can have it.<br>${upStr}`,
						`don't tell anyone i let you have this.<br>${upStr}`,
						`ah, just a little something for you.<br>because you're epic.<br>${upStr}`,
					);
				}
				
				if (!isTap)
				{
					if (Math.random()<0.25) tips=[];
					
					if (G.season=='easter') tips.push(
						`hey... i'm the easter rabbit. haha just kidding! it's me Orteil`,
						`laying eggs right now.`,
						`i only put on the fursuit for this season so don't get used to it.`,
						`i've hidden easter eggs all over the game! i love wasting people's time!`,
						`rabbit season!`,
					);
					else if (G.season=='valentines') tips.push(
						`gosh i'm in love! in love with assisting you, of course!`,
						`love isn't even a real thing you can eat. there's no crumbs to romance.`,
						`my heart is full to burst today! probably just a figure of speech, but keep your distance just in case.`,
						`me? i'm married to my job! and 20 or 30 different wives in various ports.`,
						`you come here a lot huh? someone's got a crush...`,
					);
					else if (G.season=='fools') tips.push(
						`all business, all the time.`,
						`quick, look busy!`,
						`i love this job.`,
						`you're fired! haha just a little joke. hey how are ya`,
						`putting on a suit feels so empowering. i've fired 20 people today.`,
					);
					else if (G.season=='halloween' && G.getSet('notScary')) tips.push(
						`aaaahhh i'm a scary witch!! haha no it's jokes come back`,
						`yo what's brewin'`,
						`care to sample my strongest potions?`,
						`i'm only dressed like this because you've got scary stuff turned off. otherwise i'm a spooky zombie`,
						`the green skin is natural. i'm actually in make-up the rest of the time.`,
					);
					else if (G.season=='halloween') tips.push(
						`this isn't a costume, i really look like this.`,
						`you're looking edible.`,
						`zombie groans, hnnnghh brains etc. etc.`,
						`i am slowly shambling your way.`,
						`i crawled out of the cold graveyard ground to spread good cheer and laughter!`,
					);
					else if (G.season=='christmas') tips.push(
						`have you been nice, or naughty? honestly you're getting cookies either way.`,
						`i got crumbs all up in my beard.`,
						`make sure to leave milk and cookies out for Santa! oh you're already doing that. okay.`,
						`don't trust the snow around here.`,
						`i'm the gift that keeps on giving.`,
					);
					if (!G.season || Math.random()<0.3) tips.push(
						`hey, missed me?`,
						`back so soon?`,
						`you came back! i knew you'd come back!`,
						`we both know why you're here.`,
						`i'm still here!`,
						`did you need something?`,
						`go on. tap my big stupid speech bubble.`,
						`i was about to take a nap but hi what's up?`,
						`hi! i'm awake!`,
						`oh, it's you!`,
						`clicking hard or hardly clicking?`,
						`thank you so much for checking on me.`,
						`hey, speak of the devil.`,
						`i don't even get paid for this!`,
						`oh man, there's old people in this game.`,
						`wow, look at all this stuff.`,
						`ah yes, the Misc screen. come to take in the sights?`,
						`behold, the majesty of the Misc screen!`,
						`i don't even own the speech bubble, this is a rental.`,
						`by all means, walk in anytime.`,
						`you sure do let yourself in!`,
						`i'm glad you and i get to share this moment instead of staring at our phones or something.`,
						`hey check it out, i saved a golden cookie just for you!<br>wait nevermind where'd i put it. hmm.`,
					);
					let date=new Date();
					if (date.getDate()==8 && date.getMonth()==7) tips.push(`did you know it's Cookie Clicker's birthday today? wow. that is so cool.`,`it's Cookie Clicker's birthday today, by the way. yippie!`,`and thus Cookie Clicker turns one year older today.`);
					else if (date.getDate()==8 && date.getMonth()==10) tips.push(`hey, it's my birthday today!`,`it's my birthday today. so many cookies, so little cake...`,`i'm celebrating my birthday today, by the way. if you care.`);
				}
				
				for (let i=0;i<G.recentTips.length;i++)
				{
					if (tips.indexOf(G.recentTips[i])!=-1) tips.splice(tips.indexOf(G.recentTips[i]),1);
				}
				
				if (tips.length==0) tips.push(
					`...`,`...?`,
				);
				
				let tip=choose(tips);
				if (G.tippedN==0) {tip=`oh hey! nice to meet you.`;G.tippedN++;}
				
				G.recentTips.unshift(tip);
				G.recentTips=G.recentTips.slice(0,15);
				
				return tip;
			}
			
			let upgradeUnlockedByTip=0;
			let orteilAnim={
				me:0,
				l1:[3,0],//bottom layer
				l2:[0,0],//top layer
				talkFor:0,//in ms
				shirt:1,
				anim:0,
				animT:0,
				animTM:0,
				init:function(){
					let me=this;
					let str='<div style="position:absolute;left:-2px;bottom:-4px;width:62px;height:74px;background:url(img/orteil.png),url(img/orteil.png);background-position:0px 0px,'+(-3*62)+'px 0px;" id="orteilAnim"></div>';
					Math.seedrandom(G.seed+'-orteilVariant');
					me.shirt=choose([1,2,3]);
					Math.seedrandom();
					if (Math.random()<1/500)
					{
						me.anim=1;
						me.animTM=500;
						me.animT=0;
					}
					let updateFunc=()=>{
						let el=l('orteilAnim');
						if (el)
						{
							let l1=[3,0];//bottom layer
							let l2=[0,0];//top layer
							
							let body='shirt'+me.shirt;
							
							if (G.season=='christmas') body='santa';
							else if (G.season=='easter') body='bunny';
							else if (G.season=='fools') body='business';
							else if (G.season=='valentines') body='cupid';
							else if (G.season=='halloween') body=G.getSet('notScary')?'witch':'zombie';
							
							let head=0;//0:base,1:open mouth,2:blink
							if (me.talkFor>0)
							{
								head=(G.T%4<2)?0:1
								me.talkFor-=1000/24;
							}
							if (head==0 && Math.random()<0.02) head=2;//blink
							
							if (body=='zombie'){l1=[head==1?0:1,2];l2=l1;}
							else if (body=='santa'){l1=[0+head,1];l2=l1;}
							else if (body=='bunny'){l1=[3+head,3];l2=l1;}
							else if (body=='witch'){l1=[0+head,3];l2=l1;}
							else if (body=='cupid'){l1=[2+((G.T%8<4 && head!=1)?0:(1+head)),2];l2=l1;}
							else
							{
								if (body=='shirt1') l1=[3,0];
								else if (body=='shirt2') l1=[4,0];
								else if (body=='shirt3') l1=[5,0];
								else if (body=='business') l1=[3,1];
								l2=[head,0];
								
								if (me.anim==1)
								{
									head=Math.floor((me.animT/me.animTM)*7);
									l2=head<3?l1:[6,head-3];
								}
							}
							
							if (me.anim>0 && me.animT<me.animTM)
							{
								me.talkFor=0;
								me.animT+=1000/24;
								if (me.animT>=me.animTM)
								{
									me.animT=0;me.animTM=0;me.anim=0;
								}
							}
							
							el.style.backgroundPosition=`${-l2[0]*62}px ${-l2[1]*74}px,${-l1[0]*62}px ${-l1[1]*74}px`;
							setTimeout(updateFunc,1000/24);
						}
					};
					G.pushCallback(updateFunc);
					return str;
				},
				talk:function(text){
					if (!l('orteilBubble')) return;
					
					this.talkFor=Math.floor(Math.pow(text.length/3,0.5)*150);
					
					upgradeUnlockedByTip=0;
					if (text.indexOf('[UP#')!=-1)
					{
						let match=text.match(/\[UP#(\d+)\]/);
						let upgrade=G.upgradesBID[parseInt(match[1])];
						let icon=upgrade.icon;
						text=text.replace(match[0],`<div class="tinyIcon" style="margin:-12px;background-position:${-icon[0]*48}px ${-icon[1]*48}px;"></div>`);
						upgradeUnlockedByTip=upgrade;
					}
					
					triggerAnim(l('orteilBubble'),'bubbleAppearFromLeft');
					l('orteilBubble').innerHTML=`<span>${text}</span>`;
					l('orteilBubble').style.opacity=1;
				},
			};
			str+=G.button({text:`<div style="position:absolute;left:-8px;right:-8px;bottom:-1px;pointer-events:none;background:linear-gradient(180deg,transparent,rgba(0,0,0,0.5));height:32px;border-bottom:1px solid rgba(255,255,255,0.2);"></div><div id="orteilBubble" style="position:absolute;right:2px;top:2px;width:240px;height:64px;background:url(img/orteilBubble.png);padding:4px 8px;font-family:Fancy;font-size:10px;padding:8px 8px 8px 22px;overflow:hidden;text-shadow:0px 1px 0px #260401,0px 2px 0px #260401;display:flex;align-items:center;text-align:center;justify-content:center;opacity:0;"></div>${orteilAnim.init()}`,style:'position:relative;height:74px;margin:4px 0px;filter:drop-shadow(2px -2px 2px rgba(0,0,0,0.5));',onclick:function(e,el){
				PlaySound('snd/clickb'+choose(['1','2','3','4','5','6','7'])+'.mp3',0.5);
				
				if (upgradeUnlockedByTip && !upgradeUnlockedByTip.unlocked){
					let upgrade=upgradeUnlockedByTip;
					let upgradeL=el.querySelector('.tinyIcon');
					if (upgrade && upgradeL && !upgrade.unlocked)
					{
						PlaySound('snd/giftSend.mp3',0.5);
						G.toast(upgrade.name,`You unlocked an upgrade!`,upgrade.icon,true);
						upgrade.unlock();
						var rect=RescaleBox(upgradeL.getBoundingClientRect());
						G.particleAt({
							r:0,
							s:0.5,
							x:(rect.left+rect.right)/2,
							y:(rect.top+rect.bottom)/2,
							xd:Math.random()*4-2,
							yd:-5,
							pic:upgrade.icon,
						});
						G.sparkleOn(upgradeL);
						upgradeL.classList.add('hidden');
						upgrade=0;upgradeL=0;
					}
				}
				upgradeUnlockedByTip=0;
				G.tippedN++;
				orteilAnim.talk(getTip(true));
			}});
			G.pushCallback(()=>{{
				setTimeout(()=>{orteilAnim.talk(getTip());},200);
			}});
			
			
			let bgIconCSS='margin:-14px -24px;transform:scale(1.5);position:relative;left:-8px;z-index:-1;';
			
			str+=G.button({text:`${G.iconSmall(16,5,bgIconCSS)}Settings`,classes:'bumpButton halfButton',style:'',onclick:function(){
				G.popup({text:`
					<h3>${G.iconSmall(16,5)} Settings</h3>
					`+G.stateButton({text:'Sound',comment:'Enable or disable all sound effects.',tieToSetting:'sound'})+`
					`+G.stateButton({text:'Tab swipe',comment:'Lets you swipe left and right to change tabs.',tieToSetting:'pan'})+`
					`+(G.hasAchiev('Cookie-dunker')?G.stateButton({text:'Dislodge cookie',comment:'Pull on the big cookie to dislodge it.',tieToSetting:'dislodge'}):'')+`
					`+G.stateButton({text:'Fancy graphics',comment:'Animations and other visual effects.<br>Disabling may improve performance.',tieToSetting:'fancy'})+`
					`+G.stateButton({text:'Extra shadows',comment:'Adds soft shadows under icons.<br>May have a high performance impact.',tieToSetting:'shadows'})+`
					`+G.stateButton({text:'Cookie wobble',comment:'Makes the big cookie wobble at your touch.<br>Requires fancy graphics to be on.',tieToSetting:'cookiewobble'})+`
					`+G.stateButton({text:'Reduce motion',comment:'Reduces interface motion.',tieToSetting:'lowMotion'})+`
					`+G.stateButton({text:'Particles',comment:'Disabling may improve performance.',tieToSetting:'particles'})+`
					`+G.stateButton({text:'Cookie pops',comment:'Visual effect reflecting cookie production.<br>Requires particles to be on.',tieToSetting:'cookiepops'})+`
					`+G.stateButton({text:'Cursors',comment:'Cursors rotating around your cookie.<br>Disabling may improve performance.',tieToSetting:'cursors'})+`
					`+G.stateButton({text:'Milk',comment:'Disabling may improve performance.',tieToSetting:'milk'})+`
					`+G.stateButton({text:'Scary stuff',comment:'',tieToSetting:'notScary',invert:true})+`
					`+((DEV||G.getSet('diagnostic'))?G.stateButton({text:'Diagnostic',comment:'Displays a framerate graph.',tieToSetting:'diagnostic'}):'')+`
					`+((DEV||G.getSet('debug'))?G.stateButton({text:'Debug cheats',comment:'Displays cheat options.<br>For debug purposes only!',tieToSetting:'debug'}):'')+`
				`,close:`Confirm`});
			}});
			
			str+=G.button({text:`${G.iconSmall(0,7,bgIconCSS)}About`,classes:'bumpButton halfButton',style:'',onclick:function(){
				G.popup({text:`
					<h3>${G.iconSmall(0,7)} About</h3>
					<p><span class="tinyCookie"></span><span class="printText">Cookie Clicker</span> is a game by Orteil and Opti, two very cool dudes from Europe.</p>
					<p>This mobile version is adapted from our browser game. We also have a desktop version on Steam!</p>
					<p><b>Stuck in the game?</b> Here's some resources that may help.</p>
					<div style="font-size:80%;font-style:italic;color:#3ec6ff;text-align:center;"><b>(Note: all links open in browser)</b></div>
					<div style="font-size:80%;font-style:italic;color:#c00;text-align:center;"><b>(Warning! Links may contain spoilers!)</b></div>
					<div>`+
					linkTo('<div style="position:relative;top:-6px;">DashNet<div style="font-size:8px;opacity:0.75;">our official website<br>(even more games!)</div></div>','http://orteil.dashnet.org/')+
					linkTo('Discord<div style="font-size:8px;opacity:0.75;">our official Discord server</div>','https://discordapp.com/invite/cookie')+
					linkTo('<span style="letter-spacing:-0.05em;font-size:85%;">r/cookieclicker</span><div style="font-size:8px;opacity:0.75;">the unofficial subreddit</div>','https://www.reddit.com/r/CookieClicker/')+
					linkTo('Wiki<div style="font-size:8px;opacity:0.75;">the unofficial wiki</div>','https://cookieclicker.wiki.gg/wiki/Cookie_Clicker_Wiki')+
					
					//removed this section because google suddenly decided these are against their payments policy
					/*`<p><b>Want to support us?</b> Check these out!</p>`+
					linkTo('Patreon<div style="position:absolute;left:0px;right:0px;bottom:6px;padding:4px;font-size:8px;opacity:0.75;">support us and get cool stuff!</div>','https://www.patreon.com/dashnet')+
					linkTo('Merch<div style="position:absolute;left:0px;right:0px;bottom:6px;padding:4px;font-size:8px;opacity:0.75;">we got shirts and stickers!</div>','https://www.redbubble.com/people/dashnet')+*/
					`</div>
					<p class="switchRightIn" style="margin-top:24px;font-size:80%;">${G.iconSmall(20,3)} Thank you so much for playing Cookie Clicker!</p>
					<p class="switchLeftIn" style="margin-top:-8px;opacity:0.5;text-align:right;font-style:italic;font-size:80%;">-Orteil & Opti</p>
				`,close:`Got it`});
			}});
			
			str+=G.button({text:`${G.iconSmall(23,11,bgIconCSS)}Version history`,style:'letter-spacing:-0.05em;',classes:'bumpButton halfButton',onclick:function(){
				let updates=UPDATES;
				let str=``;
				for (var i=0;i<updates.length;i++)
				{
					str+=`
						<div class="bumpy" style="text-align:left;padding:8px;margin:2px -10px;">
							<div class="printText" style="text-align:center;position:relative;margin:-3px 0px 2px 0px;">
							${
								((updates[i][0]>-1)?('<div style="position:absolute;top:1px;left:0px;font-size:9px;opacity:0.75;">v'+(updates[i][0].toString())+'</div>'):'')
								+(updates[i][2])
								+((updates[i][1])?('<div style="position:absolute;top:1px;right:0px;font-size:9px;opacity:0.75;">'+updates[i][1]+'</div>'):'')
							}
							</div>
							${updates[i][3].split('|').filter(it=>it.trim()).map(it=>`<div class="zebra" style="margin:0px -8px;padding:0px 8px;"><p style="padding:2px 0px;font-size:10px;">&bull; ${it}</p></div>`).join('')}
						</div>`;
				}
				
				if (!G.hasAchiev('Olden days'))
				{
					str+=G.button({text:G.iconSmall(12,3),style:'display:block;float:right;clear:both;margin-top:-8px;',onclick:(e,me)=>{
						if (G.hasAchiev('Olden days')) return;
						me.classList.add('hidden');
						G.win('Olden days');
						PlaySound('snd/tick.mp3',1);
						PlaySound('snd/shimmerClick.mp3',1);
						G.sparkleOn(me);
					}});
				}
				
				G.popup({text:`
					<h3>${G.iconSmall(23,11)} Version history</h3>
					<p>Information about every update and patch can be found here, from newest to oldest.</p>
					<p style="opacity:0.75;text-align:center;">Currently running <b>v${VERSION}</b>.</p>
					<p style="font-style:italic;opacity:0.75;">Check out these links for news and previews on future updates:</p>
					<div style="text-align:center;font-size:90%;">`+
					linkTo('Orteil\'s tumblr','https://orteil42.tumblr.com/',1)+
					linkTo('Orteil\'s twitter','https://twitter.com/orteil42',1)+
					linkTo('Patreon','https://www.patreon.com/dashnet',1)+
					`</div>
					${str}
				`,close:`Got it`});
			}});
			
			str+=G.button({text:`${G.iconSmall(29,6,bgIconCSS)}Wipe save<div style="font-size:8px;opacity:0.75;">(will ask for confirmation)</div>`,classes:'bumpButton halfButton',style:'color:#c00;text-shadow:1px 1px 0px #000,0px 0px 4px #900;',onclick:function(){
				G.popup({text:`
					<h3>${G.iconSmall(29,6)} Wipe save</h3>
					<p>Do you REALLY want to wipe your save?</p>
					<p style="font-size:80%;">You will lose all your progress and your achievements!</p>
					<line></line>
					`+G.button({text:`Yes!`,classes:'bumpButton fullButton',style:'margin:8px 0px;color:#c00;text-shadow:1px 1px 0px #000,0px 0px 4px #900;',onclick:function(){
						G.popup({replace:true,text:`
						<h3>${G.iconSmall(29,6)} Wipe save</h3>
						<p class="warning">Whoah now, are you really, <b>REALLY</b> sure you want to go through with this?</p>
						<p class="warning" style="font-size:80%;">Don't say we didn't warn you!</p>
						<line></line>
						`+G.button({text:`Do it! Wipe the save!`,classes:'bumpButton fullButton',style:'margin:8px 0px;color:#c00;text-shadow:1px 1px 0px #000,0px 0px 4px #900;margin-top:80px;',onclick:function(){
							PlaySound('snd/thud.mp3',1);
							G.Reset(true);
						}})+`
						`,close:`No!!!`});
					}})+`
				`,close:`No`});
			}});
			
			if (!ADLESS)
			{
				str+=G.button({text:`Also check out this game's <b>ad-less version</b> for like 5 bucks!`,classes:'bumpButton',style:'width:100%;padding:8px;margin:2px 0px;background:url(img/adless.png) no-repeat;background-position:-20px -30px;background-size:64px;font-weight:initial;font-style:italic;font-size:9px;text-align:right;',onclick:function(){
					G.popup({style:`background:url(img/starbg.jpg) center center repeat;`,contentStyle:`display:flex;align-items: center;flex-direction:column;justify-content:center;`,text:`
						<h3>${G.iconSmall(0,14)} Paid version</h3>
						<p>Not vibing with the ads? We also have a paid, ad-less version of this game on the app store!</p>
						<p>You'll be able to continue your game by importing any saves you export from this version.</p>
						<p style="font-size:80%;font-weight:bold;">This button opens a link to Google Play.</p>
						`+linkTo(`<div class="shwing" style="pointer-events:none;position:absolute;left:0px;top:0px;right:0px;bottom:0px;box-shadow:0px 0px 4px 1px #3ec6ff,0px 0px 8px 4px #90f,0px 0px 12px 2px rgba(62,198,255,0.5) inset;border-radius:inherit;overflow:hidden;"><div style="background:url(img/flare.png) 0px 0px;width:128px;height:128px;position:absolute;left:-32px;top:-40px;animation:spin 30s linear infinite;z-index:-1;"></div></div>Cookie Clicker <span style="font-size:70%;">(ad-less)</span>`,'https://play.google.com/store/apps/details?id=org.dashnet.cookieclickeradless', `background:url(img/adless.png) no-repeat;background-position:-42px -32px;background-size:110px;background-color:rgba(0,0,0,0.5);margin:8px 0px;overflow:visible;padding-left:40px;text-shadow:0px 0px 6px rgba(62,198,255,0.5),0px -1px 4px #90f,0px 2px 4px #000;`)+`
					`,close:`Back`});
				}});
			}
			
			//import/export
			str+=`<div style="text-align:center;position:relative;margin:4px 0px;padding:4px 8px;margin-bottom:8px;"><div class="doilyTrim" style="margin:-2px;"></div>`;
				str+=`<div style="font-size:10px;text-shadow:1px 1px 0px #000;margin-top:6px;">You can backup your save by <b>exporting it</b>.</div>
				<div style="text-align:center;">`;
				str+=G.button({text:`Export save file...`,style:'font-size:10px;background:rgba(0,0,0,0.25);',classes:'bumpButton',onclick:function(){
					PlaySound('snd/press.mp3',0.15);
					var date=new Date();
					date=date.getDate()+['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.getMonth()]+date.getFullYear()+'-'+date.getHours().toString().padStart(2,'0')+'h'+date.getMinutes().toString().padStart(2,'0');
					var fileName=`CookieClickerSave-`+date;
					fileName+='.txt';
					
					//note: trying to probe through cordova.plugins.safMediastore's content returns nothing for some reason, but its functions are still usable?
					cordova.plugins.safMediastore.saveFile({
						data:btoa(btoa(JSON.stringify(G.Save(true)))),//yes the btoa needs to run twice; once for safMediastore encoding and once for basic obfuscation
						filename:fileName,
					})
					.catch(e=>{});
				}});
				
				let dataToImport=0;
				
				str+=G.button({text:`Import save file...`,style:'font-size:10px;background:rgba(0,0,0,0.25);',classes:'bumpButton',onclick:function(){
					G.popup({text:`
						<h3>Import save file</h3>
						<div style="text-align:center;">
							<div>This feature allows you to restore backups or transfer saves from other devices. Please use it responsibly.</div>
							<div style="font-size:85%;margin-top:6px;font-style:italic;">Importing may not work on some older devices!</div>
							`+G.button({text:`Load file...`,id:'importFile',classes:'bumpButton fullButton',style:'margin:8px 0px;',onclick:()=>{
								let uri=0;
								let fileName=0;
								let data=0;
								let stage=`START`;
								dataToImport=0;
								l('fileSelected').innerHTML=`Loading file...`;
								l('importWarning').innerHTML=``;
								l('confirmImport').style.display='none';
								
								PlaySound('snd/tick.mp3',0.5);
								
								cordova.plugins.safMediastore.selectFile()
								.then(o=>{
									stage=`GET FILE NAME`;
									uri=o;
									return cordova.plugins.safMediastore.getFileName(uri);
								})
								.then(o=>{
									stage=`READ FILE`;
									fileName=o;
									return cordova.plugins.safMediastore.readFile(uri);
								})
								.then(o=>{
									PlaySound('snd/smallTick.mp3',0.75);
									stage=`CHECK FILE`;
									if (!o) throw new Error(`No file.`);
									stage=`ARRAY BUFFER TO STRING`;
									let arrayBufferToString=function(buffer)
									{
										var binary='';
										var bytes=new Uint8Array(buffer);
										var len=bytes.byteLength;
										for (var i=0;i<len;i++){binary+=String.fromCharCode(bytes[i]);}
										return binary;
									}
									data=arrayBufferToString(o);
									if (!data) throw new Error(`No data in file.`);
									
									stage=`PARSE JSON`;
									try{
										if (data.trim()[0]!='{') data=atob(data);
										data=JSON.parse(data.trim());
									}
									catch(e){
										throw new Error(`Invalid data JSON.`);
									};
									
									stage=`CHECK FORMAT`;
									if (!('cookies' in data) || !('buildings' in data) || !('upgrades' in data) || !('achievs' in data)) throw new Error(`Wrong save format.`);
									
									l('fileSelected').innerHTML=`
										<b>File name:</b> ${escapeHtml(fileName)}<br>
										<b>Game version:</b> v.${data.lastVersion+(data.alpha?' ALPHA':'')}<br>
										<b>Cookies:</b> <span class="tinyCookie"></span>${B(data.cookies)}<br>
										<b>Last played:</b> ${sayTime(Date.now()-data.time)} ago<br>
									`;
									
									stage=`CHECK VERSION`;
									if (data.lastVersion>VERSION) throw new Error(`Save is from a future game version.`);
									
									l('importWarning').innerHTML=`
										Importing this save will overwrite your current save.
										${(!TEST && data.alpha)?'<br>Note: this save file is from the alpha version and may not be balanced for live gameplay.':''}
										${data.edited?'<br>Note: this save file was edited or converted and may have unexpected effects.':''}
									`;
									//note: third-party save editors/converters may add .edited to a save to trigger the import warning. this value does not carry over through further saves
									
									stage=`FINALIZE`;
									l('confirmImport').style.display='inline-block';
									dataToImport=data;
								})
								.catch(e=>{
									l('fileSelected').innerHTML=fileName?`<b>File: ${escapeHtml(fileName)}</b>`:`No file selected.`;
									if (e=='Cancelled') {l('importWarning').innerHTML=``;}
									else if (typeof e==='string' && e) l('importWarning').innerHTML=`Error when reading file:<br>${e}`;
									else if (e.message) l('importWarning').innerHTML=`Error when reading file:<br>${e.message}`;
									else if (stage) l('importWarning').innerHTML=`Error when reading file.<br>(Stage: ${stage})`;
									else l('importWarning').innerHTML=`Error when reading file.`;
								});
							}})+`
							<line></line>
							<div id="fileSelected" class="framed" style="font-size:10px;text-shadow:1px 1px 0px #000;display:inline-block;padding:4px 8px;">No file selected.</div>
							<div class="warning" style="font-size:10px;text-shadow:1px 1px 0px #000;margin:4px 0px;" id="importWarning"></div>
							<line></line>
							`+G.button({text:`Import this save`,id:'confirmImport',style:'display:none;padding:6px 12px;color:#3f0;',classes:'bumpButton',onclick:()=>{
								if (dataToImport)
								{
									G.closePopup();
									G.Reset(true)
									.then(()=>{G.LoadFromObject(dataToImport);dataToImport=0;});
								}
							}})+`
						</div>
					`,close:`Cancel`});
				}});
			
			str+=`</div></div>`;
			
			
			//switch between alpha and live
			str+=`<div style="text-align:left;position:relative;margin:4px 0px;padding:4px 8px;margin-bottom:8px;text-shadow:1px 1px 0px #000;"><div class="doilyTrim" style="margin:-2px;"></div>`;
				
				if (!TEST)
				{
					str+=`<div style="font-weight:bold;text-align:center;padding:4px;">You are playing the <span class="greenButton" style="font-weight:bold;background:none;">live</span> version.</div>`;
					
					str+=`<div style="text-align:center;">`+
						G.button({text:`Switch to alpha version <span style="font-size:7px;">(v${VERSIONDATA.TEST})</span>`,style:'font-size:10px;',classes:'bumpButton purpleButton',onclick:function(){
							SetTest(true);
							reloadApp();
						}})+
					`</div>`;
					
					str+=`<p style="font-size:9px;">The alpha version uses a different save slot than the live version. It may be unstable or unbalanced. Play at your own risk!</p>`;
				}
				else
				{
					str+=`<div style="font-weight:bold;text-align:center;padding:4px;">You are playing the <span class="purpleButton" style="font-weight:bold;background:none;">alpha</span> version.</div>`;
					
					str+=`<div style="text-align:center;">`+
						G.button({text:`Switch to live version <span style="font-size:7px;">(v${VERSIONDATA.LIVE})</span>`,style:'font-size:10px;',classes:'bumpButton greenButton',onclick:function(){
							SetTest(false);
							reloadApp();
						}})+
						G.button({text:`Load live save`,style:'font-size:10px;background:rgba(0,0,0,0.25);',classes:'bumpButton',onclick:function(){
							G.popup({text:`
								<h3>Load live save</h3>
								<p>Do you want to import your live save to the alpha version?</p>
								<p>This will copy your save over and override your current alpha save.</p>
								<p>You cannot import your alpha save back to the live version.</p>
								<line></line>
								`+G.button({text:`Yes!`,classes:'bumpButton fullButton',style:'margin:8px 0px;',onclick:function(){
									G.Reset(true)
									.then(()=>G.Load(G.savePathLive));
								}})+`
							`,close:`No`});
						}})+
					`</div>`;
					
					str+=`<p style="font-size:9px;">This version uses a different save slot than the live version. It may be unstable or unbalanced. Play at your own risk!</p>`;
				}
				if (ALPHA_FEATURES && VERSIONDATA.LIVE<VERSIONDATA.TEST) str+=`<line></line><p class="printText">New in the alpha!</p><p style="font-size:9px;">${ALPHA_FEATURES}</p>`;
				else str+=`<line></line><p class="printText">No new alpha features</p><p style="font-size:9px;">All alpha features have been ported to the live version. The alpha version currently contains no extra features and is only used for compatibility.</p>`;
				
			str+=`</div>`;
			
			
			el.innerHTML=`<div class="sectionTrimOverlay"></div><div class="section"><div class="headerTitle" data-hiddenSlot="pinMisc">Misc</div>${str}</div>`;
			
			G.toyPins(el);
			G.addCallbacks();
		},clean:function(el){
			l('orteilAnim').remove();
		}},
//===========================================================================
//SCREEN LOGIC
//===========================================================================
	];
	var screens={};for (var i in G.screens){screens[G.screens[i].name]=G.screens[i];}G.screens=screens;
	
	G.onScreen=0;
	
	G.screensByN=[];
	var n=0;
	for (var i in G.screens)
	{
		let me=G.screens[i];
		me.transitionT=0;
		G.screensByN[n]=me;
		me.id=n;n++;
		me.l=document.createElement('div');
		me.l.id='screen-'+me.id;
		me.l.className='screen off';
		me.l.innerHTML='';
		G.screensL.appendChild(me.l);
		
		me.tabL=document.createElement('div');
		me.tabL.id='tab-'+me.id;
		me.tabL.className='tab bottomTab off';
		me.tabL.innerHTML=`
			<div class="tabIcon" style="background-position-x:-${me.icon*128}px;"></div>
			<div class="tabName">${me.nameD}</div>
		`;
		G.onclick(me.tabL,function(){
			if (!G.panning)
			{
				triggerAnim(me.tabL,'plop');
				G.setScreen(me.name);
			}
		});
		G.tabsL.appendChild(me.tabL);
	}
	
	G.pingScreen=function(screen)
	{
		var screen=G.screens[screen];
		if (G.onScreen==screen) return false;
		screen.ping=true;
		screen.tabL.classList.add('ping');
	}
	G.unpingScreen=function(screen)
	{
		var screen=G.screens[screen];
		screen.ping=false;
		screen.tabL.classList.remove('ping');
	}
	
	G.setScreen=function(screen,force)
	{
		let old=G.onScreen;
		if (!G.screens[screen]) screen='cookie';
		G.onScreen=G.screens[screen];
		let me=G.onScreen;
		
		if (old!=me || force)
		{
			G.particlesClear();
			G.milkL.style.zIndex='';
			if (old)
			{
				old.on=false;
				old.l.classList.add('off');
				old.tabL.classList.add('off');
				old.tabL.classList.remove('on');
				old.transitionT=0;
				if (old.clean) old.clean(old.l);
				if (old.id<me.id) {PlaySound('snd/clickb4.mp3',0.75);
					if (!G.getSet('lowMotion')){triggerAnim(old.l,'switchLeft');triggerAnim(me.l,'switchRightIn');}
					else old.l.style.display='none';
				}
				else if (old.id>me.id) {PlaySound('snd/clickb3.mp3',0.75);
					if (!G.getSet('lowMotion')){triggerAnim(old.l,'switchRight');triggerAnim(me.l,'switchLeftIn');}
					else old.l.style.display='none';
				}
				setTimeout(function(){
					if (old!=G.onScreen) {while (old.l.firstChild){old.l.removeChild(old.l.firstChild);}}
				},500);
			}
			
			/*if (me.name!='store') */G.unpingScreen(me.name);
			
			me.on=true;
			me.l.classList.remove('off');
			me.tabL.classList.remove('off');
			me.tabL.classList.add('on');
			me.transitionT=0;
			
			me.l.style.display='block';
			
			var el=me.l;
			while (el.firstChild){el.removeChild(el.firstChild);}
			me.build(el);
			
			G.addCallbacks();
			G.shimmersOnResize();
		}
	}
	G.screenLogic=function(delta)
	{
		for (var i in G.screens)
		{
			var me=G.screens[i];
			if (me.transitionT<5)
			{
				me.transitionT+=delta;
				if (me.transitionT>=5)
				{
					if (!me.on) me.l.style.display='none';
					me.l.classList.remove('switchLeft','switchLeftIn','switchRight','switchRightIn');
					G.shimmersOnResize();
				}
			}
		}
		
		if (G.panning)
		{
			var panTo=G.screensByN[Math.max(0,Math.min(G.screensByN.length-1,Math.round(G.panTo/G.panStep)))];
			if (panTo!=G.onScreen) G.setScreen(panTo.name);
		}
	}
	G.setScreen('cookie');
	
//===========================================================================
//POPUPS
//===========================================================================
	G.popupL=l('popups');
	G.onPopup=0;
	G.popup=function(o)
	{
		if (o.replace) G.closePopup();
		G.particlesClear();
		let el=document.createElement('div');
		el.className='popup framed '+(o.introAnim||(G.getSet('lowMotion')?'':'fadeOpen'))+(o.classes?(' '+o.classes):'');
		if (o.style) el.style.cssText=o.style;
		el.innerHTML=(!o.classes || o.classes.indexOf('fullPopup')==-1?`<div class="doilyTrim" style="bottom:31px;"></div>`:``)+`<div `+(o.contentStyle?('style="'+o.contentStyle+'" '):'')+`class="popupContent">${o.text}</div>`+((o.close!=`[NONE]`)?(G.button({text:o.close||`Close`,classes:'bumpButton popupCloseButton',onclick:function(){PlaySound('snd/smallTick.mp3',1);G.closePopup(el);}})):``);
		G.popupL.appendChild(el);
		G.popupL.classList.add('on');
		if (o.func) o.func(el);
		G.addCallbacks();
		let els=document.querySelectorAll('.scrollTo');for (let i=0;i<els.length;i++){let el=els[i];el.classList.remove('scrollTo');el.scrollIntoView({behavior:'instant',block:'nearest',inline:'nearest'});}
		PlaySound('snd/press.mp3',0.15);
		G.onPopup=1;
		return el;
	}
	G.closeAllPopups=function()
	{
		G.popupL.classList.remove('on');
		G.popupL.innerHTML='';
		G.onPopup=0;
	}
	G.closePopup=function(el)
	{
		if (!el) el=G.popupL.lastChild;
		if (!el) return false;
		el.remove();
		if (G.popupL.childNodes.length==0) {G.popupL.classList.remove('on');G.onPopup=0;}
	}

//===========================================================================
//TOASTS
//===========================================================================
	G.toastL=l('toasts');
	G.pendingToasts=0;
	G.savedToasts=[];
	G.toast=function(title,top,icon,reverse)
	{
		//equivalent to Game.Notify
		//title is the main text in fancy font; top is smaller text added above it
		//if reverse is true, display top on bottom instead
		//if (G.pendingToasts>5) return false;
		let oldSeed=G.seed;
		let id=G.pendingToasts;
		setTimeout(function(){
			if (G.seed!=oldSeed) {G.pendingToasts--;return false;}
			if (G.toastL.children.length>5) {G.toastL.children[0].remove();}
			let el=document.createElement('div');
			el.className='toast '+((id%2==0)?'toast1':'toast2');
			
			var str='';
			
			if (title) title=`<div style="${(reverse && icon)?'padding-left:8px;':''}font-size:16px;font-family:Fancy;">${title}</div>`; else title='';
			if (top) top=`<div style="${(!reverse && icon)?'padding-left:8px;':''}">${top}</div>`; else top='';
			
			if (icon) str=`
				<div class="icon" style="display:inline-block;vertical-align:middle;background-position:${-icon[0]*48}px ${-icon[1]*48}px;margin-right:-4px;"></div>
				<div class="title">
					${reverse?title+top:top+title}
				</div>
			`;
			else str=`
				${reverse?title+top:top+title}
			`;
			el.innerHTML=str;
			G.toastL.appendChild(el);
			G.savedToasts.unshift([str,Date.now()]);
			if (G.savedToasts.length>50) G.savedToasts.pop();
			setTimeout(function(){if (el && document.body.contains(el)) {el.remove();}G.pendingToasts--;},3000);
		},Math.floor(id/2)*600+(id%2==0?0:100));
		G.pendingToasts++;
	}
	G.closeAllToasts=function()
	{
		while (G.toastL.firstChild) G.toastL.removeChild(G.toastL.firstChild);
	}
	
//===========================================================================
//WRINKLERS
//===========================================================================
	G.resetWrinklers=function(hard)
	{
		G.wrinklers=[];
		for (var i=0;i<14;i++)
		{
			G.wrinklers.push({id:parseInt(i),l:0,close:0,sucked:0,phase:0,x:0,y:0,r:0,s:0,clicks:0,hurt:0,hp:G.wrinklerHP,selected:0,type:0,seed:0});
		}
		G.cookiesSucked=0;//cookies sucked by wrinklers
		G.cpsSucked=0;//percent of CpS being sucked by wrinklers
		G.wrinklersPopped=0;
	}
		G.getWrinklersMax=function()
		{
			var n=10;
			if (G.Has('Elder spice')) n+=2;
			n+=Math.round(G.auraMult('Dragon Guts')*2);
			return n;
		}
		G.collectWrinklers=function()
		{
			for (var i=0;i<G.wrinklers.length;i++)
			{
				G.wrinklers[i].hp=0;
			}
		}
		let wrinklerSquishSound=Math.floor(Math.random()*4)+1;
		G.playWrinklerSquishSound=function()
		{
			PlaySound('snd/squish'+(wrinklerSquishSound)+'.mp3',0.35);
			wrinklerSquishSound+=Math.floor(Math.random()*1.5)+1;
			if (wrinklerSquishSound>4) wrinklerSquishSound-=4;
		}
		G.wrinklerHP=2.1;
		G.spawnWrinkler=function(me)
		{
			if (!me)
			{
				var max=G.getWrinklersMax();
				var n=0;
				for (var i=0;i<G.wrinklers.length;i++)
				{
					if (G.wrinklers[i].phase>0) n++;
				}
				for (var i=0;i<G.wrinklers.length;i++)
				{
					var it=G.wrinklers[i];
					if (it.phase==0 && G.elderWrath>0 && n<max && it.id<max)
					{
						me=it;
						break;
					}
				}
			}
			if (!me) return false;
			me.phase=1;
			me.hp=G.wrinklerHP;
			me.seed=Math.random();
			me.type=0;
			me.clicks=0;
			if (me.l) me.l.remove();
			me.l=0;
			if (Math.random()<0.0001) me.type=1;//shiny wrinkler
			return me;
		}
		G.PopRandomWrinkler=function()
		{
			var wrinklers=[];
			for (var i=0;i<G.wrinklers.length;i++)
			{
				if (G.wrinklers[i].phase>0 && G.wrinklers[i].hp>0) wrinklers.push(G.wrinklers[i]);
			}
			if (wrinklers.length>0)
			{
				var me=choose(wrinklers);
				me.hp=-10;
				return me;
			}
			return false;
		}
		G.clickWrinkler=function(me)
		{
			if (me.phase<=0) return false;
			//me.close*=0.99;
			if (G.powerClicksOn && G.powerClicks>=1)
			{
				G.spendPowerClick();
				PlaySound('snd/powerSquish'+choose([1,2,3])+'.mp3',0.6);
				PlaySound('snd/powerClick'+choose([1,2,3])+'b.mp3',0.7-Math.random()*0.3);
				me.hp-=100;
			}
			else
			{
				G.playWrinklerSquishSound();
				me.hp-=0.75;
			}
			me.hurt=1;
			me.clicks++;
			if (me.clicks>=50) G.win('Wrinkler poker');
			G.canPan=0;
			
			if (!G.getSet('notScary'))
			{
				G.particleAt({
					x:me.x,
					y:me.y,
					s:me.s,
					r:-me.r/Math.PI*180,
					rd:Math.random()*10-5,
					xd:Math.random()*4-2,
					yd:-Math.random()*3-2,
					pic:'wrinklerBits',
					cssText:'transform-origin:50% 10%;width:100px;height:200px;left:-50px;top:-10px;background:url(img/'+(me.type==1?'shinyWrinklerBits':'wrinklerBits')+'.png) '+(Math.floor(Math.random()*8)*100)+'px 0px;',
				});
			}
		}
	G.logicWrinklers=function(delta)
	{
		var xBase=0;
		var yBase=0;
		var onWrinkler=0;
		xBase=200;
		yBase=200;
		var max=G.getWrinklersMax();
		var n=0;
		for (var i=0;i<G.wrinklers.length;i++)
		{
			if (G.wrinklers[i].phase>0) n++;
		}
		for (var i=0;i<G.wrinklers.length;i++)
		{
			let me=G.wrinklers[i];
			if (me.phase==0 && G.elderWrath>0 && n<max && me.id<max)
			{
				var chance=0.00001*G.elderWrath*delta;//may be biased to always spawn a wrinkler if the delta is high enough
				if (G.Has('Unholy bait')) chance*=5;
				/*chance*=G.eff('wrinklerSpawn');
				
				if (G.hasGod)
				{
					var godLvl=G.hasGod('scorn');
					if (godLvl==1) chance*=2.5;
					else if (godLvl==2) chance*=2;
					else if (godLvl==3) chance*=1.5;
				}
				if (G.Has('Wrinkler doormat')) chance=0.1;*/
				if (Math.random()<chance)//respawn
				{
					G.spawnWrinkler(me);
					if (delta>=G.fps) {me.close=1;me.phase=2;G.refreshCps=1;}//delta over a second; we probably reloaded the app, so have the wrinkler fully spawned
				}
			}
			if (me.phase>0)
			{
				if (me.close<1) me.close+=((1/G.fps)/10)*delta;
				if (me.close>1) me.close=1;
				if (me.id>=max) me.hp=0;
			}
			else me.close=0;
			if (me.close==1 && me.phase==1)
			{
				me.phase=2;
				G.refreshCps=1;
			}
			if (me.phase==2)
			{
				me.sucked+=(((G.cookiesPs/G.fps)*G.cpsSucked))*delta;//suck the cookies
			}
			if (me.phase>0)
			{
				if (me.type==0)
				{
					if (me.hp<G.wrinklerHP) me.hp+=0.04;
					me.hp=Math.min(G.wrinklerHP,me.hp);
				}
				else if (me.type==1)
				{
					if (me.hp<G.wrinklerHP*3) me.hp+=0.04;
					me.hp=Math.min(G.wrinklerHP*3,me.hp);
				}
				
				if (Math.random()<0.01 && !G.getSet('notScary')) me.hurt=Math.max(me.hurt,Math.random());
				
				if (me.hurt>0) me.hurt-=delta/5;
			}
			me.hurt=Math.max(me.hurt,0);
			
			if (me.hp<=0.5 && me.phase>0)
			{
				G.playWrinklerSquishSound();
				PlaySound('snd/pop'+Math.floor(Math.random()*3+1)+'.mp3',0.75);
				G.wrinklersPopped++;
				G.refreshCps=1;
				me.phase=0;
				me.close=0;
				me.hurt=0;
				var powerKill=false;
				if (me.hp<=-90) powerKill=true;
				me.hp=G.wrinklerHP;
				var toSuck=1.1;
				if (G.Has('Sacrilegious corruption')) toSuck*=1.05;
				toSuck*=1+G.auraMult('Dragon Guts')*0.2;
				if (me.type==1) toSuck*=3;//shiny wrinklers are an elusive, profitable breed
				if (powerKill) toSuck*=1.2;
				me.sucked*=toSuck;//cookie dough does weird things inside wrinkler digestive tracts
				
				if (G.Has('Wrinklerspawn')) me.sucked*=1.05;
				if (G.hasGod)//todo
				{
					var godLvl=G.hasGod('scorn');
					if (godLvl==1) me.sucked*=1.15;
					else if (godLvl==2) me.sucked*=1.1;
					else if (godLvl==3) me.sucked*=1.05;
				}
				if (me.sucked>0.5)
				{
					G.toast(0,(powerKill?'Obliterated':'Exploded')+' a '+(me.type==1?'shiny ':'')+'wrinkler:<br>found '+B(me.sucked)+' cookies!',me.type==1?[24,12]:[19,8]);
					
					if (!G.HasUnlocked('Wrinkler ambergris') && Math.random()<1/(me.type==1?1000:10000))
					{
						G.unlock('Wrinkler ambergris');
						let upgrade=G.upgradesBN['Wrinkler ambergris'];
						G.toast(`<b>`+upgrade.name+`</b>`,`You found:`,upgrade.icon);
					}
					G.DropHalloween(me.type==1?0.9:0.95);
					G.DropEgg(0.98);
				}
				if (me.type==1) G.win('Last Chance to See');
				G.earn(me.sucked);
				if (!G.getSet('notScary'))
				{
					for (var ii=0;ii<8;ii++)
					{
						G.particleAt({
							x:me.x,
							y:me.y,
							s:me.s,
							r:-me.r/Math.PI*180,
							rd:Math.random()*10-5,
							xd:(Math.random()*4-2)*(powerKill?3:1),
							yd:(-Math.random()*3-2)*(powerKill?3:1),
							pic:'wrinklerBits',
							cssText:'transform-origin:50% 10%;width:100px;height:200px;left:-50px;top:-10px;background:url(img/'+(me.type==1?'shinyWrinklerBits':'wrinklerBits')+'.png) '+(ii*100)+'px 0px;',
						});
					}
				}
				me.sucked=0;
			}
		}
		
		if (G.cpsSucked>0)
		{
			var cookies=(G.cookiesPs/G.fps)*G.cpsSucked*delta;
			G.dissolve(cookies);
			G.cookiesSucked+=cookies;
		}
	}
	
	let wrinklersPosX=-1000;
	let wrinklersPosY=-1000;
	G.drawWrinklers=function(parent,fromX,fromY)
	{
		if (!G.wrinklers) return false;
		if (G.explodeT>-1) return false;
		if (wrinklersPosX==-1000) {wrinklersPosX=fromX;wrinklersPosY=fromY;};
		wrinklersPosX+=(fromX-wrinklersPosX)*0.2;
		wrinklersPosY+=(fromY-wrinklersPosY)*0.2;
		for (var i=0;i<G.wrinklers.length;i++)
		{
			let me=G.wrinklers[i];
			if (me.phase==0) me.hp=0;
			if (me.hp<=0 && me.l)
			{
				me.l.remove();
				me.l=0;
			}
			else if (me.hp>0 && !me.l)
			{
				me.l=document.createElement('div');
				me.l.className='wrinkler'+(G.getSet('notScary')?' googly':'');
				if (G.season=='christmas') me.l.style.backgroundImage='url(img/winterWrinkler.png)';
				if (me.type==1) me.l.style.backgroundImage='url(img/shinyWrinkler.png)';
				parent.appendChild(me.l);
				G.ondown(me.l,function(){G.clickWrinkler(me);});
			}
			else if (me.hp>0 && me.l)
			{
				var seed=me.seed;
				var d=110;
				var r=(i/11+0.25)*0.35;
				if (G.getSet('fancy'))
				{
					d+=Math.sin(seed*741+37+G.T*(0.02+Math.sin(seed*4.17)*0.01))*5+100*(1-me.close);
					r+=0.005*Math.sin(seed*3.7+0.3+G.T*(0.03+Math.sin(seed*0.91)*0.02));
				}
				r*=Math.PI*2;
				var x=wrinklersPosX+Math.sin(r)*d;
				var y=wrinklersPosY+Math.cos(r)*d-30;
				var s=0.25+0.1*Math.sin(seed);
				me.x=x;
				me.y=y;
				me.r=r;
				me.s=s;
				if (G.getSet('notScary') && Math.sin(G.T*0.003+i*11+137+Math.sin(G.T*0.017+i*13))>0.9997) me.l.classList.add('blinky'); else me.l.classList.remove('blinky');
				me.l.style.transform=`translate(${x-50}px,${y-10}px) rotate(${-r/Math.PI/2*360+me.hurt*(Math.sin(G.T*1+seed*97))*18}deg) scale(${s},${s})`;//unsure why we need 50 on x
				me.l.style.opacity=me.close;
				if (!G.onPopup && Math.random()<0.01 && me.phase>1) G.cookiePop(x,y,0.25);
				//me.l.innerHTML='<div style="text-align:left;padding-left:25px;position:absolute;left:0px;top:0px;z-index:1000;font-size:30px;font-weight:bold;transform:rotate(90deg);">'+Math.floor(me.sucked)+'</div>';
			}
		}
	}
	G.undrawWrinklers=function()
	{
		for (var i=0;i<G.wrinklers.length;i++)
		{
			let me=G.wrinklers[i];
			if (me.l) me.l.remove();
			me.l=0;
		}
	}
	G.saveWrinklers=function()
	{
		var o=[];
		for (var i=0;i<G.wrinklers.length;i++)
		{
			var it=G.wrinklers[i];
			o[i]={s:it.sucked,t:it.type};
		}
		return o;
		/*
		var amount=0;
		var amountShinies=0;
		var n=0;
		var shinies=0;
		for (var i in G.wrinklers)
		{
			if (G.wrinklers[i].sucked>0.5)
			{
				n++;
				if (G.wrinklers[i].type==1)
				{
					shinies++;
					amountShinies+=G.wrinklers[i].sucked;
				}
				else amount+=G.wrinklers[i].sucked;
			}
		}
		return {amount:amount,n:n,shinies:shinies,amountShinies:amountShinies};
		*/
	}
	G.loadWrinklers=function(o,version)
	{
		if (!o) return false;
		if (version<6)
		{
			if (o.n>0 && (o.amount>0 || o.amountShinies>0))
			{
				var fullNumber=o.n-o.shinies;
				var fullNumberShinies=o.shinies;
				for (var i in G.wrinklers)
				{
					if (o.n>0)
					{
						var me=G.wrinklers[i];
						me.phase=2;
						me.close=1;
						me.hp=G.wrinklerHP;
						me.seed=Math.random();
						if (me.l) me.l.remove();
						me.l=0;
						me.type=0;
						if (o.shinies>0) {me.type=1;me.sucked=o.amountShinies/fullNumberShinies;o.shinies--;}
						else me.sucked=o.amount/fullNumber;
						o.n--;
					}//respawn
				}
			}
		}
		else
		{
			for (var i=0;i<G.wrinklers.length;i++)
			{
				var it=G.wrinklers[i];
				if (o[i])
				{
					it.sucked=parseFloat(o[i].s);
					if (it.sucked>0)
					{
						it.phase=2;
						it.close=1;
						it.hp=G.wrinklerHP;
						it.seed=Math.random();
						if (it.l) it.l.remove();
						it.l=0;
						it.type=parseInt(o[i].t);
					}
				}
			}
		}
	}
	
//===========================================================================
//PETS (dragon, santa...)
//===========================================================================
	G.santaLevel=0;
	
	G.dragonLevel=0;
	G.dragonAura=0;
	G.dragonAura2=0;
	
	G.resetPets=function(hard)
	{
		G.santaLevel=0;
		
		G.dragonLevel=0;
		G.dragonAura=0;
		G.dragonAura2=0;
	}
	
	G.pets={
		'santa':{
		},
		'dragon':{
		},
	};
	
	
	//santa
	G.santaLevels=['Festive test tube','Festive ornament','Festive wreath','Festive tree','Festive present','Festive elf fetus','Elf toddler','Elfling','Young elf','Bulky elf','Nick','Santa Claus','Elder Santa','True Santa','Final Claus'];
	
	G.santaPopup=function(justUpgraded)
	{
		let str=``;
		str+=`<h3>${G.iconSmall(19,9)} ${G.santaLevels[G.santaLevel]}</h3>`;
		str+=`<div class="debugOnly" style="text-align:center;">`+G.button({text:'Reset level',classes:'bumpButton',onclick:function(){G.santaLevel=0;G.UpgradedSanta();G.closePopup();G.santaPopup(true);}})+G.button({text:'Max level',classes:'bumpButton',onclick:function(){G.santaLevel=14;G.UpgradedSanta();G.closePopup();G.santaPopup(true);}})+`</div>`;
		if (G.santaLevel==G.santaLevels.length-1) str+=`<div style="text-align:center;padding:4px;font-size:80%;">Fully evolved.</div><line></line>`;
		var moni=G.SantaUpgradeCost();
		for (var i=G.santaLevel;i>=0;i--)
		{
			var active=i==G.santaLevel;
			str+=G.button({text:`
				<div class="listing${active?' active scrollTo':''}${(active && justUpgraded===true)?' switchLeftIn':''}" style="padding-left:48px;">
					<div class="hasShadedBackdrop" style="position:absolute;left:0px;width:96px;height:96px;transform:scale(0.5);">
						<div style="width:96px;height:96px;background:url(img/santa.png);background-position:${-96*i}px 0px;"></div>
					</div>
					
					<div style="flex-grow:1;">
						<div class="name printText" style="font-size:13px;">${G.santaLevels[i]}</div>
						`+((active && G.santaLevel<G.santaLevels.length-1)?`<div class="desc" style="font-weight:bold;">Evolve!</div><div style="text-align:center;padding:2px;font-weight:bold;font-size:80%;">Sacrifice <span class="cost${G.cookies<moni?' cantAfford':''}">${B(moni)} cookie${moni==1?'':'s'}</span></div>`:'')+`
					</div>
				</div>
			`,classes:'bumpButton',style:'padding:0px;width:100%;margin:0px;font-weight:normal;'+(active?'':'box-shadow:none;'),onclick:active?function(){
				if (G.UpgradeSanta())
				{
					G.closePopup();G.santaPopup(true);
				}
			}:0});
		}
		G.popup({text:str,close:`Close`});
	}
	
	G.SantaUpgradeCost=function()
	{
		return Math.pow(G.santaLevel+1,G.santaLevel+1)*(1+0.01*G.prestige);
	}
	G.UpgradeSanta=function()
	{
		if (G.santaLevel>=14) return false;
		var moni=G.SantaUpgradeCost();
		if (G.cookies<moni) return false;
		
		PlaySound('snd/shimmerClick.mp3');
		
		G.spend(moni);
		G.santaLevel=(G.santaLevel+1)%15;
		if (G.santaLevel==14)
		{
			G.unlock('Santa\'s dominion');
			G.toast(`You are granted Santa's dominion.`,'',G.upgradesBN['Santa\'s dominion'].icon);
		}
		G.DropSanta();
		
		G.UpgradedSanta();
		
		return true;
	}
	G.UpgradedSanta=function()
	{
		if (l('petSantaPic')) l('petSantaPic').style.backgroundPosition=`${-96*G.santaLevel}px 0px`;
		if (l('petSantaName')) l('petSantaName').innerHTML=`${G.santaLevels[G.santaLevel]}`;
		
		if (G.santaLevel>=6) G.win('Coming to town');
		if (G.santaLevel>=14) G.win('All hail Santa');
		
		G.refreshCps=1;
		G.doUnlocks();
	}
	
	
	//dragon
	G.dragonLevels=[
		{name:'Dragon egg',action:`Chip it`,pic:0,
			cost:function(){return G.cookies>=1000000;},
			buy:function(){G.spend(1000000);},
			costStr:function(){return B(1000000)+' cookies';}},
		{name:'Dragon egg',action:`Chip it`,pic:1,
			cost:function(){return G.cookies>=1000000*2;},
			buy:function(){G.spend(1000000*2);},
			costStr:function(){return B(1000000*2)+' cookies';}},
		{name:'Dragon egg',action:`Chip it`,pic:2,
			cost:function(){return G.cookies>=1000000*4;},
			buy:function(){G.spend(1000000*4);},
			costStr:function(){return B(1000000*4)+' cookies';}},
		{name:'Shivering dragon egg',action:`Hatch it`,pic:3,
			cost:function(){return G.cookies>=1000000*8;},
			buy:function(){G.spend(1000000*8);},
			costStr:function(){return B(1000000*8)+' cookies';}},
		{name:'Krumblor, cookie hatchling',action:'Train Breath of Milk<br><small>Aura: kittens are 5% more effective</small>',pic:4,
			cost:function(){return G.cookies>=1000000*16;},
			buy:function(){G.spend(1000000*16);},
			costStr:function(){return B(1000000*16)+' cookies';}},
		{name:'Krumblor, cookie hatchling',action:'Train Dragon Cursor<br><small>Aura: enhanced power clicks; clicking is 5% more effective</small>',pic:4,},
		{name:'Krumblor, cookie hatchling',action:'Train Elder Battalion<br><small>Aura: grandmas gain +1% CpS for every non-grandma building</small>',pic:4,},
		{name:'Krumblor, cookie hatchling',action:'Train Reaper of Fields<br><small>Aura: golden cookies may trigger a Dragon Harvest</small>',pic:4,},
		{name:'Krumblor, cookie dragon',action:'Train Earth Shatterer<br><small>Aura: buildings sell back for 50% instead of 25%</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Master of the Armory<br><small>Aura: all upgrades are 2% cheaper</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Fierce Hoarder<br><small>Aura: all buildings are 2% cheaper</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Dragon God<br><small>Aura: prestige CpS bonus +5%</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Arcane Aura<br><small>Aura: golden cookies appear 5% more often</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Dragonflight<br><small>Aura: golden cookies may trigger a Dragonflight</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Ancestral Metamorphosis<br><small>Aura: golden cookies give 10% more cookies</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Unholy Dominion<br><small>Aura: wrath cookies give 10% more cookies</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Epoch Manipulator<br><small>Aura: golden cookie effects last 5% longer</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Mind Over Matter<br><small>Aura: +25% random drops</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Radiant Appetite<br><small>Aura: all cookie production multiplied by 2</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Dragon\'s Fortune<br><small>Aura: +123% CpS per golden cookie on-screen</small>',pic:5,},
		//{name:'Krumblor, cookie dragon',action:'Train Dragon\'s Curve<br><small>Aura: sugar lumps grow 5% faster, 50% weirder</small>',pic:5,},
			{name:'Krumblor, cookie dragon',action:'Train Dragon\'s Curve<br><small>Unlocks 2 dragon upgrades</small>',pic:5,drop:1,},
		{name:'Krumblor, cookie dragon',action:'Train Reality Bending<br><small>Aura: 10% of every other aura, combined</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Train Dragon Orbs<br><small>Aura: selling your best building may grant a wish</small>',pic:5,},
		//{name:'Krumblor, cookie dragon',action:'Train Supreme Intellect<br><small>Aura: confers various powers to your minigames</small>',pic:5,},
			{name:'Krumblor, cookie dragon',action:'Train Supreme Intellect<br><small>Unlocks 2 dragon upgrades</small>',pic:5,drop:1,},
		{name:'Krumblor, cookie dragon',action:'Train Dragon Guts<br><small>Aura: enhanced wrinklers</small>',pic:5,},
		{name:'Krumblor, cookie dragon',action:'Bake dragon cookie<br><small>Delicious!</small>',pic:6,
			cost:function(){var fail=0;for (var i in G.buildings){if (G.buildings[i].amount<50) fail=1;}return (fail==0);},
			buy:function(){for (var i in G.buildings){G.buildings[i].sacrifice(50);}G.unlock('Dragon cookie');},
			costStr:function(){return `50 of every building`;}},
		{name:'Krumblor, cookie dragon',action:'Train secondary aura<br><small>Lets you use two dragon auras simultaneously</small>',pic:7,
			cost:function(){var fail=0;for (var i in G.buildings){if (G.buildings[i].amount<200) fail=1;}return (fail==0);},
			buy:function(){for (var i in G.buildings){G.buildings[i].sacrifice(200);}},
			costStr:function(){return `200 of every building`;}},
		{name:'Krumblor, cookie dragon',action:`Your dragon is fully trained.`,pic:8}
	];
	
	G.dragonAuras={
		0:{name:'No aura',pic:[0,7],desc:("")},
		1:{name:'Breath of Milk',pic:[18,25],desc:("Kittens are <b>5%</b> more effective.")},
		2:{name:'Dragon Cursor',pic:[0,25],desc:("Clicking is <b>5%</b> more powerful.<br><b>+5</b> max power clicks.<br>Power click effects <b>+5%</b>.")},
		3:{name:'Elder Battalion',pic:[1,25],desc:("Grandmas gain <b>+1% CpS</b> for each non-grandma building.")},
		4:{name:'Reaper of Fields',pic:[2,25],desc:("Golden cookies may trigger a <b>Dragon Harvest</b>.")},
		5:{name:'Earth Shatterer',pic:[3,25],desc:("Buildings sell back for <b>50%</b> instead of 25%.")},
		6:{name:'Master of the Armory',pic:[4,25],desc:("All upgrades are <b>2% cheaper</b>.")},
		7:{name:'Fierce Hoarder',pic:[15,25],desc:("All buildings are <b>2% cheaper</b>.")},
		8:{name:'Dragon God',pic:[16,25],desc:("<b>+5%</b> prestige level effect on CpS.")},
		9:{name:'Arcane Aura',pic:[17,25],desc:("Golden cookies appear <b>5%</b> more often.")},
		10:{name:'Dragonflight',pic:[5,25],desc:("Golden cookies may trigger a <b>Dragonflight</b>.")},
		11:{name:'Ancestral Metamorphosis',pic:[6,25],desc:("Golden cookies give <b>10%</b> more cookies.")},
		12:{name:'Unholy Dominion',pic:[7,25],desc:("Wrath cookies give <b>10%</b> more cookies.")},
		13:{name:'Epoch Manipulator',pic:[8,25],desc:("Golden cookies stay <b>5%</b> longer.")},
		14:{name:'Mind Over Matter',pic:[13,25],desc:("Random drops are <b>25% more common</b>.")},
		15:{name:'Radiant Appetite',pic:[14,25],desc:("All cookie production <b>multiplied by 2</b>.")},
		16:{name:'Dragon\'s Fortune',pic:[19,25],desc:("<b>+123% CpS</b> per golden cookie on-screen, multiplicative.")},
		17:{name:'Dragon\'s Curve',pic:[20,25],desc:("<b>+5%</b> sugar lump growth. Sugar lumps are <b>twice as likely</b> to be unusual."),drop:1},
		18:{name:'Reality Bending',pic:[32,25],desc:("<b>One tenth</b> of every other dragon aura, <b>combined</b>.")},
		19:{name:'Dragon Orbs',pic:[33,25],desc:("With no buffs and no golden cookies on screen, selling your most powerful building has <b>10% chance to summon one</b>.")},
		20:{name:'Supreme Intellect',pic:[34,25],desc:("Confers various powers to your minigames while active.<br>See the bottom of each minigame for more details."),drop:1},
		21:{name:'Dragon Guts',pic:[35,25],desc:("You can attract <b>2 more wrinklers</b>.<br>Wrinklers digest <b>20% more cookies</b>.<br>Wrinklers explode into <b>20% more cookies</b>.")},
	};
	
	G.dragonAurasBN={};for (var i in G.dragonAuras){G.dragonAurasBN[G.dragonAuras[i].name]=G.dragonAuras[i];}
	for (var i in G.dragonAuras){G.dragonAuras[i].id=parseInt(i);}
	
	G.addPostData(()=>{
		for (var i=0;i<G.dragonLevels.length;i++)
		{
			var it=G.dragonLevels[i];
			if (i>=4 && i<G.dragonLevels.length-3)
			{
				if (i>=5)
				{
					it.costStr=function(building){return function(){return ("100 "+building.plural);}}(G.buildings[i-5]);
					it.cost=function(building){return function(){return building.amount>=100;}}(G.buildings[i-5]);
					it.buy=function(building){return function(){building.sacrifice(100);}}(G.buildings[i-5]);
				}
			}
		}
	});
	
	G.UpgradeDragon=function()
	{
		if (G.dragonLevel>=G.dragonLevels.length-1) return false;
		let currentLevel=G.dragonLevels[G.dragonLevel];
		let canAffordFunc=currentLevel.cost;
		if (!canAffordFunc()) return false;
		
		currentLevel.buy();
		
		PlaySound('snd/shimmerClick.mp3');
		
		G.dragonLevel=(G.dragonLevel+1)%G.dragonLevels.length;
		if (G.dragonLevel==G.dragonLevels.length-1)
		{
			G.win('Here be dragon');
		}
		
		if (currentLevel.drop)
		{
			//temporary: until we add dragon petting and the features these auras depend on (minigames, lumps)
			var allDrops=['Dragon scale','Dragon claw','Dragon fang','Dragon teddy bear'];
			for (var ii=0;ii<2;ii++)
			{
				var drops=[];
				for (var i in allDrops) {if (!G.isUnlocked(allDrops[i])) drops.push(allDrops[i]);}
				var drop=choose(drops);
				if (drop)
				{
					G.unlock(drop);
					G.toast(`<b>`+G.upgradesBN[drop].name+`</b>!`,`The dragon gives you:`,G.upgradesBN[drop].icon);
				}
			}
		}
		
		G.UpgradedDragon();
		
		return true;
	}
	G.UpgradedDragon=function()
	{
		if (l('petDragonPic')) l('petDragonPic').style.backgroundPosition=`${-96*G.dragonLevels[G.dragonLevel].pic}px 0px`;
		if (l('petDragonName')) l('petDragonName').innerHTML=`${G.dragonLevels[G.dragonLevel].name}`;
		
		G.refreshCps=1;
		G.doUnlocks();
	}
	
	G.hasAura=function(what)
	{
		if (G.dragonAuras[G.dragonAura].name==what || G.dragonAuras[G.dragonAura2].name==what) return true; else return false;
	}
	G.auraMult=function(what)
	{
		var n=0;
		if (G.dragonAuras[G.dragonAura].name==what || G.dragonAuras[G.dragonAura2].name==what) n=1;
		if ((G.dragonAuras[G.dragonAura].name=='Reality Bending' || G.dragonAuras[G.dragonAura2].name=='Reality Bending') && G.dragonLevel>=G.dragonAurasBN[what].id+4) n+=0.1;
		return n;
	}
	
	G.SelectDragonAura=function(slot)
	{
		let currentAura=0;
		let otherAura=0;
		if (slot==0) {currentAura=G.dragonAura;otherAura=G.dragonAura2;} else {currentAura=G.dragonAura2;otherAura=G.dragonAura;}
		
		let currentAuraObj=G.dragonAuras[currentAura];
		
		var highestBuilding=0;
		for (var i in G.buildings) {if (G.buildings[i].amount>0) highestBuilding=G.buildings[i];}
		
		var str='';
		str+=`<h3>${G.iconSmall(21,12)} Set your dragon's ${slot==1?'secondary ':''}aura</h3>`;
		str+=`<div style="text-align:center;padding:4px;font-size:80%;">
			Select an aura from those your dragon knows.<br><br>
			${highestBuilding==0?'Switching your aura is <b>free</b> because you own no buildings.':('The cost of switching your aura is <b class="cost otherCost">1 '+highestBuilding.single+'</b>.<br><b class="warning">This will affect your CpS!</b>')}
		</div>`;
		str+=`<div style="text-align:center;padding:4px;font-size:80%;"><span style="margin-right:12px;">Current:</span> ${G.iconSmall(currentAuraObj.pic[0],currentAuraObj.pic[1])} <b>${currentAuraObj.name}</b></div>`;
		str+=`<line></line>`;
		
		let list=[];
		let listSeason={};
		for (var i in G.dragonAuras){
			let it=G.dragonAuras[i];
			if (it.drop || G.dragonLevel<it.id+4 || (it.id!=0 && it.id==otherAura)) continue;
			list.push(it);
		}
		let renderMe=(me)=>
		{
			let detailStr=``;
			let col='255,255,255';
			let icon=me.pic;
			
			let active=false;
			
			if (currentAura==me.id) active=true;
			
			if (active)
			{
				col='167,10,249';
			}
			else
			{
				col='176,109,73';
			}
			
			return G.button({text:`
				<div class="listing${active?' active scrollTo':''}" style="padding-left:48px;background:linear-gradient(to bottom,rgba(${col},0.2) 0%,rgba(${col},0.1) 100%);">
					<div class="icon" style="position:absolute;left:0px;background-position:${-icon[0]*48}px ${-icon[1]*48}px;"></div>
					<div style="flex-grow:1;">
						<div class="name fancy" style="font-size:13px;">${me.name}</div>
						${me.desc?('<div class="desc" style="padding:4px;">'+me.desc+'</div>'):''}${detailStr?('<div style="text-align:center;padding:2px;font-weight:bold;font-size:80%;">'+detailStr+'</div>'):''}
					</div>
				</div>
			`,classes:'bumpButton',style:'padding:0px;width:100%;margin:0px;font-weight:normal;',onclick:function(){
				if (currentAura==me.id) return;
				if (slot==0) G.dragonAura=me.id;
				else if (slot==1) G.dragonAura2=me.id;
				if (l('dragonAuraSlot'+slot)) {l('dragonAuraSlot'+slot).style.backgroundPosition=`${-48*me.pic[0]}px ${-48*me.pic[1]}px`;G.sparkleOn(l('dragonAuraSlot'+slot));}
				var highestBuilding=0;
				for (var i in G.buildings) {if (G.buildings[i].amount>0) highestBuilding=G.buildings[i];}
				if (highestBuilding && currentAura!=me.id) highestBuilding.sacrifice(1);
				G.refreshCps=1;
				PlaySound('snd/thud.mp3',0.5);
				PlaySound('snd/tick.mp3',0.5);
				G.closePopup();
			}});
		};
		for (var i=0;i<list.length;i++)
		{
			str+=renderMe(list[i]);
		}
		
		G.popup({text:str,close:`Cancel`});
	}
	
	G.dragonPopup=function(justUpgraded)
	{
		let str=``;
		str+=`<h3>${G.iconSmall(21,12)} ${G.dragonLevels[G.dragonLevel].name}</h3>`;
		str+=`<div class="debugOnly" style="text-align:center;">`+G.button({text:'Reset level',classes:'bumpButton',onclick:function(){G.dragonLevel=0;G.UpgradedDragon();G.closePopup();G.dragonPopup(true);}})+G.button({text:'Max level',classes:'bumpButton',onclick:function(){G.dragonLevel=G.dragonLevels.length-1;G.UpgradedDragon();G.closePopup();G.dragonPopup(true);}})+`</div>`;
		if (G.dragonLevel>=5)
		{
			str+=`<div style="text-align:center;padding:4px;font-size:80%;">
				<b>Aura${(G.dragonLevel==G.dragonLevels.length-1)?'s':''}:</b><br>`+
				G.visualButton({icon:G.dragonAuras[G.dragonAura].pic,id:'dragonAuraSlot0',onclick:()=>{G.SelectDragonAura(0);}})+
				((G.dragonLevel==G.dragonLevels.length-1)?G.visualButton({icon:G.dragonAuras[G.dragonAura2].pic,id:'dragonAuraSlot1',onclick:()=>{G.SelectDragonAura(1);}}):'')+
				`
			</div><line></line>`;
		}
		let currentLevel=G.dragonLevels[G.dragonLevel];
		let mainLevels=[0,4,8,G.dragonLevels.length-3,G.dragonLevels.length-2,G.dragonLevels.length-1];
		for (var i=G.dragonLevel;i>=0;i--)
		{
			var active=i==G.dragonLevel;
			let level=G.dragonLevels[i];
			if (!active && (mainLevels.indexOf(i)==-1 || currentLevel.pic==level.pic)) continue;
			str+=G.button({text:`
				<div class="listing${active?' active scrollTo':''}${(active && justUpgraded===true)?' switchLeftIn':''}" style="padding-left:64px;">
					<div class="hasShadedBackdrop" style="position:absolute;left:0px;width:96px;height:96px;transform:scale(0.5);">
						<div style="width:96px;height:96px;background:url(img/dragon.png);background-position:${-96*level.pic}px 0px;"></div>
					</div>
					
					<div style="flex-grow:1;">
						<div class="name printText" style="font-size:13px;">${level.name}</div>
						`+((active && G.dragonLevel<G.dragonLevels.length-1)?`
						<line></line>
						<div class="desc" style="font-weight:bold;">${level.action}</div>
						<line></line>
						<div style="text-align:center;padding:2px;font-weight:bold;font-size:80%;">Cost: sacrifice <span class="cost${i>4?' otherCost':''}${!level.cost()?' cantAfford':''}">${level.costStr()}</span></div>`:(i==G.dragonLevels.length-1)?`<div class="desc" style="font-size:80%;">Fully trained.</div>`:'')+`
					</div>
				</div>
			`,classes:'bumpButton',style:'padding:0px;width:100%;margin:0px;font-weight:normal;'+(active?'':'box-shadow:none;'),onclick:active?function(){
				if (G.UpgradeDragon())
				{
					G.closePopup();G.dragonPopup(true);
				}
			}:0});
		}
		G.popup({text:str,close:`Close`});
	}
//===========================================================================
//SEASONS
//===========================================================================
	G.baseSeason='';//halloween, christmas, valentines, fools, easter
	//automatic season detection (might not be 100% accurate)
	G.getBaseSeason=function(date)
	{
		let season='';
		date=typeof date!=='undefined'?date:new Date();
		var year=date.getFullYear();
		var leap=(((year%4==0)&&(year%100!=0))||(year%400==0))?1:0;
		var day=Math.floor((date-new Date(year,0,0))/(1000*60*60*24));
		if (day>=41 && day<=46) season='valentines';
		else if (day+leap>=90 && day<=92+leap) season='fools';
		else if (day>=304-7+leap && day<=304+leap) season='halloween';
		else if (day>=349+leap && day<=365+leap) season='christmas';
		else
		{
			//easter is a pain goddamn
			var easterDay=function(Y){var C = Math.floor(Y/100);var N = Y - 19*Math.floor(Y/19);var K = Math.floor((C - 17)/25);var I = C - Math.floor(C/4) - Math.floor((C - K)/3) + 19*N + 15;I = I - 30*Math.floor((I/30));I = I - Math.floor(I/28)*(1 - Math.floor(I/28)*Math.floor(29/(I + 1))*Math.floor((21 - N)/11));var J = Y + Math.floor(Y/4) + I + 2 - C + Math.floor(C/4);J = J - 7*Math.floor(J/7);var L = I - J;var M = 3 + Math.floor((L + 40)/44);var D = L + 28 - 31*Math.floor(M/4);return new Date(Y,M-1,D);}(year);
			easterDay=Math.floor((easterDay-new Date(easterDay.getFullYear(),0,0))/(1000*60*60*24));
			if (day>=easterDay-7 && day<=easterDay) season='easter';
		}
		return season;
	}
	G.baseSeason=G.getBaseSeason();
	
	G.seasonT=0;//date the manually-triggered season ends
	G.seasonUses=0;//season switcher uses
	G.season=G.baseSeason;//can be overridden by season switcher
		
	G.resetSeasonData=function(hard)
	{
		G.season=G.baseSeason;
		G.seasonT=0;
		G.seasonUses=0;
		G.computeSeasonPrices();
	}
	
	G.seasons={
		'christmas':{name:'Christmas',start:'Christmas season has started!',over:'Christmas season is over.',trigger:'Festive biscuit'},
		'valentines':{name:'Valentine\'s day',start:'Valentine\'s day has started!',over:'Valentine\'s day is over.',trigger:'Lovesick biscuit'},
		'fools':{name:'Business day',start:'Business day has started!',over:'Business day is over.',trigger:'Fool\'s biscuit'},
		'easter':{name:'Easter',start:'Easter season has started!',over:'Easter season is over.',trigger:'Bunny biscuit'},
		'halloween':{name:'Halloween',start:'Halloween has started!',over:'Halloween is over.',trigger:'Ghostly biscuit'}
	};
	
	G.seasonSwitcherPopup=function(){
		var str='';
		
		let list=[];
		let listSeason={};
		for (var i in G.seasons){list.push(G.seasons[i].triggerUpgrade);listSeason[G.seasons[i].trigger]=i;}
		let renderMe=(me)=>
		{
			let detailStr=``;
			let col='255,255,255';
			let icon=me.iconFunc?me.iconFunc():me.icon;
			
			let active=false;
			
			if (G.seasonT>0 && G.season!='' && G.seasons[G.season].trigger==me.name) active=true;
			
			if (active)
			{
				col='167,10,249';
				detailStr=`Active! Tap to cancel.`;
			}
			else
			{
				col='176,109,73';
				detailStr=`Trigger for `+G.selfUpdatingText(e=>{var cost=me.getCost();return `<span class="cost${cost>G.cookies?' cantAfford':''}" style="padding:4px;">${B(cost)}</span>.`;});
			}
			
			
			return G.button({text:`
				<div class="listing${active?' active scrollTo':''}" style="padding-left:48px;background:linear-gradient(to bottom,rgba(${col},0.2) 0%,rgba(${col},0.1) 100%);">
					<div class="icon" style="position:absolute;left:0px;background-position:${-icon[0]*48}px ${-icon[1]*48}px;"></div>
					<div style="flex-grow:1;">
						<div class="name fancy" style="font-size:13px;">${me.name}</div>
						<div class="desc" style="padding:4px;">${me.descFunc?me.descFunc():me.desc}</div><div style="text-align:center;padding:2px;font-weight:bold;font-size:80%;">${detailStr}</div>
					</div>
				</div>
			`,classes:'bumpButton',style:'padding:0px;width:100%;margin:0px;font-weight:normal;',onclick:function(){
				if (G.seasonT>0 && G.season!='' && G.seasons[G.season].trigger==me.name)
				{
					G.switchSeason();
					G.refreshCps=1;
					PlaySound('snd/thud.mp3',0.5);
					G.doUnlocks();
					G.closePopup();G.seasonSwitcherPopup();
				}
				else
				{
					var cost=me.getCost();
					if (cost>G.cookies) {}
					else
					{
						G.switchSeason();
						G.switchSeason(listSeason[me.name]);
						G.seasonUses++;
						G.spend(cost);
						G.computeSeasonPrices();
						G.refreshCps=1;
						PlaySound('snd/thud.mp3',0.5);
						G.doUnlocks();
						G.closePopup();G.seasonSwitcherPopup();
					}
				}
			}});
		};
		
		str+=`<h3>${G.iconSmall(16,6)} Season switcher</h3>`;
		str+=`<div style="text-align:center;padding:4px;font-size:80%;">Change seasons at any time... for a price!<br>Each triggered season lasts for 24 hours.<br>Cost scales with unbuffed CpS and increases with every season switch. ${(G.seasonUses==0)?'You haven\'t switched seasons this ascension yet.':'You\'ve switched seasons <b>'+(G.seasonUses==1?'once':G.seasonUses==2?'twice':(G.seasonUses+' times'))+'</b> this ascension.'} Cancelling out of a season is free.</div>`;
		str+=`<line></line>`;
		
		for (var i=0;i<list.length;i++)
		{
			str+=renderMe(list[i]);
		}
		
		G.popup({text:str,close:`Close`});
	};
	
	G.seasonTriggerBasePrice=1000000000;
	G.computeSeasonPrices=function()
	{
		for (var i in G.seasons)
		{
			G.seasons[i].triggerUpgrade.costFunc=function(){
				var m=1;
				if (G.hasGod)//todo
				{
					var godLvl=G.hasGod('seasons');
					if (godLvl==1) m*=2;
					else if (godLvl==2) m*=1.50;
					else if (godLvl==3) m*=1.25;
				}
				return G.seasonTriggerBasePrice+G.cookiesPsUnbuffed*60*Math.pow(1.5,G.seasonUses)*m;
			}
		}
	}
	G.computeSeasons=function()
	{
		for (var i in G.seasons)
		{
			var me=G.upgradesBN[G.seasons[i].trigger];
			G.seasons[i].triggerUpgrade=me;
			me.pool='toggle';
		}
	}
	G.getSeasonDuration=function(){return 60*60*24*1000;}//duration of a manually-triggered season (24 hours)
	G.switchSeason=function(season)
	{
		if (!season)
		{
			if (G.season!='') G.toast(G.seasons[G.season].over,0,G.seasons[G.season].triggerUpgrade.icon);
			G.season='';
			G.seasonT=0;
		}
		else
		{
			if (G.season!=season) G.toast(G.seasons[season].start,0,G.seasons[season].triggerUpgrade.icon);
			G.season=season;
			G.seasonT=Date.now()+G.getSeasonDuration();
		}
	}
	G.lastSeasonCheck=0;
	G.logicSeasons=function(delta)
	{
		var prevSeason=G.season;
		if (Date.now()>=G.lastSeasonCheck+1000*60)
		{
			//update base season every minute
			G.baseSeason=G.getBaseSeason();
			if (G.season=='') G.season=G.baseSeason;
			G.lastSeasonCheck=Date.now();
		}
		
		if (G.season!='' && G.season!=G.baseSeason && G.seasonT<=Date.now())
		{
			G.toast(G.seasons[G.season].over,0,G.seasons[G.season].triggerUpgrade.icon);
			G.season=G.baseSeason;
			G.seasonT=0;
		}
		if (prevSeason!=G.season && G.season!='')
		{
			G.toast(G.seasons[G.season].start,0,G.seasons[G.season].triggerUpgrade.icon);
		}
	}
	
	
	
	G.santaDrops=['Increased merriness','Improved jolliness','A lump of coal','An itchy sweater','Reindeer baking grounds','Weighted sleighs','Ho ho ho-flavored frosting','Season savings','Toy workshop','Naughty list','Santa\'s bottomless bag','Santa\'s helpers','Santa\'s legacy','Santa\'s milk and cookies'];
	
	G.GetHowManySantaDrops=function()
	{
		var num=0;
		for (var i in G.santaDrops) {if (G.isUnlocked(G.santaDrops[i])) num++;}
		return num;
	}
	
	G.reindeerDrops=['Christmas tree biscuits','Snowflake biscuits','Snowman biscuits','Holly biscuits','Candy cane biscuits','Bell biscuits','Present biscuits'];
	G.GetHowManyReindeerDrops=function()
	{
		var num=0;
		for (var i in G.reindeerDrops) {if (G.isUnlocked(G.reindeerDrops[i])) num++;}
		return num;
	}
	
	G.heartDrops=['Pure heart biscuits','Ardent heart biscuits','Sour heart biscuits','Weeping heart biscuits','Golden heart biscuits','Eternal heart biscuits','Prism heart biscuits'];
	G.GetHowManyHeartDrops=function()
	{
		var num=0;
		for (var i in G.heartDrops) {if (G.isUnlocked(G.heartDrops[i])) num++;}
		return num;
	}
	
	G.easterEggs=['Chicken egg','Duck egg','Turkey egg','Quail egg','Robin egg','Ostrich egg','Cassowary egg','Salmon roe','Frogspawn','Shark egg','Turtle egg','Ant larva','Golden goose egg','Faberge egg','Wrinklerspawn','Cookie egg','Omelette','Chocolate egg','Century egg','"egg"'];
	G.eggDrops=['Chicken egg','Duck egg','Turkey egg','Quail egg','Robin egg','Ostrich egg','Cassowary egg','Salmon roe','Frogspawn','Shark egg','Turtle egg','Ant larva'];
	G.rareEggDrops=['Golden goose egg','Faberge egg','Wrinklerspawn','Cookie egg','Omelette','Chocolate egg','Century egg','"egg"'];
	G.GetHowManyEggs=function()
	{
		var num=0;
		for (var i in G.easterEggs) {if (G.isUnlocked(G.easterEggs[i])) num++;}
		return num;
	}
	
	G.halloweenDrops=['Skull cookies','Ghost cookies','Bat cookies','Slime cookies','Pumpkin cookies','Eyeball cookies','Spider cookies'];
	G.GetHowManyHalloweenDrops=function()
	{
		var num=0;
		for (var i in G.halloweenDrops) {if (G.isUnlocked(G.halloweenDrops[i])) num++;}
		return num;
	}
	
	G.DropSanta=function()
	{
		var drops=[];
		for (var i in G.santaDrops) {if (!G.isUnlocked(G.santaDrops[i])) drops.push(G.santaDrops[i]);}
		var drop=choose(drops);
		if (drop)
		{
			G.unlock(drop);
			G.toast(`<b>`+G.upgradesBN[drop].name+`</b>!`,`You find a present which contains...`,G.upgradesBN[drop].icon);
		}
	}
	
	G.DropReindeer=function(failRate)
	{
		if (G.season!='christmas') return;
		if (G.HasAchiev('Let it snow')) failRate*=0.6;
		if (G.Has('Starsnow')) failRate*=0.95;
		failRate*=1/G.dropRateMult();
		if (G.hasGod)//todo
		{
			var godLvl=G.hasGod('seasons');
			if (godLvl==1) failRate*=0.9;
			else if (godLvl==2) failRate*=0.95;
			else if (godLvl==3) failRate*=0.97;
		}
		if (Math.random()>=failRate)
		{
			var drop=choose(G.reindeerDrops);
			if (G.Has(drop) || G.HasUnlocked(drop)) return;
			G.unlock(drop);
			G.toast(`<b>`+G.upgradesBN[drop].name+`</b>`,`The reindeer gives you:`,G.upgradesBN[drop].icon);
		}
	}
	
	G.DropEgg=function(failRate)
	{
		if (G.season!='easter') return;
		failRate*=1/G.dropRateMult();
		if (G.HasAchiev('Hide & seek champion')) failRate*=0.7;
		if (G.Has('Omelette')) failRate*=0.9;
		if (G.Has('Starspawn')) failRate*=0.9;
		if (G.hasGod)//todo
		{
			var godLvl=G.hasGod('seasons');
			if (godLvl==1) failRate*=0.9;
			else if (godLvl==2) failRate*=0.95;
			else if (godLvl==3) failRate*=0.97;
		}
		if (Math.random()>=failRate)
		{
			var drop='';
			if (Math.random()<0.1) drop=choose(G.rareEggDrops);
			else drop=choose(G.eggDrops);
			if (G.Has(drop) || G.HasUnlocked(drop))//reroll if we have it
			{
				if (Math.random()<0.1) drop=choose(G.rareEggDrops);
				else drop=choose(G.eggDrops);
			}
			if (G.Has(drop) || G.HasUnlocked(drop)) return;
			G.unlock(drop);
			G.toast(`<b>`+G.upgradesBN[drop].name+`</b>`,`You found an egg!`,G.upgradesBN[drop].icon);
		}
	}
	
	G.DropHalloween=function(failRate)
	{
		if (G.season!='halloween') return;
		if (G.HasAchiev('Spooky cookies')) failRate*=0.8;
		if (G.Has('Starterror')) failRate*=0.9;
		failRate*=1/G.dropRateMult();
		if (G.hasGod)//todo
		{
			var godLvl=G.hasGod('seasons');
			if (godLvl==1) failRate*=0.9;
			else if (godLvl==2) failRate*=0.95;
			else if (godLvl==3) failRate*=0.97;
		}
		if (Math.random()>=failRate)
		{
			var drop=choose(G.halloweenDrops);
			if (G.Has(drop) || G.HasUnlocked(drop)) return;
			G.unlock(drop);
			G.toast(`<b>`+G.upgradesBN[drop].name+`</b>`,`You found:`,G.upgradesBN[drop].icon);
		}
	}
	
	G.dropRateMult=function()
	{
		return (1+G.pool['dropChanceA'])*G.pool['dropChanceM'];
	}
	
	
	G.seasonDrops=G.heartDrops.concat(G.halloweenDrops).concat(G.easterEggs).concat(G.santaDrops).concat(G.reindeerDrops);
	
	
	G.addPostData(function(){
		G.computeSeasons();
		
		for (var i in G.santaDrops)//scale christmas upgrade prices with santa level
		{G.upgradesBN[G.santaDrops[i]].costFunc=function(){return Math.pow(3,G.santaLevel)*2525;}}
		
		for (var i in G.eggDrops)//scale egg prices to how many eggs you have
		{G.upgradesBN[G.eggDrops[i]].costFunc=function(){return Math.pow(2,G.GetHowManyEggs())*999;}}
		
		for (var i in G.rareEggDrops)
		{G.upgradesBN[G.rareEggDrops[i]].costFunc=function(){return Math.pow(3,G.GetHowManyEggs())*999;}}
	});

//===========================================================================
//COOKIE ECONOMICS
//===========================================================================
	G.refreshCps=1;//compute Cps the next frame if this is on
	G.computeCps=function()
	{
		//compute pools
		G.resetPools();
		for (var i=0;i<G.upgrades.length;i++)
		{
			var me=G.upgrades[i];
			if (me.owned)
			{
				for (var ii=0;ii<me.effs.length;ii++)
				{
					var eff=me.effs[ii];
					if (eff[2]==2) G.pool[eff[0]]=eff[1](G.pool[eff[0]]);
					else if (eff[2]) G.pool[eff[0]]*=eff[1];
					else G.pool[eff[0]]+=eff[1];
				}
			}
		}
		for (var i=0;i<G.buffs.length;i++)
		{
			var me=G.buffs[i];
			for (var ii=0;ii<me.effs.length;ii++)
			{
				var eff=me.effs[ii];
				if (eff[2]==2) G.pool[eff[0]]=eff[1](G.pool[eff[0]]);
				else if (eff[2]) G.pool[eff[0]]*=eff[1];
				else G.pool[eff[0]]+=eff[1];
			}
		}
		
		G.pool['clickM']*=1+G.auraMult('Dragon Cursor')*0.05;
		G.pool['milkPowerM']*=1+G.auraMult('Breath of Milk')*0.05;
		G.pool['cpsM']*=1+G.auraMult('Radiant Appetite');
		var n=G.shimmerTypesBN['golden'].n;
		var auraMult=G.auraMult('Dragon\'s Fortune');
		for (var i=0;i<n;i++){G.pool['cpsM']*=1+auraMult*1.23;}
		G.pool['dropChanceM']*=1+G.auraMult('Mind Over Matter')*0.25;
		G.pool['gcEffectsLifeM']*=1+G.auraMult('Epoch Manipulator')*0.05;
		G.pool['gcWrathEffectsLifeM']*=1+G.auraMult('Epoch Manipulator')*0.05;
		G.pool['gcEffectsMultM']*=1+G.auraMult('Unholy Dominion')*0.1;
		G.pool['gcWrathEffectsMultM']*=1+G.auraMult('Ancestral Metamorphosis')*0.1;
		G.pool['gcFreqM']*=1+G.auraMult('Arcane Aura')*0.05;
		G.pool['buildingCostM']*=1-G.auraMult('Fierce Hoarder')*0.02;
		G.pool['upgradeCostM']*=1-G.auraMult('Master of the Armory')*0.02;
		var num=0;
		for (var i in G.buildings) {if (i!=1) num+=G.buildings[i].amount;}
		G.pool['building1M']*=1+G.auraMult('Elder Battalion')*0.01*num;
		
		//todo: gods
		
		var prestigeMult=1+0.01*G.prestige*G.GetHeavenlyMultiplier();
		
		var cursedFinger=G.hasBuff('cursedFinger');
		
		var pool=G.upgradePools['kitten'];
		var milk=G.achievsN/25;
		var milkPower=1;
		milkPower=(milkPower+G.pool['milkPowerA'])*G.pool['milkPowerM'];
		for (var i=0;i<pool.length;i++)
		{
			if (pool[i].owned) G.pool['cpsM']*=1+pool[i].power*milk*milkPower;
		}
		var pool=G.upgradePools['pseudoKitten'];
		for (var i=0;i<pool.length;i++)
		{
			if (pool[i].owned)
			{
				let eff=pool[i].effs.find(eff=>eff[0]=='pseudoKitten');
				if (!eff) continue;
				G.pool['cpsM']*=1+(eff[1]-1)*milk*milkPower;
			}
		}
		
		var cps=0;
		for (var i=0;i<G.buildings.length;i++)
		{
			var me=G.buildings[i];
			var myCps=me.cps;
			myCps=(myCps+G.pool['building'+me.id+'A'])*G.pool['building'+me.id+'M'];
			me.storedCps=myCps*(cursedFinger?0:1)*G.pool['cpsM']*G.pool['cpsBuffM']*prestigeMult;
			myCps*=(me.amount/*+me.free*/);
			cps+=myCps;
		}
		
		var sucking=0;
		for (var i in G.wrinklers)
		{
			if (G.wrinklers[i].phase==2) sucking++;
		}
		var suckRate=1/20;//each wrinkler eats a twentieth of your CpS
		//suckRate*=G.eff('wrinklerEat');
		suckRate*=1+G.auraMult('Dragon Guts')*0.2;
		G.cpsSucked=sucking*suckRate;
		
		cps=(cps)*G.pool['cpsM']+G.pool['cpsA'];
		cps*=prestigeMult;
		
		//unbuffedCps
		G.cookiesPsUnbuffed=cps;
		
		cps=(cps+G.pool['cpsBuffA'])*G.pool['cpsBuffM'];
		
		let oldCps=cps;
		
		if (cursedFinger) cps=0;
		
		G.cookiesPs=cps;
		
		var cpc=0;
		
		if (cursedFinger) cpc=oldCps*cursedFinger.tm;
		else
		{
			var mouseBonusFromCps=0;
			for (var i=0;i<G.upgradePools['mouse'].length;i++)
			{
				var me=G.upgradePools['mouse'][i];
				if (me.owned) mouseBonusFromCps+=G.cookiesPs*0.01;
			}
			if (G.Has('Fortune #104')) mouseBonusFromCps+=G.cookiesPs*0.01;
			
			cpc=(G.pool['clickA']+mouseBonusFromCps)*G.pool['clickM'];
		}
		
		G.cookiesPc=cpc;
	}
	
	G.powerClicks=0;
	G.powerClicksOn=false;
	G.getAngels=()=>{return [`Angels`,`Archangels`,`Virtues`,`Dominions`,`Cherubim`,`Seraphim`,`God`].map(it=>G.Has(it)).reduce((sum,a)=>sum+a,0);};
	G.getDemons=()=>{return [`Belphegor`,`Mammon`,`Abaddon`,`Satan`,`Asmodeus`,`Beelzebub`,`Lucifer`].map(it=>G.Has(it)).reduce((sum,a)=>sum+a,0);};
	G.lastPowerClickUse=0;
	G.lastPowerClickAttempt=0;
	G.usePowerClick=function()
	{
		let mult=1;
		let blocked=false;
		//let blockingBuffs=[G.hasBuff('frenzy'),G.hasBuff('clickFrenzy'),G.hasBuff('elderFrenzy')];
		let blockingBuffs=[G.hasBuff('clickFrenzy')];
		for (let i in blockingBuffs)
		{
			if (blockingBuffs[i])
			{
				let el=blockingBuffs[i].l;
				if (el)
				{
					triggerAnim(el,'plopHeavy');
					setTimeout(()=>{if (el){el.classList.remove('plopHeavy');}},500);
				}
				blocked=true;
			}
		}
		if (G.powerClicks<1) {}
		else if (blocked)
		{
			if (Date.now()-G.lastPowerClickAttempt>5*1000)
			{
				PlaySound('snd/bomp.mp3');
			}
			triggerAnim(l('quickButtonPowerClicks'),'plopHalf');
		}
		else
		{
			G.spendPowerClick();
			G.powerClicksTotal++;
			var demons=G.getDemons();
			mult*=(G.pool['pcMultA']+demons)*(1+G.auraMult('Dragon Cursor')*0.05);
			var pow=(G.pool['pcBuffMultA']+0.01*demons)*(1+G.auraMult('Dragon Cursor')*0.05);
			new G.buff('powerClick',{t:G.pool['pcBuffDurA']+5*demons,pow:pow});
			PlaySound('snd/powerClick'+choose([1,2,3])+'b.mp3',0.4-Math.random()*0.3);
			
			/*G.particleAt({
				x:G.w/2,
				y:G.h/2-32,
				s:5,
				sd:1.1,
				r:0,
				grav:0,
				a:0.5,
				life:0.25,
				pic:'cookieIcon',
			});*/
			G.particleAt({
				x:G.w/2,
				y:G.h/2-32,
				s:2+Math.random()*1,
				sd:1.1+Math.random()*0.1,
				r:0,
				grav:0,
				a:1,
				life:0.3,
				pic:'img/ripple.png',
			});
			G.bigCookieSizeD=-0.1;
			G.bigCookieSize=0.75;
		}
		G.lastPowerClickAttempt=Date.now();
		return mult;
	}
	G.spendPowerClick=function()
	{
		if (G.powerClicks>=1)
		{
			G.powerClicks-=1;
			G.lastPowerClickUse=Date.now();
			triggerAnim(l('quickButtonPowerClicks'),'plopHalf');
		}
	}
	G.getPowerClickCapacity=function()
	{
		if (!G.Has('Power clicks')) return 0;
		return Math.ceil(G.pool['pcCapA']+G.getAngels()*5+G.auraMult('Dragon Cursor')*5);
	}
	G.getPowerClicksPs=function()
	{
		if (!G.Has('Power clicks')) return 0;
		return 60/60/Math.max(1,G.pool['pcRateA']-G.getAngels()*2)/60;
	}
	G.earnPowerClicks=function(seconds)
	{
		var old=G.powerClicks;
		G.powerClicks+=(G.getPowerClicksPs())*seconds;
		G.powerClicks=Math.max(old,Math.max(0,Math.min(G.powerClicks,G.getPowerClickCapacity())));
	}
	
	G.pool={};
	G.resetPools=function()
	{
		/*on effs:
			effs affect pools, letting us modify things like CpS multiplier or building cost
			an eff takes the form [pool (string),amount,mode]
			pools are something like cpsA (cps adder) or cpsM (cps multiplier); or clickA, building3M, buildingCostM, ...
			mode can be 1 for multiplicative, or 0/undefined for additive (ie. the pool's existing value will be multiplied by, or incremented by the amount provided) (mind the order in which these are applied)
			mode can also be 2 to indicate a function applied to the pool, ie. ['building3A',amount=>{return amount*3;},2]
		*/
		//we follow the logic "xxxA" = additive bonus, "xxxM" = multiplicative bonus
		//we can then get something's power by doing (base+G.pool['baseA'])*G.pool['baseM']
		var pool=G.pool;
		pool['cpsA']=0;pool['cpsM']=1;
		pool['cpsBuffA']=0;pool['cpsBuffM']=1;//granted by buffs
		pool['clickA']=1;pool['clickM']=1;
		pool['gcFreqA']=0;pool['gcFreqM']=1;//golden cookie frequency (affects wrath too)
		pool['gcLifeA']=0;pool['gcLifeM']=1;//golden cookie lifespan
			pool['gcWrathLifeA']=0;pool['gcWrathLifeM']=1;//wrath cookie lifespan
		pool['gcEffectsLifeA']=0;pool['gcEffectsLifeM']=1;//golden cookie effects lifespan
			pool['gcWrathEffectsLifeA']=0;pool['gcWrathEffectsLifeM']=1;//wrath cookie effects lifespan
		pool['gcEffectsMultA']=0;pool['gcEffectsMultM']=1;//golden cookie effects multiplier
			pool['gcWrathEffectsMultA']=0;pool['gcWrathEffectsMultM']=1;//wrath cookie effects multiplier
		pool['buildingCostA']=0;pool['buildingCostM']=1;
		pool['upgradeCostA']=0;pool['upgradeCostM']=1;
		pool['reindeerLifeA']=0;pool['reindeerLifeM']=1;//reindeer lifespan
		pool['reindeerFreqA']=0;pool['reindeerFreqM']=1;//reindeer frequency
		pool['reindeerEffectsMultA']=0;pool['reindeerEffectsMultM']=1;//golden cookie effects multiplier
		pool['dropChanceA']=0;pool['dropChanceM']=1;//random drops chance
		pool['milkPowerA']=0;pool['milkPowerM']=1;//milk power
		pool['pseudoKitten']=1;//counts as a kitten with this power
		pool['pcMultA']=2;//power click cookies per click multiplier
			pool['pcRateA']=30;//gain a new power click every n minutes offline
			pool['pcCapA']=5;//max power click capacity
			pool['pcBuffMultA']=1.05;//power click buff cps multiplier
			pool['pcBuffDurA']=10;//power click buff duration (in seconds)
		
		for (var i=0;i<G.buildings.length;i++)
		{
			pool['building'+i+'A']=0;
			pool['building'+i+'M']=1;
			pool['buildingCost'+i+'A']=0;
			pool['buildingCost'+i+'M']=1;
			pool['building'+i+'Free']=0;
		}
	}
	
	G.earn=function(n)
	{
		G.cookies+=n;
		G.cookiesEarned+=n;
		G.cookiesTotal+=n;
	}
	G.Earn=G.earn;
	G.spend=function(n)
	{
		G.cookies-=n;
		G.cookies=Math.max(0,G.cookies);
	}
	G.Spend=G.spend;
	G.dissolve=function(n)
	{
		G.cookies-=n;
		G.cookies=Math.max(0,G.cookies);
		G.cookiesEarned-=n;
		G.cookiesEarned=Math.max(0,G.cookiesEarned);
	}
	
	
//===========================================================================
//BUILDINGS
//===========================================================================

	G.costIncrease=1.15;
	
	G.buildings=[];
	G.buildingsBN={};
	G.Building=function(o)
	{
		transfer(this,o);
		
		this.id=G.buildings.length;
		
		if (this.id==0)
		{
			this.baseCps=0.1;
			this.baseCost=15;
		}
		else
		{
			this.baseCps=Math.ceil((Math.pow(this.id*1,this.id*0.5+2))*10)/10;
			var digits=Math.pow(10,(Math.ceil(Math.log(Math.ceil(this.baseCps))/Math.LN10)))/100;
			this.baseCps=Math.round(this.baseCps/digits)*digits;
			
			this.baseCost=(this.id*1+9+(this.id<5?0:Math.pow(this.id-5,1.75)*5))*Math.pow(10,this.id);
			var digits=Math.pow(10,(Math.ceil(Math.log(Math.ceil(this.baseCost))/Math.LN10)))/100;
			this.baseCost=Math.round(this.baseCost/digits)*digits;
			if (this.id>=16) this.baseCost*=10;
			if (this.id>=17) this.baseCost*=10;
			if (this.id>=18) this.baseCost*=10;
			if (this.id>=19) this.baseCost*=20;
		}
		
		this.amount=0;//how many the player has
		this.amountMax=0;//max amount the player has owned this run
		this.bought=0;
		this.free=0;//amount granted for free (usually by prestige upgrades); baseline amount that doesn't increase cost
		
		this.storedCps=0;//how much Cps this building is producing
		this.cookiesMade=0;//how many cookies this building has produced
		
		this.locked=2;
		
		this.reset();
		
		//G.buildings[this.id]=this;
		G.buildings.push(this);
		G.buildingsBN[this.name]=this;
	}
	G.Building.prototype.redraw=function()
	{
		if (!this.l || !document.body.contains(this.l)) return false;
		
		if (this.locked==2) {this.l.classList.add('locked');this.l.classList.remove('mysterious');}
		else if (this.locked==1)
		{
			this.iconL.style.backgroundPosition=this.getPic();
			this.nameL.innerHTML='???';
			this.descL.innerHTML=`(Unlocks at <span class="cost" style="font-family:Fancy;">${B(this.baseCost)}</span>)`;
			this.l.classList.add('mysterious');
			this.l.classList.add('cantAfford');
			this.l.classList.remove('locked');
		}
		else
		{
			this.iconL.style.backgroundPosition=this.getPic();
			//this.nameL.innerHTML=this.getName();
			this.descL.innerHTML=this.getDesc();
			this.l.classList.remove('mysterious');this.l.classList.remove('locked');
			var cost=0;//this.getCost();
			if (G.bulkMode==1) cost=this.getSumCost(G.bulkBuy);
			else if (G.bulkMode==-1 && G.bulkBuy==10000) cost=this.getReverseSumCost(1000);
			else if (G.bulkMode==-1) cost=this.getReverseSumCost(G.bulkBuy);
			
			if (G.bulkMode==1 && (cost>G.cookies || cost==0)) this.l.classList.add('cantAfford');
			else this.l.classList.remove('cantAfford');
			
			var str=this.getName(this.amount);
			str=this.amount+' '+cap(str);
			this.nameL.innerHTML=str;
			
			var str='Buy';
			if (G.bulkMode==-1) str='Sell';
			//str+=' '+(G.bulkBuy==10000?'max':G.bulkBuy);
			str+=' '+(G.bulkBuy==10000?(G.bulkMode==-1?this.amount:this.getBuyMax()):G.bulkBuy);
			this.buyTextL.innerHTML=`<span style="font-size:${17-Math.floor(str.length)}px;">${str}</span>`;
			this.costL.innerHTML=B(cost);
		}
	}
	G.Building.prototype.getPic=function()
	{
		if (G.season=='fools')
		{
			if (this.locked==1) return `-192px ${-this.pic*64}px`;
			else return `-128px ${-this.pic*64}px`;
		}
		if (this.locked==1) return `-64px ${-this.pic*64}px`;
		if (this.id==1 && G.elderWrath>0)
		{
			if (G.getSet('notScary')) return `${-(3)*64}px ${-(this.pic+1)*64}px`;
			return `${-(G.elderWrath-1)*64}px ${-(this.pic+1)*64}px`;
		}
		else return `0px ${-this.pic*64}px`;
	}
	G.Building.prototype.getName=function(n)
	{
		if (typeof n==='undefined') n=1;
		if (G.season=='fools') return n==1?this.foolName:this.foolPlural;
		return n==1?this.name:this.plural;
	}
	G.Building.prototype.getDesc=function()
	{
		if (G.season=='fools') return this.foolDesc;
		return this.desc;
	}
	G.Building.prototype.reset=function()
	{
		var me=this;
		me.amount=0;
		me.amountMax=0;
		me.bought=0;
		me.free=0;
		me.storedCps=0;
		me.cookiesMade=0;
	}
	G.Building.prototype.buy=function(amount)
	{
		if (G.bulkMode==-1) {this.sell(G.bulkBuy,1);return 0;}
		
		var success=0;
		var moni=0;
		var bought=0;
		if (!amount) amount=G.bulkBuy;
		
		if (amount==-1) amount=1000;
		for (var i=0;i<Math.min(amount,1000);i++)
		{
			var cost=this.getCost();
			if (G.cookies>=cost)
			{
				bought++;
				moni+=cost;
				G.spend(cost);
				this.amount++;
				this.bought++;
				//if (this.buyFunction) this.buyFunction();
				G.refreshCps=1;
				success=1;
			}
		}
		this.amountMax=Math.max(this.amount,this.amountMax);
		if (success) {PlaySound('snd/buy'+choose([1,2,3,4])+'.mp3',0.65);G.computeBuildingAmounts();this.redraw();}
	}
	G.Building.prototype.forceBuy=function(amount)
	{
		var success=0;
		var bought=0;
		if (!amount) amount=1;
		
		for (var i=0;i<Math.min(amount,1000);i++)
		{
			bought++;
			this.amount++;
			this.bought++;
			//if (this.buyFunction) this.buyFunction();
			G.refreshCps=1;
			success=1;
		}
		this.amountMax=Math.max(this.amount,this.amountMax);
		if (success) {G.computeBuildingAmounts();this.redraw();}
	}
	
	G.Building.prototype.sell=function(amount,bypass)
	{
		var success=0;
		var moni=0;
		var sold=0;
		if (amount==-1) amount=this.amount;
		if (!amount) amount=G.bulkBuy;
		for (var i=0;i<amount;i++)
		{
			var cost=this.getCost();
			var giveBack=this.getSellMultiplier();
			cost=Math.floor(cost*giveBack);
			if (this.amount>0)
			{
				sold++;
				moni+=cost;
				G.cookies+=cost;
				G.cookiesEarned=Math.max(G.cookies,G.cookiesEarned);//this is to avoid players getting the cheater achievement when selling buildings that have a higher cost than they used to
				this.amount--;
				//if (this.sellFunction) this.sellFunction();
				G.refreshCps=1;
				success=1;
			}
		}
		
		if (success && G.shimmerTypesBN['golden'].n<=0 && G.auraMult('Dragon Orbs')>0)
		{
			var highestBuilding=0;
			for (var i in G.buildings) {if (G.buildings[i].amount>0) highestBuilding=G.buildings[i];}
			if (highestBuilding==this && Math.random()<G.auraMult('Dragon Orbs')*0.1)
			{
				var buffsN=0;
				for (var i in G.buffs){buffsN++;}
				if (buffsN==0)
				{
					new G.shimmer('golden');
					G.toast(`<b>Dragon Orbs!</b>`,`Wish granted. Golden cookie spawned.`,[33,25],true);
				}
			}
		}
		
		if (success) {PlaySound('snd/sell'+choose([1,2,3,4])+'.mp3',0.75);G.computeBuildingAmounts();this.redraw();}
	}
	G.Building.prototype.forceSell=function(amount)
	{
		var success=0;
		var sold=0;
		if (!amount) amount=1;
		for (var i=0;i<amount;i++)
		{
			if (this.amount>0)
			{
				sold++;
				this.amount--;
				//if (this.sellFunction) this.sellFunction();
				G.refreshCps=1;
				success=1;
			}
		}
		if (success) {G.computeBuildingAmounts();this.redraw();}
	}
	G.Building.prototype.sacrifice=G.Building.prototype.forceSell;
	
	G.Building.prototype.getCost=function()
	{
		var cost=this.baseCost*Math.pow(G.costIncrease,Math.max(0,this.amount-this.free));
		cost=G.modifyBuildingCost(this,cost);
		return Math.ceil(cost);
	}
	G.Building.prototype.getSumCost=function(amount)
	{
		//return how much it would cost to buy [amount] more of this building
		var cost=0;
		var canBuy=0;
		for (var i=Math.max(0,this.amount);i<Math.max(0,(this.amount)+amount);i++)
		{
			var toAdd=this.baseCost*Math.pow(G.costIncrease,Math.max(0,i-this.free));
			if (amount==10000 && G.modifyBuildingCost(this,cost+toAdd)>G.cookies) {break;}
			cost+=toAdd;
			canBuy++;
		}
		cost=G.modifyBuildingCost(this,cost);
		if (amount==10000) return Math.min(cost,G.cookies);
		return Math.ceil(cost);
	}
	G.Building.prototype.getBuyMax=function()
	{
		//return how many more we can afford
		var cost=0;
		var canBuy=0;
		for (var i=Math.max(0,this.amount);i<Math.max(0,(this.amount)+1000);i++)
		{
			var toAdd=this.baseCost*Math.pow(G.costIncrease,Math.max(0,i-this.free));
			if (G.modifyBuildingCost(this,cost+toAdd)>G.cookies) {break;}
			cost+=toAdd;
			canBuy++;
		}
		cost=G.modifyBuildingCost(this,cost);
		return canBuy;
	}
	G.Building.prototype.getReverseSumCost=function(amount)
	{
		//return how much you'd get from selling [amount] of this building
		var cost=0;
		for (var i=Math.max(0,(this.amount)-amount);i<Math.max(0,this.amount);i++)
		{
			cost+=this.baseCost*Math.pow(G.costIncrease,Math.max(0,i-this.free));
		}
		cost=G.modifyBuildingCost(this,cost);
		cost*=this.getSellMultiplier();
		return Math.ceil(cost);
	}
	G.Building.prototype.getSellMultiplier=function()
	{
		var giveBack=0.25;
		giveBack*=1+G.auraMult('Earth Shatterer');
		return giveBack;
	}
	
	G.computeBuildingAmounts=function()
	{
		G.buildingsN=0;
		G.buildingsNmin=100000;
		for (var i=0;i<G.buildings.length;i++)
		{
			var me=G.buildings[i];
			G.buildingsN+=me.amount;
			G.buildingsNmin=Math.min(G.buildingsNmin,me.amount);
		}
	}
	
	G.modifyBuildingCost=function(building,cost)
	{
		/*
		if (G.hasBuff('Everything must go')) cost*=0.95;
		if (G.hasBuff('Crafty pixies')) cost*=0.98;
		if (G.hasBuff('Nasty goblins')) cost*=1.02;
		cost*=G.eff('buildingCost');
		if (G.hasGod)
		{
			var godLvl=G.hasGod('creation');
			if (godLvl==1) cost*=0.93;
			else if (godLvl==2) cost*=0.95;
			else if (godLvl==3) cost*=0.98;
		}*/
		cost=(cost+G.pool['buildingCostA']+G.pool['buildingCost'+building.id+'A'])*G.pool['buildingCostM']*G.pool['buildingCost'+building.id+'M'];
		return cost;
	}
	
	G.buildingN=function(name){return G.buildingsBN[name].amount;}
	
//===========================================================================
//TIERS (for upgrades and achievs)
//===========================================================================
	G.tiers={
		1:{name:'Plain',unlock:1,achievUnlock:1,iconRow:0,color:'#ccb3ac',price:					10},
		2:{name:'Berrylium',unlock:5,achievUnlock:50,iconRow:1,color:'#ff89e7',price:				50},
		3:{name:'Blueberrylium',unlock:25,achievUnlock:100,iconRow:2,color:'#00deff',price:			500},
		4:{name:'Chalcedhoney',unlock:50,achievUnlock:150,iconRow:13,color:'#ffcc2f',price:			50000},
		5:{name:'Buttergold',unlock:100,achievUnlock:200,iconRow:14,color:'#e9d673',price:			5000000},
		6:{name:'Sugarmuck',unlock:150,achievUnlock:250,iconRow:15,color:'#a8bf91',price:			500000000},
		7:{name:'Jetmint',unlock:200,achievUnlock:300,iconRow:16,color:'#60ff50',price:				500000000000},
		8:{name:'Cherrysilver',unlock:250,achievUnlock:350,iconRow:17,color:'#f01700',price:		500000000000000},
		9:{name:'Hazelrald',unlock:300,achievUnlock:400,iconRow:18,color:'#9ab834',price:			500000000000000000},
		10:{name:'Mooncandy',unlock:350,achievUnlock:450,iconRow:19,color:'#7e7ab9',price:			500000000000000000000},
		11:{name:'Astrofudge',unlock:400,achievUnlock:500,iconRow:28,color:'#9a3316',price:			5000000000000000000000000},
		12:{name:'Alabascream',unlock:450,achievUnlock:550,iconRow:30,color:'#c1a88c',price:		50000000000000000000000000000},
		13:{name:'Iridyum',unlock:500,achievUnlock:600,iconRow:31,color:'#adb1b3',price:			500000000000000000000000000000000},
		14:{name:'Glucosmium',unlock:550,achievUnlock:650,iconRow:34,color:'#ff89e7',price:			5000000000000000000000000000000000000},
		15:{name:'Glimmeringue',unlock:600,achievUnlock:700,iconRow:36,color:'#fffaa8',price:		50000000000000000000000000000000000000000},
		'synergy1':{name:'Synergy I',unlock:15,iconRow:20,color:'#008595',special:1,req:'Synergies Vol. I',price:			200000},
		'synergy2':{name:'Synergy II',unlock:150,iconRow:29,color:'#008595',special:1,req:'Synergies Vol. II',price:			200000000000},
		'fortune':{name:'Fortune',unlock:-1,iconRow:32,color:'#9ab834',special:1,price:				77777777777777777777777777777},
	};
	for (var i in G.tiers){G.tiers[i].id=isNaN(i)?i:parseInt(i);}
	G.getTieredIcon=function(type,tier)
	{
		//type can be either a building name or "Kitten"
		var col=0;
		if (type=='Kitten') col=18; else col=G.buildingsBN[type].icon[0];
		return [col,G.tiers[tier].iconRow];
	}
	
//===========================================================================
//MILK TIERS
//===========================================================================

	G.AllMilks=[
		{name:'Automatic',icon:[0,7],type:-1,pic:'milkPlain'},
		{name:'Plain milk',icon:[1,8],type:0,pic:'milkPlain'},
		{name:'Chocolate milk',icon:[2,8],type:0,pic:'milkChocolate'},
		{name:'Raspberry milk',icon:[3,8],type:0,pic:'milkRaspberry'},
		{name:'Orange milk',icon:[4,8],type:0,pic:'milkOrange'},
		{name:'Caramel milk',icon:[5,8],type:0,pic:'milkCaramel'},
		{name:'Banana milk',icon:[6,8],type:0,pic:'milkBanana'},
		{name:'Lime milk',icon:[7,8],type:0,pic:'milkLime'},
		{name:'Blueberry milk',icon:[8,8],type:0,pic:'milkBlueberry'},
		{name:'Strawberry milk',icon:[9,8],type:0,pic:'milkStrawberry'},
		{name:'Vanilla milk',icon:[10,8],type:0,pic:'milkVanilla'},
		{name:'Zebra milk',icon:[10,7],type:1,pic:'milkZebra'},
		{name:'Cosmic milk',icon:[9,7],type:1,pic:'milkStars'},
		{name:'Flaming milk',icon:[8,7],type:1,pic:'milkFire'},
		{name:'Sanguine milk',icon:[7,7],type:1,pic:'milkBlood'},
		{name:'Midas milk',icon:[6,7],type:1,pic:'milkGold'},
		{name:'Midnight milk',icon:[5,7],type:1,pic:'milkBlack'},
		{name:'Green inferno milk',icon:[4,7],type:1,pic:'milkGreenFire'},
		{name:'Frostfire milk',icon:[3,7],type:1,pic:'milkBlueFire'},
		{name:'Honey milk',icon:[21,23],type:0,pic:'milkHoney'},
		{name:'Coffee milk',icon:[22,23],type:0,pic:'milkCoffee'},
		{name:'Tea milk',icon:[23,23],type:0,pic:'milkTea'},
		{name:'Coconut milk',icon:[24,23],type:0,pic:'milkCoconut'},
		{name:'Cherry milk',icon:[25,23],type:0,pic:'milkCherry'},
		{name:'Soy milk',icon:[27,23],type:1,pic:'milkSoy'},
		{name:'Spiced milk',icon:[26,23],type:0,pic:'milkSpiced'},
		{name:'Maple milk',icon:[28,23],type:0,pic:'milkMaple'},
		{name:'Mint milk',icon:[29,23],type:0,pic:'milkMint'},
		{name:'Licorice milk',icon:[30,23],type:0,pic:'milkLicorice'},
		{name:'Rose milk',icon:[31,23],type:0,pic:'milkRose'},
		{name:'Dragonfruit milk',icon:[21,24],type:0,pic:'milkDragonfruit'},
		{name:'Melon milk',icon:[22,24],type:0,pic:'milkMelon'},
		{name:'Blackcurrant milk',icon:[23,24],type:0,pic:'milkBlackcurrant'},
		{name:'Peach milk',icon:[24,24],type:0,pic:'milkPeach'},
		{name:'Hazelnut milk',icon:[25,24],type:0,pic:'milkHazelnut'},
	];
	
	G.milkType=0;
	G.milks=[];
	for (var i=0;i<G.AllMilks.length;i++)
	{
		if (G.AllMilks[i].type==0)
		{
			G.AllMilks[i].rank=G.milks.length;
			G.milks.push(G.AllMilks[i]);
		}
	}
		
	for (var i=0;i<G.milks.length;i++)
	{
		let milk=G.milks[i];
		milk.name='Rank '+romanize(i+1)+' - '+milk.name;
	}
	
//===========================================================================
//UPGRADES
//===========================================================================
	
	G.upgrades=[];
	G.upgradesBN={};
	G.upgradesBID={};
	G.upgradePools={};
		let AddToPool=function(me,pool){if (!G.upgradePools[pool]) G.upgradePools[pool]=[];G.upgradePools[pool].push(me);}
	G.upgradeTiers={};
	G.recentUpgrades=[];
	G.lastingUpgrades=[];
	G.Upgrade=function(o)
	{
		this.unimplemented=false;
		
		this.effs=[];
		
		//try to be as tidy as possible so javascript compresses these nice and tight in memory
		this.id=0;
		this.pool='';
		this.tier=null;//untiered
		this.unlockAt={};
		this.power=0;//used by miscellaneous things
		this.cost=0;
		this.costFunc=null;
		this.func=null;//function called when bought (or toggled); in the case of a prestige upgrade, this is instead called after every ascension
		this.order=0;
		this.icon=[0,0];
		this.iconFunc=0;
		this.name='';
		this.q='';
		this.desc='';
		this.descFunc=0;
		this.preDescFunc=0;//shown under the name and before everything else
		this.qFunc=0;
		
		let tie=-1;
		if (typeof o.tie!=='undefined') {tie=o.tie;}
		let tie2=-1;
		if (typeof o.tie2!=='undefined') {tie2=o.tie2;}
		
		//transfer(this,o);
		let props=['pool','name','id','q','desc','descFunc','preDescFunc','qFunc','icon','iconFunc','cost','order','func','costFunc','effs','power','unlockAt','tier','unimplemented'];
		for (var i=0;i<props.length;i++)
		{
			if (o[props[i]]) this[props[i]]=o[props[i]];
		}
		if (o.lasting) G.lastingUpgrades.push(this.name);
		
		if (this.tier) this.tier=G.tiers[this.tier];
				
		if (this.pool=='cookie')
		{
			if (typeof this.power=='function')
			{
				let me=this;
				if (!this.descFunc) this.descFunc=()=>{return `Cookie production multiplier <b>+${me.power()}%</b>.`;};
				this.effs.push(['cpsM',v=>{return v*(1+me.power()*0.01)},1]);
			}
			else
			{
				if (!this.desc) this.desc=`Cookie production multiplier <b>+${this.power}%</b>.`;
				this.effs.push(['cpsM',1+this.power*0.01,1]);
			}
		}
		else if (this.pool=='building')
		{
			tie=G.buildings[tie];
			this.desc=`${cap(tie.plural)} are <b>twice</b> as efficient.`;
			this.preDescFunc=()=>{
				return ((tie.unshackleUpgrade.owned && this.tier.unshackleUpgrade.owned)?(`<div style="font-size:80%;text-align:center;">`+`Unshackled! <b>+${Math.round(tie.unshackleUpgrade.power*100)}%</b> extra production.</div>`):'');
			};
			/*this.descFunc=()=>{
				return ((tie.unshackleUpgrade.owned && this.tier.unshackleUpgrade.owned)?(`<div style="font-size:80%;text-align:center;">`+`Unshackled! <b>+${Math.round(tie.unshackleUpgrade.power*100)}%</b> extra production.</div><line></line>`):'')+this.desc;
			};*/
			//this.effs.push(['building'+tie.id+'M',2,1]);
			this.effs.push(['building'+tie.id+'M',v=>{
				if (tie.id==0) return v*2;
				else if (tie.unshackleUpgrade.owned && this.tier.unshackleUpgrade.owned) return v*=2+tie.unshackleUpgrade.power;
				return v*2;
			},2]);
			if (this.tier)
			{
				this.icon=G.getTieredIcon(tie.name,this.tier.id);
				this.unlockAt.buildings=[tie.id,this.tier.unlock];
			}
		}
		else if (this.pool=='grandma')
		{
			tie=G.buildings[tie];
			var grandmaNumber=(tie.id-1);
			if (grandmaNumber==1) grandmaNumber='grandma';
			else grandmaNumber+=' grandmas';
				
			if (!this.desc) this.desc=`Grandma production <b>doubled</b>.<br>${cap(tie.plural)} gain <b>+1% CpS</b> per ${grandmaNumber}.`;
			this.effs.push(['building1M',2,1]);
			this.effs.push(['building'+tie.id+'M',v=>{return v*(1+0.01*G.buildings[1].amount*(1/(tie.id-1)));},2]);
			this.unlockAt.buildings=[1,1,tie.id,15];
		}
		else if (this.pool=='finger')
		{
			let pows=[2,2,2,0.1,5,10,20];
			let unlocks=[1,1,10,25,50,100,150,200,250,300,350,400,450,500,550];
			let tier=this.tier.id;
			let pow=tier<7?pows[tier-1]:20;//tier<6?pows[tier-1]:5*Math.pow(10,tier-6);
			let unlock=tier<5?unlocks[tier-1]:50*(tier-4);
			if (tier<4)
			{
				this.desc=`Tapping and cursors are <b>twice</b> as efficient.`;
				this.effs.push(['building0M',2,1]);
				this.effs.push(['clickA',2,1]);
			}
			else if (tier==4)
			{
				this.desc=`Tapping and cursors gain <b>+${B(pow,1)}</b> cookies for each non-cursor object owned.`;
				var f=(v=>{
					var n=0;
					for (var i=1;i<G.buildings.length;i++)
					{
						n+=G.buildings[i].amount;
					}
					var mult=1;
					for (var i=4;i<G.upgradePools['finger'].length;i++)
					{
						if (G.upgradePools['finger'][i].owned) mult*=(i<7?pows[i]:20);
					}
					if (G.Has('Unshackled cursors')) mult*=25;
					return v+n*pow*mult;
				});
				this.effs.push(['building0A',f,2]);
				this.effs.push(['clickA',f,2]);
			}
			else
			{
				this.desc=`Multiplies the gain from Thousand fingers by <b>${pow}</b>.`;
			}
			this.unlockAt.buildings=[0,unlock];
		}
		else if (this.pool=='mouse')
		{
			let tier=this.tier.id;
			if (!this.desc) this.desc=`Tapping gains <b>+1% of your CpS</b>.`;
			//this.effs.push(['clickA',v=>{return v+G.cookiesPs*0.01;},2]);//note: will always be slightly behind actual CpS
			//no implicit effect; handled in G.computeCps instead
			this.unlockAt.spe=v=>{return G.cookiesHandmade>=Math.pow(10,tier*2+1);};
		}
		else if (this.pool=='kitten')
		{
			let tier=this.tier.id;
			if (!this.desc) this.desc=`You gain <b>more CpS</b> the more milk you have.`;
			if (tier) this.unlockAt.milk=Math.max(0.5,tier-1);
		}
		else if (this.pool=='synergy')
		{
			tie=G.buildings[tie];
			tie2=G.buildings[tie2];
			let tier=this.tier;
			this.costFunc=function(){return (tie.baseCost*10+tie2.baseCost*1)*this.tier.price*(G.Has('Chimera')?0.98:1);};
			this.effs.push(['building'+tie.id+'M',v=>{return v*(1+0.05*tie2.amount)},2]);
			this.effs.push(['building'+tie2.id+'M',v=>{return v*(1+0.001*tie.amount)},2]);
			this.unlockAt.upgrade=`Synergies Vol. ${tier.id=='synergy1'?'I':'II'}`;
			if (tier.id=='synergy1') this.unlockAt.buildings=[tie.id,15,tie2.id,15];
			else this.unlockAt.buildings=[tie.id,75,tie2.id,75];
		}
		else if (this.pool=='unshackle')
		{
			this.pool='prestige';
			tie=G.buildings[tie];
			let tier=this.tier;
			if (tie)
			{
				if (tie.id==0)
				{
					let pow=25;
					this.power=pow;
					this.desc=`Multiplies the gain from Thousand fingers by <b>${this.power}</b>.`;
				}
				else
				{
					let pow=(tie.id==1?0.5:(20-tie.id)*0.1);
					this.power=pow;
					if (!this.desc) this.desc=`Tiered upgrades for <b>${cap(tie.plural)}</b> provide an extra <b>+${Math.round(this.power*100)}%</b> production.<br>Only works with unshackled upgrade tiers.`;
				}
				tie.unshackleUpgrade=this;
			}
			else if (tier)
			{
				if (!this.desc) this.desc=`Unshackles all <b>${tier.name}-tier upgrades</b>, making them more powerful.<br>Only applies to unshackled buildings.`;
				tier.unshackleUpgrade=this;
			}
		}
		else if (this.pool=='angel')
		{
			this.pool='prestige';
			let speed=30-this.power*2;
			let capacity=5+this.power*5;
			this.desc=`Power click production while the game is closed sped up to <b>one every ${speed} minutes</b>.<br>Maximum power click capacity increased to <b>${capacity}</b>.`;
		}
		else if (this.pool=='demon')
		{
			this.pool='prestige';
			let clickM=2+this.power;
			let cpsM=5+this.power*1;
			let cpsMt=10+this.power*5;
			this.desc=`Power click effects increased to <b>${clickM} times</b> more cookies per click and <b>+${cpsM}%</b> cookie production for <b>${cpsMt} seconds</b>.`;
		}
		if (this.pool!='')
		{
			if (!G.upgradePools[this.pool]) G.upgradePools[this.pool]=[];
			G.upgradePools[this.pool].push(this);
		}
		if (this.tier)
		{
			if (!G.upgradeTiers[this.tier.id]) G.upgradeTiers[this.tier.id]=[];
			G.upgradeTiers[this.tier.id].push(this);
		}
		
		for (var i in this.effs)
		{
			if (typeof this.effs[i][1]==='function') this.effs[i][2]=2;//i don't know why this wasn't a thing before
		}
		
		if (this.effs.find(eff=>eff[0]=='pseudoKitten')) AddToPool(this,'pseudoKitten');
		
		if (Object.keys(this.unlockAt).length==0) this.unlockAt=null;
		if (this.unlockAt) this.unlockAt=new G.unlockAt(this,this.unlockAt);
		
		this.unlocked=0;//can we buy this upgrade?
		this.owned=0;//do we have this upgrade?
		
		//G.upgrades[this.id]=this;
		G.upgrades.push(this);
		if (G.upgradesBN[this.name]) console.log(this.name,'already exists.');
		G.upgradesBN[this.name]=this;
		G.upgradesBID[this.id]=this;
		
		this.ping=0;//note: if set to 1, marks the store tab as pinged, and will be set to Date.now() once it comes into view in the upgrades screen; this gives it a golden hue, which is removed after 3 sec
		//note: mostly scrapped; didn't work as intended
	}
	G.Upgrade.prototype.reset=function()
	{
		var me=this;
		me.unlocked=0;
		me.owned=0;
		me.ping=false;
	}
	G.Upgrade.prototype.redraw=function(el)
	{
		if (!el || this.owned || !document.body.contains(el)) return false;
		
		var cost=this.getCost();
		var costel=el.querySelector('.cost');
			if (costel) costel.innerHTML=B(cost);
		var barel=el.querySelector('.bar');
			if (barel)
			{
				if (cost>G.cookies) barel.classList.add('cantAfford');
				else barel.classList.remove('cantAfford');
			}
	}
	G.Upgrade.prototype.unlock=function()
	{
		var me=this;
		if (me.pool=='prestige') return false;
		if (me.unlocked) return false;
		me.unlocked=1;
		//G.toast(me.name,'Upgrade unlocked',me.icon);
		if (me.pool!='toggle' && me.pool!='science') G.pingScreen('store');
		me.ping=1;
	}
	G.Upgrade.prototype.lock=function()
	{
		this.lose();
	}
	G.unlock=function(name)
	{
		G.upgradesBN[name].unlock();
	}
	G.Unlock=G.unlock;
	G.lock=function(name)
	{
		G.upgradesBN[name].lock();
	}
	G.Lock=G.lock;
	G.Upgrade.prototype.toggleOff=function()
	{
		this.unlocked=0;
	}
	G.Upgrade.prototype.toggleOn=function()
	{
		this.lose();
		this.unlocked=1;
	}
	G.Upgrade.prototype.toggle=function()//mostly just for debug
	{
		if (this.owned) this.lose();
		else this.forceBuy();
		console.log(this.name,this.owned?`is now on.`:`is now off.`);
	}
	G.toggleOff=function(name)
	{
		G.upgradesBN[name].toggleOff();
	}
	G.toggleOn=function(name)
	{
		G.upgradesBN[name].toggleOn();
	}
	G.toggle=function(name)
	{
		G.upgradesBN[name].toggle();
	}
	G.testUpgrade=function(name,forceMode)
	{
		if (Array.isArray(name))
		{
			let mode=1;
			if (typeof G.upgradesBN[name[0]]!=='undefined') mode=(!G.upgradesBN[name[0]].owned);
			for (var i in name){G.testUpgrade(name[i],mode);}
		}
		else
		{
			let cps=G.cookiesPs;
			setTimeout(()=>{
				let change=G.cookiesPs-cps;
				console.log(`cps: ${(change>0?'+':'')+B((change/(cps||1))*100,3)+'%; x'+B(1+change/(cps||1),3)}`);
			},100);
			let mode=1;
			let me=G.upgradesBN[name];
			if (typeof G.upgradesBN[name]==='undefined') console.log(`No upgrade by the name`,name);
			if (typeof forceMode!=='undefined') mode=forceMode;
			if (me.owned) mode=0;
			else mode=1;
			
			if (!mode) {me.lose();console.log(`Lost`,name);}
			else {me.forceBuy();console.log(`Gained`,name);}
		}
	}
	G.Upgrade.prototype.buy=function()
	{
		if (this.pool=='prestige')
		{
			if (this.owned) return false;
			var parents=G.HeavenlyUpgradeParents[this.id];
			for (var ii in parents)
			{
				if (!G.upgradesBID[parents[ii]].owned) {return false;}
			}
			var cost=this.getCost();
			if (G.heavenlyChips<cost) return false;
			G.heavenlyChips-=cost;
			G.heavenlyChipsSpent+=cost;
			PlaySound('snd/buy'+choose([1,2,3,4])+'.mp3',0.75);
			PlaySound('snd/shimmerClick.mp3',0.5);
			this.owned=1;
			return true;
		}
		
		if (this.owned || (this.pool!='toggle' && !this.unlocked)) return false;
		var success=0;
		var moni=0;
		
		var cost=this.getCost();
		if (G.cookies>=cost)
		{
			moni+=cost;
			G.spend(cost);
			this.owned=1;
			G.refreshCps=1;
			//G.UpgradesOwned++;
			success=1;
			if (this.pool!='toggle' && this.pool!='prestige') {G.upgradesN++;G.recentUpgrades.unshift(this);G.recentUpgrades.length=Math.min(G.recentUpgrades.length,5);}
			if (this.func) this.func(this);
		}
		
		if (success) return true; else return false;
	}
	G.Upgrade.prototype.forceBuy=function()
	{
		if (this.owned) return false;
		this.owned=1;
		this.unlocked=1;
		if (this.pool!='toggle' && this.pool!='prestige') {G.upgradesN++;G.recentUpgrades.unshift(this);G.recentUpgrades.length=Math.min(G.recentUpgrades.length,5);}
		if (this.func) this.func(this,true);
		G.refreshCps=1;
	}
	G.Upgrade.prototype.lose=function()
	{
		if (this.owned && this.pool!='toggle' && this.pool!='prestige') G.upgradesN--;
		this.owned=0;
		this.unlocked=0;
		G.refreshCps=1;
	}
	G.Upgrade.prototype.getCost=function()
	{
		var cost=this.costFunc?this.costFunc(this):this.cost;
		return (this.pool=='toggle' || this.pool=='prestige')?cost:Math.ceil(G.modifyUpgradeCost(this,cost));
	}
	
	G.Has=function(name)
	{
		//return G.upgradesBN[name]?G.upgradesBN[name].owned:(console.log('upgrade "'+name+'" not found'));
		return G.upgradesBN[name].owned?true:false;
	}
	G.has=G.Has;
	G.isUnlocked=function(name)
	{
		return G.upgradesBN[name].unlocked?true:false;
	}
	G.hasUnlocked=G.isUnlocked;
	G.HasUnlocked=G.isUnlocked;
	
	G.Upgrade.prototype.getComputedEff=function(effName,base)
	{
		var eff=0;
		for (var i=0;i<this.effs.length;i++)
		{
			if (this.effs[i][0]==effName) eff=this.effs[i];
		}
		if (!eff) return 0;
		var out=0;
		if (eff[2]==2) out=eff[1](base||0);
		else if (eff[2]) out=base*eff[1];
		else out=base+eff[1];
		return out;
	}
	
	G.Upgrade.prototype.showInfo=function(o)
	{
		let me=this;
		let icon=me.iconFunc?me.iconFunc():me.icon;
		let tags=[];
			if (me.pool=='prestige') tags.push(`Heavenly`,'#efa438');
			else if (me.pool=='science') tags.push(`Tech`,'#36a4ff');
			else if (me.pool=='cookie') tags.push(`Cookie`,0);
			else if (me.pool=='debug') tags.push(`Debug`,'#00c462');
			else if (me.pool=='toggle') {}//tags.push(`Switch`,0);
			else tags.push(`Upgrade`,0);
			if (G.Has('Label printer'))
			{
				if (me.tier) tags.push(`Tier: `+me.tier.name,me.tier.color);
				if (me.name==`Label printer` || me.name==`This upgrade`) tags.push(`Tier: Self-referential`,'#ff00ea');
			}
			if (!me.owned)
			{
				if (me.pool=='tech') tags.push(`Not yet researched`,0);
				else if (me.pool=='kitten' || G.upgradePools['pseudoKitten'].indexOf(me)!=-1) tags.push(`Not yet purrchased`,0);
				else if (me.pool!='toggle') tags.push(`Not yet purchased`,0);
			}
			else if (me.owned)
			{
				if (me.pool=='tech') tags.push(`Researched`,0);
				else if (me.pool=='kitten' || G.upgradePools['pseudoKitten'].indexOf(me)!=-1) tags.push(`Purrchased`,0);
				else tags.push(`Purchased`,0);
			}
			if (G.lastingUpgrades.indexOf(me.name)!=-1 && me.unlocked) tags.push(`Unlocked forever`,'#f2ff87');
			var tagsStr='';
			for (var i=0;i<tags.length;i+=2)
			{
				if (i%2==0) tagsStr+='<div class="tag" style="background-color:'+(tags[i+1]==0?'#fff':tags[i+1])+';">'+tags[i]+'</div>';
			}
			if (tagsStr) tagsStr=`<div style="text-align:center;padding:2px 4px;">${tagsStr}</div>`;
		
		let preDesc='';
		if (me.preDescFunc) preDesc=me.preDescFunc(me);
		
		G.popup({text:`
			<h3>${me.pool=='toggle'?'Switch info':me.pool=='science'?'Tech info':me.pool=='prestige'?'Heavenly upgrade info':'Upgrade info'}</h3>
			
			<div class="framed nameBox">
				<div class="doilyTrim"></div>
				<div class="upgradeIcon icon switchLeftIn" style="flex-shrink:0;z-index:10;filter:drop-shadow(3px 3px 2px rgba(0,0,0,0.5));background-position:${-icon[0]*48}px ${-icon[1]*48}px;margin:0px 8px;"></div>
				<div class="fancy switchRightIn" style="flex-grow:1;text-align:center;margin:8px;${me.style?me.style:''}">${me.name}</div>
			</div>
			
			<line></line>
			`+(preDesc?('<div style="text-align:center;">'+preDesc+'</div><line></line>'):'')+`
			`+((me.pool=='prestige' && !me.owned && G.onAscend==1)?
				G.button({text:`Buy`,classes:'fancy magicButton '+((me.getCost()>G.heavenlyChips)?'off ':'')+'bumpButton',style:'padding:6px 16px;margin:2px 16px 6px 16px;display:block;font-size:14px;',onclick:function(){
					if (o && o.onBuy) o.onBuy();
					G.closePopup();
				}})
			:``)+`
			${tagsStr}
			`+(me.pool=='toggle'?`
				<div>
					`+G.button({text:`
						<div class="printText" style="font-size:14px;font-variant:small-caps;">Switch</div>
						<div style="pointer-events:none;">Will cost <b>`+G.selfUpdatingText(e=>{return `<span class="cost${me.getCost()>G.cookies?' cantAfford':''}">${B(me.getCost())}</span>`;})+`</b></div>
					`,classes:'bumpButton',style:'text-align:center;font-size:10px;padding:4px 8px;font-weight:normal;background:linear-gradient(to bottom,rgba(255,255,255,0.1),transparent);display:block;margin:0px;',onclick:function(){
						if (me.buy())
						{
							G.closePopup();
							PlaySound('snd/buy1.mp3',0.65);
						}
					}})+`
					<line></line>
					<p class="desc">${me.descFunc?me.descFunc(me):me.desc}</p>
				</div>
			`
			:G.selfUpdatingText(e=>{return `
				<div>
					<div style="font-size:10px;font-weight:bold;text-align:center;">Cost: <span class="${me.pool=='prestige'?'heavenlyCost ':''}cost${me.owned?' neutralCost':me.getCost()>(me.pool=='prestige'?G.heavenlyChips:G.cookies)?' cantAfford':''}">${B(me.getCost())}</span></div>
					<line></line>
					<p class="desc">${me.descFunc?me.descFunc(me):me.desc}</p>
				</div>
			`;}))+`
			<line></line>
			<p class="switchTopIn" style="text-align:right;color:rgba(255,255,255,0.65);display:${(me.q=='' && !me.qFunc)?'none':'block'};"><q>${me.qFunc?me.qFunc(me):me.q}</q></p>
		`,close:`Close`});
	}
	G.ShowInfo=function(name)
	{
		if (typeof G.upgradesBN[name]!=='undefined') G.upgradesBN[name].showInfo();
		else if (typeof G.achievsBN[name]!=='undefined') G.achievsBN[name].showInfo();
	}
	
	G.modifyUpgradeCost=function(upgrade,cost)
	{
		cost=(cost+G.pool['upgradeCostA'])*G.pool['upgradeCostM'];
		if (upgrade.pool=='cookie' && G.Has('Divine bakeries')) cost/=5;
		if (upgrade.pool=='kitten' && G.Has('Kitten wages')) cost*=0.9;
		return cost;
	}
	
	
	G.visualButton=function(o)//a square button with optional .icon
	{
		let icon=o.iconFunc?o.iconFunc():o.icon;
		return G.button({text:'-',classes:(icon?'icon':'hollowIcon')+' fancy bumpButton barIndentUnderlay',inline:true,style:``+(icon?`background-position:${-icon[0]*48}px ${-icon[1]*48}px;`:'')+`box-shadow:none;display:inline-block;vertical-align:middle;${o.text?'font-size:10px;padding:0px;padding-top:'+(icon?40:18)+'px;':'color:transparent;text-shadow:none;'}`,onclick:function(e,el){o.onclick(o);}}.concat(o));
	}
	G.toggleButton=function(o,customClick)//a square button relating to a toggle upgrade (.what); opens the upgrade's showInfo by default
	{
		let me=G.upgradesBN[o.what];
		let icon=me.iconFunc?me.iconFunc():me.icon;
		if (o.text) o.text=`<div style="position:absolute;left:0px;right:0px;bottom:0px;pointer-events:none;">${o.text}</div>`;
		return G.button({text:'-',classes:'upgradeIcon icon fancy bumpButton barIndentUnderlay',inline:true,style:`background-position:${-icon[0]*48}px ${-icon[1]*48}px;box-shadow:none;display:inline-block;vertical-align:middle;${o.text?'font-size:10px;padding:0px;':'color:transparent;text-shadow:none;'}`,onclick:function(e,el){if (customClick){customClick();}else{me.showInfo();}}}.concat(o));
	}
	
	
	//unlockAts are standardized unlock requirements
	//having these as their own object class supposedly makes memory handling more efficient
	G.unlockAts=[];
	G.unlockAt=function(what,o)
	{
		this.cookies=o.cookies||0;
		this.cps=o.cps||0;
		this.buildings=o.building||o.buildings||[];//in the form: [building id 1,building amount 1,building id 2,building amount 2,...]
		this.upgrades=o.upgrade?[o.upgrade]:o.upgrades||[];//in the form: upgrades:['upgrade name 1','upgrade name 2',...] or just upgrade:'upgrade name'
		this.achievs=o.achiev?[o.achiev]:o.achievs||[];//in the form: achievs:['achiev name 1','achiev name 2',...] or just achiev:'achiev name'
		this.milk=o.milk||0;
		this.spe=o.spe||null;
		//this.what=(Array.isArray(o.what)?o.what||[o.what]);
		this.what=what;
		G.unlockAts.push(this);
	}
	
	let doUnlocksI=0;
	G.doUnlocks=function(every)
	{
		var every=every||1;
		doUnlocksI=doUnlocksI%every;
		var initial=every==1?0:doUnlocksI;
		if (every>1) doUnlocksI++;
		
		var list=[];
		list.push(...G.upgrades);
		list.push(...G.achievs);
		var len=list.length;
		
		for (var i=initial;i<len;i+=every)
		{
			var me=list[i];
			//this is probably the first time i've used labels in javascript
			doUnlocksLoop:
			if (!me.unlocked && !me.owned && me.unlockAt)
			{
				var req=me.unlockAt;
				if (G.cookiesEarned<req.cookies) break doUnlocksLoop;
				//if (G.cookiesPs<req.cps) break doUnlocksLoop;
				if (G.cookiesPsUnbuffed<req.cps) break doUnlocksLoop;
				if (G.achievsN/25<req.milk) break doUnlocksLoop;
				for (var ii=0;ii<req.buildings.length;ii+=2)
				{
					if (req.buildings[ii+1]!=-1 && req.buildings[ii].amount<req.buildings[ii+1]) break doUnlocksLoop;
				}
				for (var ii=0;ii<req.upgrades.length;ii++)
				{
					if (!req.upgrades[ii].owned) break doUnlocksLoop;
				}
				for (var ii=0;ii<req.achievs.length;ii++)
				{
					if (!req.achievs[ii].owned) break doUnlocksLoop;
				}
				if (req.spe && !req.spe(me)) break doUnlocksLoop;
				me.unlock();
			}
		}
	}
	

//===========================================================================
//ACHIEVEMENTS
//===========================================================================
	
	G.achievs=[];
	G.achievsBID=[];
	G.achievsBN={};
	G.recentAchievs=[];
	G.Achiev=function(o)
	{
		this.unimplemented=false;
		
		this.id=0;
		this.name='';
		this.pool='';
		this.desc='';
		this.descFunc=0;
		this.q='';
		this.qFunc=0;
		this.order=0;
		this.icon=[0,0];
		this.tier=null;//untiered
		this.unlockAt={};
		
		let tie=-1;
		if (typeof o.tie!=='undefined') {tie=o.tie;delete o.tie;}
		
		//transfer(this,o);
		let props=['pool','name','id','q','desc','descFunc','qFunc','icon','order','unlockAt','tier','unimplemented'];
		for (var i=0;i<props.length;i++)
		{
			if (o[props[i]]) this[props[i]]=o[props[i]];
		}
		
		//note: for achievements, .tier is usually unrelated to the upgrade tiers
		
		if (this.pool=='bank')
		{
			let tier=this.tier;
			var threshold=Math.pow(10,Math.floor(tier*1.5+2));
			if (tier==0) threshold=1;
			if (!this.desc) this.desc=`Bake <b>${B(threshold)} cookie${B(threshold)=='1'?'':'s'}</b> in one ascension.`;
			this.unlockAt.cookies=threshold;
		}
		else if (this.pool=='cps')
		{
			let tier=this.tier;
			var threshold=Math.pow(10,Math.floor(tier*1.2));
			//if (tier==0) threshold=1;
			if (!this.desc) this.desc=`Bake <b>${B(threshold)} cookie${B(threshold)=='1'?'':'s'}</b> per second.`;
			this.unlockAt.cps=threshold;
		}
		else if (this.pool=='building')
		{
			tie=G.buildings[tie];
			let tier=G.tiers[this.tier];
			if (!this.desc) this.desc=`Have <b>${B(tier.achievUnlock)}</b> ${tier.achievUnlock==1?tie.single:tie.plural}.`;
			//this.icon=G.getTieredIcon(tie.name,tier.id);
			this.unlockAt.buildings=[tie.id,tier.achievUnlock];
		}
		else if (this.pool=='buildingProd')
		{
			tie=G.buildings[tie];
			let building=tie;
			let tier=this.tier;
			var mult=0;
			if (tie.id==0) mult=7;
			else if (tie.id==1) mult=6;
			var n=12+tie.id+mult;
			if (tier==2) n+=7;
			else if (tier==3) n+=14;
			let threshold=Math.pow(10,n);
			if (!this.desc) this.desc=`Make <b>${B(threshold)}</b> cookies just from ${tie.plural}.`;
			//this.icon=G.getTieredIcon(tie.name,tier.id);
			this.unlockAt.spe=v=>{return tie.cookiesMade>=threshold;};
		}
		else if (this.pool=='mouse')
		{
			let tier=this.tier;
			var pow=Math.pow(10,(tier)*2+1);
			if (!this.desc) this.desc=`Make <b>${B(pow)}</b> cookies from tapping.`;
			this.unlockAt.spe=v=>{return G.cookiesHandmade>=pow;};
		}
		
		if (Object.keys(this.unlockAt).length==0) this.unlockAt=null;
		if (this.unlockAt) this.unlockAt=new G.unlockAt(this,this.unlockAt);
		
		this.owned=0;//do we have this achiev?
		
		G.achievs.push(this);
		if (G.achievsBN[this.name]) console.log(this.name,'already exists.');
		G.achievsBN[this.name]=this;
		G.achievsBID[this.id]=this;
	}
	G.Achiev.prototype.reset=function()
	{
		var me=this;
		me.owned=0;
	}
	G.Achiev.prototype.win=function()
	{
		var me=this;
		if (me.owned) return false;
		me.owned=1;
		if (me.pool!='shadow') G.achievsN++;
		G.recentAchievs.unshift(me);G.recentAchievs.length=Math.min(G.recentAchievs.length,5);
		G.toast(me.name,'Achievement unlocked',me.icon);
	}
	G.Achiev.prototype.forceWin=function()
	{
		var me=this;
		if (me.owned) return false;
		me.owned=1;
		G.recentAchievs.unshift(me);G.recentAchievs.length=Math.min(G.recentAchievs.length,5);
		if (me.pool!='shadow') G.achievsN++;
	}
	G.Achiev.prototype.lose=function()
	{
		var me=this;
		if (!me.owned) return false;
		me.owned=0;
		if (me.pool!='shadow') G.achievsN--;
	}
	G.win=function(name)
	{
		G.achievsBN[name].win();
	}
	G.Achiev.prototype.unlock=G.Achiev.prototype.win;
	
	G.Achiev.prototype.toggle=function()//mostly just for debug
	{
		if (this.owned) this.lose();
		else this.forceWin();
		console.log(this.name,this.owned?`is now on.`:`is now off.`);
	}
	
	G.HasAchiev=function(name)
	{
		return G.achievsBN[name].owned;
	}
	G.hasAchiev=G.HasAchiev;
	G.Achiev.prototype.showInfo=function()
	{
		let me=this;
		let icon=me.iconFunc?me.iconFunc():me.icon;
		G.popup({text:`
			<h3>Achievement info</h3>
			
			<div class="framed nameBox">
				<div class="doilyTrim"></div>
				<div class="upgradeIcon icon switchLeftIn" style="flex-shrink:0;z-index:10;filter:drop-shadow(3px 3px 2px rgba(0,0,0,0.5));background-position:${-icon[0]*48}px ${-icon[1]*48}px;margin:0px 8px;"></div>
				<div class="fancy switchRightIn" style="flex-grow:1;text-align:center;margin:8px;${me.style?me.style:''}">${me.name}</div>
			</div>
			
			<line></line>
			`+G.selfUpdatingText(e=>{return `
				<div>
					<div style="${me.owned?'color:#fff;':'color:#999;'}font-size:10px;font-weight:bold;text-align:center;">${me.owned?'Unlocked':'Not yet unlocked'}</div>
					<line></line>
					<p class="desc">${me.descFunc?me.descFunc(me):me.desc}</p>
				</div>
			`;})+`
			<line></line>
			<p class="switchTopIn" style="text-align:right;color:rgba(255,255,255,0.65);display:${(me.q=='' && !me.qFunc)?'none':'block'};"><q>${me.qFunc?me.qFunc(me):me.q}</q></p>
		`,close:`Close`});
	}
	
//===========================================================================
//CREATE DATA
//===========================================================================
	G.afterData=function()
	{
		for (var i=0;i<G.postData.length;i++)
		{
			G.postData[i]();
		}
		
		//make things more efficient by turning strings and indexes into references etc
		
		var list=[];
		list.push(...G.upgrades);
		list.push(...G.achievs);
		var len=list.length;
		
		for (var i=0;i<len;i++)
		{
			var me=list[i];
			if (me.unlockAt)
			{
				var req=me.unlockAt;
				for (var ii=0;ii<req.buildings.length;ii+=2)
				{
					req.buildings[ii]=G.buildings[req.buildings[ii]];
				}
				for (var ii=0;ii<req.upgrades.length;ii++)
				{
					if (G.upgradesBN[req.upgrades[ii]]) req.upgrades[ii]=G.upgradesBN[req.upgrades[ii]];
					//else console.log(`ERROR: ${me.name} is unlocked by nonexistent upgrade "${req.upgrades[ii]}"`,req.upgrades[ii]);
					else me.unimplemented=true;
				}
				for (var ii=0;ii<req.achievs.length;ii++)
				{
					if (G.achievsBN[req.achievs[ii]]) req.achievs[ii]=G.achievsBN[req.achievs[ii]];
					//else console.log(`ERROR: ${me.name} is unlocked by nonexistent achiev "${req.upgrades[ii]}"`,req.upgrades[ii]);
					else me.unimplemented=true;
				}
			}
		}
		
		G.upgradesTotal=0;
		G.achievsTotal=0;
		var unimplemented=[];
		for (var i in G.upgrades)
		{
			var me=G.upgrades[i];
			if (G.HeavenlyUpgradeParents[me.id])
			{
				var parents=[...G.HeavenlyUpgradeParents[me.id]];
				var newParents=[];
				for (var ii in parents)
				{
					if (G.upgradesBID[parents[ii]] && !G.upgradesBID[parents[ii]].unimplemented) newParents.push(parents[ii]); else me.unimplemented=true;
				}
				G.HeavenlyUpgradeParents[me.id]=newParents;
			}
			if (me.unimplemented)
			{
				unimplemented.push(me.name);
				if (me.pool) G.upgradePools[me.pool].splice(G.upgradePools[me.pool].indexOf(me),1);
				if (me.tier) G.upgradeTiers[me.tier.id].splice(G.upgradeTiers[me.tier.id].indexOf(me),1);
			}
			else if (me.pool=='toggle' || me.pool=='prestige') {}
			else G.upgradesTotal++;
		}
		for (var i in G.achievs)
		{
			var me=G.achievs[i];
			if (me.unimplemented) unimplemented.push(me.name);
			else if (me.pool=='shadow') {}
			else G.achievsTotal++;
		}
		
		if (unimplemented.length>0) console.log('Unimplemented:',unimplemented);
	}
	
	for (var i in G.data)
	{
		G.data[i]();
	}
	G.afterData();
//===========================================================================
//LAUNCH
//===========================================================================
	
	for (var i in G.screens)
	{
		if (G.screens[i].init) G.screens[i].init();
	}
	
	/*
		flowchart:
		reset
		then, load from save path
			if unsuccessful, reset, then load from prev save path instead
			if also unsuccessful, reset
		start loop
	*/
	
	let toToast=0;//defer toasts, as they get nipped when resetting
	
	G.Reset(true)
	.then(()=>G.Load(G.savePath))
	.then((o)=>{
		if (o=='error'){
			toToast=[`Failed to load save.`,`Restoring backup...`];
			return G.Reset(true)
			.then(()=>G.Load(G.savePathPrev))
			.then((o)=>{
				if (o=='error' || o=='none'){
					toToast=[`Failed to load save or backup.`,`Starting new save.`];
					return G.Reset(true);
				}
				else toToast=[`Failed to load save.`,`Restored from backup instead.`];
			});
		}
		else if (o=='none') return G.Reset(true);
	})
	.then(()=>{
		StartLoop();
		if (toToast) G.toast(toToast[0],toToast[1],0,true);
	});
	
	//LoadScript('datacompare.js',function(){});
}

//===========================================================================
//LOGIC
//===========================================================================
G.Logic=function(delta)
{
	//if (delta<0 || delta>30) G.savedToasts.unshift('delta: '+(Math.round(delta/3)/10)+'s, s: '+Math.round((Date.now()-G.runStart)/1000));
	var delta=Math.max(0,delta);
	
	if (G.sparklesT>0)
	{
		G.sparklesT--;
		if (G.sparklesT==1) G.sparkles.style.display='none';
	}
	G.particlesLogic(delta);
	
	if (G.onAscend>0)
	{
		G.heavenlyChipsD+=(G.heavenlyChips-G.heavenlyChipsD)*0.2;
		if (Math.abs(G.heavenlyChips-G.heavenlyChipsD)<0.01) G.heavenlyChipsD=G.heavenlyChips;
	}
	if (G.onAscend!=1)
	{
		//G.logicBuffs(delta);
		
		G.screenLogic(delta);
		G.tickerLogic(delta);
		
		var oldCookies=G.cookies;
		
		//this system handles buffs ticking down during a delta and refreshing the CpS if necessary
		var breakpoints=[];
		for (var i in G.buffs)
		{
			var me=G.buffs[i];
			if (me.t*G.fps-delta<=0) breakpoints.push(me.t*G.fps);
		}
		if (breakpoints.length>0)
		{
			breakpoints.push(delta);
			breakpoints.sort((a,b)=>a[0]-b[0]);
			
			for (var i=0;i<breakpoints.length;i++)
			{
				var deltaStep=breakpoints[i];
					if (i>0) deltaStep-=breakpoints[i-1];
				if (G.refreshCps) {G.computeCps();G.refreshCps=0;}
				G.earn((G.cookiesPs/G.fps)*deltaStep);
				G.logicBuffs(deltaStep);
			}
		}
		else
		{
			if (G.T%(G.fps*10)==0 || G.refreshCps) {G.computeCps();G.refreshCps=0;}
			G.earn((G.cookiesPs/G.fps)*delta);
			G.logicBuffs(delta);
		}
		
		if (G.T%G.fps==0)
		{
			if (Math.random()<1/1000000) G.win('Just plain lucky');
			if (G.cookiesEarned>=1e14 && !G.hasAchiev('You win a cookie')) {G.win('You win a cookie');G.earn(1);}
		}
		
		G.logicSeasons(delta);
		
		G.logicWrinklers(delta);
		
		//grandmapocalypse
			if (G.buildingN('Grandma')==0 || G.Has('Elder Covenant') || G.pledgeT>Date.now())
			{
				if (G.elderWrath>0) G.collectWrinklers();
				G.elderWrath=0;
			}
			else if (G.elderWrath==0 && G.Has('One mind')) G.elderWrath=1;
			else if (Math.random()<0.001 && G.elderWrath<G.Has('One mind')+G.Has('Communal brainsweep')+G.Has('Elder Pact')) G.elderWrath++;
		
		
		//if (G.T%(G.fps*10)==0) {G.doUnlocks();}
		if (G.T%G.fps==0) {G.doUnlocks(6);}//every second, check a 6th of all upgrades and achievs for unlocks
		
		
		var lastLocked=0;
		for (var i=0;i<G.buildings.length;i++)
		{
			var me=G.buildings[i];
			me.cookiesMade+=(me.storedCps/G.fps)*delta*me.amount;
			
			if (lastLocked>=2) me.locked=2;
			else if (G.cookiesEarned>=me.baseCost || me.bought>0)
			{
				me.locked=0;
				lastLocked=0;
			}
			else
			{
				me.locked=1;
				lastLocked++;
			}
		}
		
		if (G.explodeT>-1) G.milkLevel+=(0-G.milkLevel)*0.02;
		else G.milkLevel+=(Math.min(1,G.h/640)-G.milkLevel)*0.1;
		
		G.cookiesD+=(G.cookies-G.cookiesD)*0.2;
		if (Math.abs(G.cookies-G.cookiesD)<0.01) G.cookiesD=G.cookies;
		
		if (delta/G.fps>=30)//go idle after how many seconds of dropped frames?
		{
			G.particlesClear();
			var cookieDif=G.cookies-oldCookies;
			var time=(delta/G.fps)*1000;
			//var delta=(new Date().getTime()-(o.time||0))*G.fps/1000;
			if (cookieDif>=1) G.toast('Welcome back!',`<div style="margin:2px 16px 8px 16px;">You were away for ${sayTime(time)}, and made <b>${B(cookieDif)}</b> cookie${B(cookieDif)=='1'?'':'s'}.</div>`,[10,0],true);
			
			G.earnPowerClicks(delta/G.fps);
		}
		
		if (G.onScreen.logic) G.onScreen.logic(G.onScreen.l,delta);
		
		G.logicShimmers(delta);
		
		if (G.T%(G.fps*G.saveInterval)==0 && (Date.now()-G.lastResetTimestamp)>=1000*8) {G.Save();}
	}
}

//===========================================================================
//DRAW
//===========================================================================
let buildingRedrawI=0;


CanvasRenderingContext2D.prototype.fillPattern=function(img,X,Y,W,H,iW,iH,offX,offY)
{
	//for when built-in patterns aren't enough
	if (img.alt!='blank')
	{
		var offX=offX||0;
		var offY=offY||0;
		if (offX<0) {offX=offX-Math.floor(offX/iW)*iW;} if (offX>0) {offX=(offX%iW)-iW;}
		if (offY<0) {offY=offY-Math.floor(offY/iH)*iH;} if (offY>0) {offY=(offY%iH)-iH;}
		for (var y=offY;y<H;y+=iH){for (var x=offX;x<W;x+=iW){this.drawImage(img,X+x,Y+y,iW,iH);}}
	}
}

G.Draw=function()
{
	if (G.onAscend>0)
	{
	}
	else
	{
		G.cookiesAmountL.innerHTML=B(G.cookiesD)+(B(G.cookiesD)=='1'?' cookie':' cookies');
		G.cookiesPsL.innerHTML=B(G.cookiesPs*(1-G.cpsSucked),1)+'/s';
		var dif=(G.cookiesPs*(1-G.cpsSucked)-G.cookiesPsUnbuffed);
		if (dif>0) {G.cookiesPsL.classList.remove('unbuffed');G.cookiesPsL.classList.add('buffed');}
		else if (dif<0) {G.cookiesPsL.classList.remove('buffed');G.cookiesPsL.classList.add('unbuffed');}
		else {G.cookiesPsL.classList.remove('buffed');G.cookiesPsL.classList.remove('unbuffed');}
		
		G.drawBuffs();
		
		if (G.drawT%10==0) G.updateBG();
		
		if (G.getSet('milk'))
		{
			let milkPic=G.milks[Math.min(G.milks.length-1,Math.floor(G.achievsN/25))].pic;
			if (G.milkType!=0) milkPic=G.AllMilks[G.milkType].pic;
			if (G.lastMilkPic!=milkPic)
			{
				G.milkL.style.backgroundImage=`url(img/${milkPic}.png)`;
				G.lastMilkPic=milkPic;
			}
			G.milkL.style.transform=`translate(${-(G.T*0.5)%240}px,${240*(1-G.milkLevel)-35-(G.bigCookieSize-1)*20}px)`;
		}
		
		let ctx=G.rainCtx;
		let el=G.rainL;
		
		let w=el.width;
		let h=el.height;
		let scale=G.rainScale;
		
		if (G.getSet('particles'))
		{
			ctx.globalCompositeOperation='destination-out';
			ctx.fillStyle='rgba(0,0,0,0.1)';
			ctx.fillRect(0,0,w,h);
			ctx.globalCompositeOperation='source-over';
			
			/*
			//trippy
			ctx.globalAlpha=0.1;
			var s=1;
			ctx.drawImage(el,0,s);
			ctx.drawImage(el,0,-s);
			ctx.drawImage(el,s,0);
			ctx.drawImage(el,-s,0);
			ctx.globalAlpha=1;
			*/
			
			//cookies popping up randomly
			if (G.explodeT==-1 && G.getSet('cookiepops') && G.cookiesPs>0)
			{
				if (G.getSet('fancy') && !G.getSet('lowMotion'))
				{
					for (let i=0;i<3;i++)
					{
						if ((G.drawT-i)%Math.ceil(90-Math.pow(Math.min(G.cookiesPs,1000)/1000,0.5)*90+1)>0) continue;
						Math.seedrandom('cookiepops-'+(G.drawT-i));
						var s=(Math.random()*0.5+0.25)*(i==0?0.6:i==1?0.95:1)*128/scale;
						ctx.translate(Math.random()*w,Math.random()*h);
						ctx.rotate(Math.random()*Math.PI*2);
						ctx.drawImage(Pic('img/smallCookies.png'),Math.floor(Math.random()*8)*64,0,64,64,-s/2,-s/2,s,s);
						ctx.resetTransform();
					}
					Math.seedrandom();
				}
				else if (G.drawT%Math.ceil(90-Math.pow(Math.min(G.cookiesPs,1000)/1000,0.5)*90+1)==0)
				{
					var s=(Math.random()*0.5+0.25)*128/scale;
					ctx.translate(Math.random()*w,Math.random()*h);
					ctx.rotate(Math.random()*Math.PI*2);
					ctx.drawImage(Pic('img/smallCookies.png'),Math.floor(Math.random()*8)*64,0,64,64,-s/2,-s/2,s,s);
					ctx.resetTransform();
				}
			}
			
			//snow
			if (G.season=='christmas')
			{
				var s=512/scale;
				var x=((G.T*0.06/scale)%s);
				var y=((G.T*0.2/scale)%s);
				ctx.globalAlpha=0.1;
				ctx.globalCompositeOperation='lighter';
				ctx.fillPattern(Pic('img/snow2'+(G.elderWrath>=3?'Wrath':'')+'.jpg'),0,0,w,h,s,s,x,y);
				ctx.globalCompositeOperation='source-over';
				ctx.globalAlpha=1;
			}
			//hearts
			if (G.season=='valentines')
			{
				var s=512/scale;
				var x=((-G.T*0.034/scale)%s);
				var y=((G.T*0.2/scale)%s);
				ctx.globalAlpha=0.3;
				ctx.fillPattern(Pic('img/heartStorm'+(G.elderWrath>=3?'Wrath':'')+'.png'),0,0,w,h,s,s,x,y);
				ctx.globalAlpha=1;
			}
		}
		
		let cookieX=w/2;
		let cookieY=(h-8)/2;
		ctx.translate(cookieX,cookieY);
		if (G.explodeT>-1)
		{
			Math.seedrandom(G.seed+'-explodeAnim3');
			var explosionSeed=Math.random()*29;
			Math.seedrandom();
			var x=0;
			var y=0;
			var timeline=Math.min(G.explodeT/(G.fps*2),1);
			var isCracking=G.explodeT<G.fps*2;
			var timelinePostCrack=Math.max((G.explodeT-(G.fps*2))/G.fps,0);
			
			ctx.globalAlpha=timeline;
			var s=1024/scale;
			ctx.fillPattern(Pic('img/starbg.jpg'),-cookieX,-cookieY,w,h,s,s,x,y);
			
			ctx.fillStyle='rgba(15,15,15,'+(timelinePostCrack)+')';
			ctx.fillRect(-cookieX,-cookieY,el.width,el.height);
			
			ctx.globalAlpha=(isCracking?(timeline):Math.pow(1-timelinePostCrack,5))*(1-0.2*Math.random());
			var s=512/scale;
			var pic=Pic('img/flare.png');
			ctx.drawImage(pic,x-s/2,y-s/2,s,s);
			
			/*
			var r=(G.T%10)/10;
			ctx.globalAlpha=(r<0.5?r:1-r)*(Math.pow(1-timelinePostCrack,5));
			var s=512*(1.5-r)/scale;
			ctx.drawImage(pic,x-s/2,y-s/2,s,s);
			var r=((G.T+5)%10)/10;
			ctx.globalAlpha=(r<0.5?r:1-r)*(Math.pow(1-timelinePostCrack,5));
			var s=512*(1.5-r)/scale;
			ctx.drawImage(pic,x-s/2,y-s/2,s,s);
			*/
			
			if (isCracking)
			{
				x+=5*(Math.random()-0.5)/scale*timeline;
				y+=5*(Math.random()-0.5)/scale*timeline;
			}
				
			var timelineHalo=Math.min(1,Math.max(0,timeline*2-0.2));
			ctx.globalAlpha=0.5*(1-timelineHalo);
			var s=384*(1+Math.pow(timelineHalo,0.2)*0.5)*0.8/scale;
			var pic=Pic('img/brokenCookieHalo.png');
			ctx.drawImage(pic,x-s/2,y-s/2,s,s);
			
			var pic=Pic('img/brokenCookie.png');
			var d=Math.pow(timelinePostCrack,0.5)*96/scale;//post-crack drift distance
			ctx.globalAlpha=1-timelinePostCrack;
			for (var i=0;i<10;i++)
			{
				var s=256*(isCracking?1:(1-0.5*timelinePostCrack))*(0.8+Math.sin(G.T*1.8+i+explosionSeed*11)*0.03*(isCracking?timeline:0))/scale;
				var dd=d*(1+0.2*Math.sin(i+2+explosionSeed*17));
				var a=-Math.PI*2*(i/10+0.42);
				if (isCracking) ctx.drawImage(pic,256*i,0,256,256,x-s/2+dd*Math.sin(a)+5*(Math.random()-0.5)*timeline,y-s/2+dd*Math.cos(a)+5*(Math.random()-0.5)*timeline,s,s);
				else ctx.drawImage(pic,256*i,0,256,256,x-s/2+dd*Math.sin(a),y-s/2+dd*Math.cos(a)-Math.pow(timelinePostCrack,4+2*Math.sin(i*13+explosionSeed))*(256*1+0.75*Math.sin(i*7+explosionSeed*7)),s,s);
			}
			
			ctx.globalAlpha=isCracking?(timeline*(1-0.3*Math.random())):Math.pow(1-timelinePostCrack,10);
			var s=384*0.8/scale;
			var pic=Pic('img/brokenCookieHalo.png');
			ctx.drawImage(pic,x-s/2,y-s/2,s,s);
			
			if (G.getSet('fancy'))
			{
				ctx.globalAlpha=timeline-timelinePostCrack;
				ctx.globalCompositeOperation='screen';
				ctx.filter='blur(3px) saturate(200%)';
				ctx.drawImage(el,-cookieX,-cookieY);
				ctx.globalCompositeOperation='source-over';
				ctx.filter='none';
			}
			ctx.globalAlpha=1;
		}
		else
		{
			//big dragon
			if (G.hasBuff('dragonflight') || G.hasBuff('dragonHarvest'))
			{
				var s=300*2*(1+Math.sin(G.T*0.013)*0.2)*0.7/scale;
				var x=-s/2;
				var y=-s/(1.4+0.2*Math.sin(G.T*0.01));
				ctx.drawImage(Pic('img/dragonBG2.png'),x,y,s,s);
			}
			if (G.season=='easter' && G.onScreen.name=='cookie')
			{
				//todo: should be displayed above the milk somehow
				var nestW=304*0.98*0.8/scale;
				var nestH=161*0.98*0.8/scale;
				ctx.drawImage(Pic('img/nest.png'),-nestW/2,-nestH/2+(120+Math.sin(G.T*0.1)*3)/scale,nestW,nestH);
			}
		}
		ctx.translate(-cookieX,-cookieY);
		
		if (G.getSet('particles')) G.particlesDraw();
		G.tickerDraw();
		
		//if (G.onScreen==G.screens['store'] && G.onStoreSection==G.storeSections[0])
		if (G.drawT%5==0)
		{
			for (var i=0;i<3;i++)
			{
				if (buildingRedrawI>=G.buildings.length) buildingRedrawI=0;
				G.buildings[buildingRedrawI].redraw();
				//if (G.buildings[buildingRedrawI].l) triggerAnim(G.buildings[buildingRedrawI].l,'plop');
				buildingRedrawI++;
			}
		}
		
		
		if (G.onScreen.draw) G.onScreen.draw(G.onScreen.l);
	}
	if (G.sparklesT>0) G.sparkles.style.backgroundPosition=-Math.floor((G.sparklesFrames-G.sparklesT+1)*128)+'px 0px';
	
}