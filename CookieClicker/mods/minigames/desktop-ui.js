// Desktop Cookie Clicker UI helpers (tooltips, prompts, lump refills, sayTime), reused by the minigame page.
function __ccDesktopUI(){
		Game.tooltip={text:'',x:0,y:0,origin:'',on:0,tt:l('tooltip'),tta:l('tooltipAnchor'),shouldHide:1,dynamic:0,from:0};
		Game.tooltip.draw=function(from,text,origin)
		{
			this.shouldHide=0;
			this.text=text;
			this.from=from;
			//this.x=x;
			//this.y=y;
			this.origin=origin;
			var tt=this.tt;
			var tta=this.tta;
			tt.style.left='auto';
			tt.style.top='auto';
			tt.style.right='auto';
			tt.style.bottom='auto';
			if (typeof this.text==='function')
			{
				var text=this.text();
				if (text=='') tta.style.opacity='0';
				else
				{
					tt.innerHTML=unescape(text);
					tta.style.opacity='1';
				}
			}
			else tt.innerHTML=unescape(this.text);
			//tt.innerHTML=(typeof this.text==='function')?unescape(this.text()):unescape(this.text);
			tta.style.display='block';
			tta.style.visibility='hidden';
			Game.tooltip.update();
			tta.style.visibility='visible';
			this.on=1;
		}
		Game.tooltip.update=function()
		{
			var X=0;
			var Y=0;
			var width=this.tt.offsetWidth;
			var height=this.tt.offsetHeight;
			if (this.origin=='store')
			{
				X=Game.windowW-332-width;
				Y=Game.mouseY-32;
				if (Game.onCrate) Y=Game.onCrate.getBounds().top-42;
				Y=Math.max(0,Math.min(Game.windowH-height-44,Y));
				/*this.tta.style.right='308px';//'468px';
				this.tta.style.left='auto';
				if (Game.onCrate) Y=Game.onCrate.getBounds().top-2;
				this.tta.style.top=Math.max(0,Math.min(Game.windowH-this.tt.clientHeight-64,Y-48))+'px';*/
			}
			else
			{
				if (Game.onCrate)
				{
					var rect=Game.onCrate.getBounds();
					if (rect.left==0 && rect.top==0)//if we get that bug where we get stuck in the top-left, move to the mouse (REVISION : just do nothing)
					{return false;/*rect.left=Game.mouseX-24;rect.right=Game.mouseX+24;rect.top=Game.mouseY-24;rect.bottom=Game.mouseY+24;*/}
					if (this.origin=='left')
					{
						X=rect.left-width-16;
						Y=rect.top+(rect.bottom-rect.top)/2-height/2-38;
						Y=Math.max(0,Math.min(Game.windowH-height-19,Y));
						if (X<0) X=rect.right;
					}
					else
					{
						X=rect.left+(rect.right-rect.left)/2-width/2-8;
						Y=rect.top-height-TopBarOffset-16;
						X=Math.max(0,Math.min(Game.windowW-width-16,X));
						if (Y<0) Y=rect.bottom-TopBarOffset;
					}
				}
				else if (this.origin=='bottom-right')
				{
					X=Game.mouseX+8;
					Y=Game.mouseY-32;
					X=Math.max(0,Math.min(Game.windowW-width-16,X));
					Y=Math.max(0,Math.min(Game.windowH-height-64,Y));
				}
				else if (this.origin=='bottom')
				{
					X=Game.mouseX-width/2-8;
					Y=Game.mouseY+24;
					X=Math.max(0,Math.min(Game.windowW-width-16,X));
					Y=Math.max(0,Math.min(Game.windowH-height-64,Y));
				}
				else if (this.origin=='left')
				{
					X=Game.mouseX-width-24;
					Y=Game.mouseY-height/2-8;
					X=Math.max(0,Math.min(Game.windowW-width-16,X));
					Y=Math.max(0,Math.min(Game.windowH-height-64,Y));
				}
				else if (this.origin=='this' && this.from)
				{
					var rect=this.from.getBounds();
					X=(rect.left+rect.right)/2-width/2-8;
					Y=(rect.top)-this.tt.clientHeight-48;
					X=Math.max(0,Math.min(Game.windowW-width-16,X));
					//Y=Math.max(0,Math.min(Game.windowH-this.tt.clientHeight-64,Y));
					if (Y<0) Y=(rect.bottom-24);
					if (Y+height+40>Game.windowH)
					{
						X=rect.right+8;
						Y=rect.top+(rect.bottom-rect.top)/2-height/2-38;
						Y=Math.max(0,Math.min(Game.windowH-height-19,Y));
					}
				}
				else
				{
					X=Game.mouseX-width/2-8;
					Y=Game.mouseY-height-32;
					X=Math.max(0,Math.min(Game.windowW-width-16,X));
					Y=Math.max(0,Math.min(Game.windowH-height-64,Y));
				}
			}
			this.tta.style.left=X+'px';
			this.tta.style.right='auto';
			this.tta.style.top=Y+'px';
			this.tta.style.bottom='auto';
			if (this.shouldHide) {this.hide();this.shouldHide=0;}
			else if (Game.drawT%10==0 && typeof(this.text)==='function')
			{
				var text=this.text();
				if (text=='') this.tta.style.opacity='0';
				else
				{
					this.tt.innerHTML=unescape(text);
					this.tta.style.opacity='1';
				}
			}
		}
		Game.tooltip.hide=function()
		{
			if (this.tta) this.tta.style.display='none';
			this.dynamic=0;
			this.on=0;
		}
		Game.getTooltip=function(text,origin,isCrate)
		{
			origin=(origin?origin:'middle');
			if (isCrate) return 'onMouseOut="Game.setOnCrate(0);Game.tooltip.shouldHide=1;" onMouseOver="if (!Game.mouseDown) {Game.setOnCrate(this);Game.tooltip.dynamic=0;Game.tooltip.draw(this,\''+escape(text)+'\',\''+origin+'\');Game.tooltip.wobble();}"';
			else return 'onMouseOut="Game.tooltip.shouldHide=1;" onMouseOver="Game.tooltip.dynamic=0;Game.tooltip.draw(this,\''+escape(text)+'\',\''+origin+'\');Game.tooltip.wobble();"';
		}
		Game.getDynamicTooltip=function(func,origin,isCrate)
		{
			origin=(origin?origin:'middle');
			if (isCrate) return 'onMouseOut="Game.setOnCrate(0);Game.tooltip.shouldHide=1;" onMouseOver="if (!Game.mouseDown) {Game.setOnCrate(this);Game.tooltip.dynamic=1;Game.tooltip.draw(this,'+'function(){return '+func+'();}'+',\''+origin+'\');Game.tooltip.wobble();}"';
			return 'onMouseOut="Game.tooltip.shouldHide=1;" onMouseOver="Game.tooltip.dynamic=1;Game.tooltip.draw(this,'+'function(){return '+func+'();}'+',\''+origin+'\');Game.tooltip.wobble();"';
		}
		Game.attachTooltip=function(el,func,origin)
		{
			if (typeof func==='string')
			{
				var str=func;
				func=function(str){return function(){return str;};}(str);
			}
			origin=(origin?origin:'middle');
			AddEvent(el,'mouseover',function(func,el,origin){return function(){Game.tooltip.dynamic=1;Game.tooltip.draw(el,func,origin);};}(func,el,origin));
			AddEvent(el,'mouseout',function(){return function(){Game.tooltip.shouldHide=1;};}());
		}
		Game.tooltip.wobble=function()
		{
			//disabled because this effect doesn't look good with the slight slowdown it might or might not be causing.
			if (false)
			{
				this.tt.className='framed';
				void this.tt.offsetWidth;
				this.tt.className='framed wobbling';
			}
		}
		
		Game.getLumpRefillMax=function()
		{
			return Game.fps*60*15;//1000*60*15;//15 minutes
		}
		Game.getLumpRefillRemaining=function()
		{
			return Game.lumpRefill;//Game.getLumpRefillMax()-(Date.now()-Game.lumpRefill);
		}
		Game.canRefillLump=function()
		{
			return Game.lumpRefill<=0;//((Date.now()-Game.lumpRefill)>=Game.getLumpRefillMax());
		}
		Game.refillLump=function(n,func)
		{
			if (Game.lumps>=n && Game.canRefillLump())
			{
				Game.spendLump(n,'refill',function()
				{
					if (!Game.sesame) Game.lumpRefill=Game.getLumpRefillMax();//Date.now();
					func();
				})();
			}
		}
		Game.spendLump=function(n,str,func,free)
		{
			//ask if we want to spend N lumps (unless free)
			return function()
			{
				if (!free && Game.lumps<n) return false;
				if (!free && Game.prefs.askLumps)
				{
					PlaySound('snd/tick.mp3');
					Game.promptConfirmFunc=func;//bit dumb
					Game.Prompt('<id SpendLump><div class="icon" style="background:url('+Game.resPath+'img/icons.png?v='+Game.version+');float:left;margin-left:-8px;margin-top:-8px;background-position:'+(-29*48)+'px '+(-14*48)+'px;"></div><div style="margin:16px 8px;">'+loc("Do you want to spend %1 to %2?",['<b>'+loc("%1 sugar lump",LBeautify(n))+'</b>',str])+'</div>',[[loc("Yes"),'Game.lumps-='+n+';Game.promptConfirmFunc();Game.promptConfirmFunc=0;Game.recalculateGains=1;Game.ClosePrompt();'],loc("No")]);
					return false;
				}
				else
				{
					if (!free) Game.lumps-=n;
					func();
					Game.recalculateGains=1;
				}
			}
		}
		Game.promptOn=0;
		Game.promptUpdateFunc=0;
		Game.promptOptionsN=0;
		Game.promptOptionFocus=0;
		Game.promptNoClose=false;
		Game.UpdatePrompt=function()
		{
			if (Game.promptUpdateFunc) Game.promptUpdateFunc();
			Game.promptAnchorL.style.top=Math.floor((Game.windowH-Game.promptWrapL.offsetHeight)/2-16)+'px';
		}
		Game.Prompt=function(content,options,updateFunc,style)
		{
			Game.promptNoClose=false;
			if (updateFunc) Game.promptUpdateFunc=updateFunc;
			if (style) Game.promptWrapL.className='framed '+style; else Game.promptWrapL.className='framed';
			var str='';
			str+=content;
			if (str.indexOf('<id ')==0)
			{
				var id=str.substring(4,str.indexOf('>'));
				str=str.substring(str.indexOf('>')+1);
				str='<div id="promptContent'+id+'">'+str+'</div>';
			}
			if (str.indexOf('<noClose>')!=-1)
			{
				str=str.replace('<noClose>','');
				Game.promptNoClose=true;
			}
			var opts='';
			Game.promptOptionsN=0;
			for (var i=0;i<options.length;i++)
			{
				if (options[i]=='br')//just a linebreak
				{opts+='<br>';}
				else
				{
					if (typeof options[i]=='string') options[i]=[options[i],'PlaySound(\'snd/tickOff.mp3\');Game.ClosePrompt();'];
					else if (!options[i][1]) options[i]=[options[i][0],'PlaySound(\'snd/tickOff.mp3\');Game.ClosePrompt();',options[i][2]];
					else options[i][1]='PlaySound(\'snd/tick.mp3\');'+options[i][1];
					options[i][1]=options[i][1].replace(/'/g,'&#39;').replace(/"/g,'&#34;');
					opts+='<a id="promptOption'+i+'" class="option" '+(options[i][2]?'style="'+options[i][2]+'" ':'')+''+Game.clickStr+'="'+options[i][1]+'">'+options[i][0]+'</a>';
					Game.promptOptionsN++;
				}
			}
			Game.promptL.innerHTML=str+'<div class="optionBox">'+opts+'</div>';
			Game.promptAnchorL.style.display='block';
			Game.darkenL.style.display='block';
			Game.promptL.focus();
			Game.promptOn=1;
			Game.promptOptionFocus=0;
			Game.FocusPromptOption(0);
			Game.UpdatePrompt();
			if (!Game.promptNoClose) l('promptClose').style.display='block'; else l('promptClose').style.display='none';
		}
		Game.ClosePrompt=function()
		{
			if (!Game.promptOn) return false;
			Game.promptAnchorL.style.display='none';
			Game.darkenL.style.display='none';
			Game.promptOn=0;
			Game.promptUpdateFunc=0;
			Game.promptOptionFocus=0;
			Game.promptOptionsN=0;
			Game.promptNoClose=false;
		}
		Game.ConfirmPrompt=function()
		{
			var el=l('promptOption'+Game.promptOptionFocus);
			if (Game.promptOn && el && el.style.display!='none' && (' '+el.className+' ').indexOf(' disabled ')==-1) FireEvent(el,'click');
		}
		Game.FocusPromptOption=function(dir,tryN)
		{
			var id=Game.promptOptionFocus+dir;
			if (id<0) id=Game.promptOptionsN-1;
			if (id>=Game.promptOptionsN) id=0;
			while (id>=0 && id<Game.promptOptionsN && (!l('promptOption'+id) || l('promptOption'+id).style.display=='none'))
			{id+=(dir||1);}
			if (l('promptOption'+id) && l('promptOption'+id).style.display!='none')
			{
				if (l('promptOption'+Game.promptOptionFocus)) l('promptOption'+Game.promptOptionFocus).classList.remove('focused');
				Game.promptOptionFocus=id;
				if (l('promptOption'+Game.promptOptionFocus)) l('promptOption'+Game.promptOptionFocus).classList.add('focused');
			}
			else if (!tryN && dir!=0) {Game.promptOptionFocus=id;Game.FocusPromptOption(dir,1);}
		}
		Game.sayTime=function(time,detail)
		{
			//time is a value where one second is equal to Game.fps (30).
			//detail skips days when >1, hours when >2, minutes when >3 and seconds when >4.
			//if detail is -1, output something like "3 hours, 9 minutes, 48 seconds"
			if (time<=0) return '';
			var str='';
			var detail=detail||0;
			time=Math.floor(time);
			if (detail==-1)
			{
				//var months=0;
				var days=0;
				var hours=0;
				var minutes=0;
				var seconds=0;
				//if (time>=Game.fps*60*60*24*30) months=(Math.floor(time/(Game.fps*60*60*24*30)));
				if (time>=Game.fps*60*60*24) days=(Math.floor(time/(Game.fps*60*60*24)));
				if (time>=Game.fps*60*60) hours=(Math.floor(time/(Game.fps*60*60)));
				if (time>=Game.fps*60) minutes=(Math.floor(time/(Game.fps*60)));
				if (time>=Game.fps) seconds=(Math.floor(time/(Game.fps)));
				//days-=months*30;
				hours-=days*24;
				minutes-=hours*60+days*24*60;
				seconds-=minutes*60+hours*60*60+days*24*60*60;
				if (days>10) {hours=0;}
				if (days) {minutes=0;seconds=0;}
				if (hours) {seconds=0;}
				var bits=[];
				//if (months>0) bits.push(Beautify(months)+' month'+(days==1?'':'s'));
				if (days>0) bits.push(loc("%1 day",LBeautify(days)));
				if (hours>0) bits.push(loc("%1 hour",LBeautify(hours)));
				if (minutes>0) bits.push(loc("%1 minute",LBeautify(minutes)));
				if (seconds>0) bits.push(loc("%1 second",LBeautify(seconds)));
				if (bits.length==0) str=loc("less than 1 second");
				else str=bits.join(', ');
				/*//if (months>0) bits.push(Beautify(months)+' month'+(days==1?'':'s'));
				if (days>0) bits.push(Beautify(days)+' day'+(days==1?'':'s'));
				if (hours>0) bits.push(Beautify(hours)+' hour'+(hours==1?'':'s'));
				if (minutes>0) bits.push(Beautify(minutes)+' minute'+(minutes==1?'':'s'));
				if (seconds>0) bits.push(Beautify(seconds)+' second'+(seconds==1?'':'s'));
				if (bits.length==0) str='less than 1 second';
				else str=bits.join(', ');*/
			}
			else
			{
				/*if (time>=Game.fps*60*60*24*30*2 && detail<1) str=Beautify(Math.floor(time/(Game.fps*60*60*24*30)))+' months';
				else if (time>=Game.fps*60*60*24*30 && detail<1) str='1 month';
				else */if (time>=Game.fps*60*60*24 && detail<2) str=loc("%1 day",LBeautify(Math.floor(time/(Game.fps*60*60*24))));//Beautify(Math.floor(time/(Game.fps*60*60*24)))+' days';
				else if (time>=Game.fps*60*60 && detail<3) str=loc("%1 hour",LBeautify(Math.floor(time/(Game.fps*60*60))));//Beautify(Math.floor(time/(Game.fps*60*60)))+' hours';
				else if (time>=Game.fps*60 && detail<4) str=loc("%1 minute",LBeautify(Math.floor(time/(Game.fps*60))));//Beautify(Math.floor(time/(Game.fps*60)))+' minutes';
				else if (time>=Game.fps && detail<5) str=loc("%1 second",LBeautify(Math.floor(time/(Game.fps))));//Beautify(Math.floor(time/(Game.fps)))+' seconds';
				else str=loc("less than 1 second");
			}
			return str;
		}
}
