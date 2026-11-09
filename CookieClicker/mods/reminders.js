/*
	Auto-harvest for sugar lumps, and garden alerts while you play.
	The iPhone app sets window.__ccSettings ({autoHarvest, gardenAlerts}) from the "iPhone extras" screen,
	and asks window.__ccLumpInfo() when you leave the app so it can send a notification when the lump is ripe.
*/
(function(){
	const on=function(k){const s=window.__ccSettings;return !s || s[k]!==false;};

	window.__ccLumpInfo=function()
	{
		if (!window.G || !G.canLumps || !G.canLumps() || !(G.lumpT>0)) return null;
		const ripeAt=G.lumpT+G.lumpRipeAge;
		return {ripeAt:ripeAt,autoHarvest:on('autoHarvest'),now:Date.now()};
	};

	//---- sugar lumps: harvest as soon as they're ripe
	setInterval(function(){
		try{
			if (!on('autoHarvest') || !window.G || !G.canLumps || !G.harvestLumpNow) return;
			if (!G.canLumps() || !(G.lumpT>0)) return;
			if (Date.now()-G.lumpT>=G.lumpRipeAge) G.harvestLumpNow();
		}catch(e){}
	},2000);

	//---- garden: a message when plants become mature or are about to wither away
	let known=null;//tile -> state, so each plant is announced once
	setInterval(function(){
		try{
			if (!window.G || !G.minigameGame) return;
			const Game=G.minigameGame();
			const M=Game && Game.Objects && Game.Objects['Farm'] && Game.Objects['Farm'].minigame;
			if (!M || !M.plot || !M.plantsById) {known=null;return;}
			const now={},matured=[],dying=[];
			for (let y=0;y<6;y++) for (let x=0;x<6;x++)
			{
				const tile=M.plot[y]&&M.plot[y][x];
				if (!tile || tile[0]<1) continue;
				const me=M.plantsById[tile[0]-1];if (!me) continue;
				let state=0;
				if (tile[1]>=me.mature) state=1;
				//less than about 2 ticks left before it withers
				if (!me.immortal && state==1)
				{
					const boost=(M.plotBoost && M.plotBoost[y] && M.plotBoost[y][x])?M.plotBoost[y][x][0]:1;
					if (100-tile[1]<=(me.ageTick+me.ageTickR)*boost*2) state=2;
				}
				const key=x+','+y;
				now[key]=tile[0]+':'+state;
				if (known && known[key]!==now[key])
				{
					const before=known[key];
					const sameplant=before && before.split(':')[0]==String(tile[0]);
					const prevState=sameplant?parseInt(before.split(':')[1]):0;
					if (state==1 && prevState<1 && !me.weed) matured.push(me.name);
					if (state==2 && prevState<2 && !me.weed && !me.fungus) dying.push(me.name);
				}
			}
			const list=function(a){const c={};a.forEach(n=>c[n]=(c[n]||0)+1);return Object.keys(c).map(n=>c[n]>1?c[n]+'× '+n:n).join(', ');};
			if (known && on('gardenAlerts'))
			{
				if (matured.length) G.toast('Garden: ready!',`<b>${list(matured)}</b> ${matured.length>1?'are':'is'} now mature.`,[15,9]);
				if (dying.length) G.toast('Garden: harvest soon!',`<b>${list(dying)}</b> will wither away very soon.`,G.buildingsBN['Farm'].icon);
			}
			known=now;
		}catch(e){}
	},3000);
})();
