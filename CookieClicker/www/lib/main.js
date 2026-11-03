function l(what) {return document.getElementById(what);}
function choose(arr) {return arr[Math.floor(Math.random()*arr.length)];}
function randomFloor(x) {if ((x%1)<Math.random()) return Math.floor(x); else return Math.ceil(x);}
function cap(str) {return str.charAt(0).toUpperCase()+str.slice(1);}
function romanize(num){
	if (isNaN(num))
		return NaN;
	var digits = String(+num).split(""),
		key=["","C","CC","CCC","CD","D","DC","DCC","DCCC","CM",
				"","X","XX","XXX","XL","L","LX","LXX","LXXX","XC",
				"","I","II","III","IV","V","VI","VII","VIII","IX"],
		roman="",
		i=3;
	while (i--)
		roman=(key[+digits.pop()+(i*10)]||"")+roman;
	return Array(+digits.join("")+1).join("M")+roman;
}
function escapeRegExp(str){return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g,"\\$1");}
String.prototype.replaceAll=function(search,replacement)
//{var target=this;return target.replace(new RegExp(search,'g'),replacement);};
{var target=this;return target.replace(new RegExp(escapeRegExp(search),'g'),replacement);};
function AddEvent(html_element,event_name,event_function,passive)
{
	if (Array.isArray(event_name))
	{
		for (var i in event_name) AddEvent(html_element,event_name[i],event_function,passive);
	}
	else html_element.addEventListener(event_name,event_function,passive?{passive:true}:false);
}
Object.defineProperty(Object.prototype,'concat',{
	//at the time of writing this is used in exactly one spot in the code and is meant to make up for the lack of consistent "Spread in object literals" support
	//use: myObject.concat(someOtherObject)
	//adds all the key-values of someOtherObject to myObject. Returns myObject.
	value:function(source){for(var i in source){this[i]=source[i];}return this;},
	writable:true,
	configurable:true,
	enumerable:false
});
var entityMap={
	'&': '&amp;',
	'<': '&lt;',
	'>': '&gt;',
	'"': '&quot;',
	"'": '&#39;',
	'/': '&#x2F;',
	'`': '&#x60;',
	'=': '&#x3D;'
};
function escapeHtml(string){
	return String(string).replace(/[&<>"'`=\/]/g,function (s){
		return entityMap[s];
	});
}

function shuffle(arr){
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
  }
}

//seeded random function, courtesy of http://davidbau.com/archives/2010/01/30/random_seeds_coded_hints_and_quintillions.html
(function(a,b,c,d,e,f){function k(a){var b,c=a.length,e=this,f=0,g=e.i=e.j=0,h=e.S=[];for(c||(a=[c++]);d>f;)h[f]=f++;for(f=0;d>f;f++)h[f]=h[g=j&g+a[f%c]+(b=h[f])],h[g]=b;(e.g=function(a){for(var b,c=0,f=e.i,g=e.j,h=e.S;a--;)b=h[f=j&f+1],c=c*d+h[j&(h[f]=h[g=j&g+b])+(h[g]=b)];return e.i=f,e.j=g,c})(d)}function l(a,b){var e,c=[],d=(typeof a)[0];if(b&&"o"==d)for(e in a)try{c.push(l(a[e],b-1))}catch(f){}return c.length?c:"s"==d?a:a+"\0"}function m(a,b){for(var d,c=a+"",e=0;c.length>e;)b[j&e]=j&(d^=19*b[j&e])+c.charCodeAt(e++);return o(b)}function n(c){try{return a.crypto.getRandomValues(c=new Uint8Array(d)),o(c)}catch(e){return[+new Date,a,a.navigator.plugins,a.screen,o(b)]}}function o(a){return String.fromCharCode.apply(0,a)}var g=c.pow(d,e),h=c.pow(2,f),i=2*h,j=d-1;c.seedrandom=function(a,f){var j=[],p=m(l(f?[a,o(b)]:0 in arguments?a:n(),3),j),q=new k(j);return m(o(q.S),b),c.random=function(){for(var a=q.g(e),b=g,c=0;h>a;)a=(a+c)*d,b*=d,c=q.g(1);for(;a>=i;)a/=2,b/=2,c>>>=1;return(a+c)/b},p},m(c.random(),b)})(this,[],Math,256,6,52);


var ajax=function(url,callback)
{
	var httpRequest=new XMLHttpRequest();
	if (!httpRequest){return false;}
	httpRequest.onreadystatechange=function()
	{
		try{
			if (httpRequest.readyState===XMLHttpRequest.DONE && httpRequest.status===200)
			{
				callback(httpRequest.responseText);
			}
		}catch(e){}
	}
	//httpRequest.onerror=function(e){console.log('ERROR',e);}
	if (url.indexOf('?')==-1) url+='?'; else url+='&';
	url+='nocache='+Date.now();
	httpRequest.open('GET',url);
	httpRequest.setRequestHeader('Content-Type','text/plain');
	httpRequest.overrideMimeType('text/plain');
	httpRequest.send();
	return true;
}

/*function LoadScript(url,callback)
{
	var script=document.createElement('script');
	script.setAttribute('src',url);
	if (callback) script.onload=callback;
	document.head.appendChild(script);
	return script;
}*/
function LoadScript(url)
{
	return new Promise(function(win,fail){
		var script=document.createElement('script');
		script.setAttribute('src',url);
		script.onload=win;
		script.onerror=fail;
		document.head.appendChild(script);
	});
}


let assets=[];
let assetsToLoad=[];
let loadAsset=function(url)
{
	if (assets[url] || assetsToLoad[url]) return false;
	assetsToLoad[url]=1;
	var img=new Image();
	img.src=url;
	img.alt=url;
	img.onload=function(e){assets[url]=e.target;assetsToLoad.splice(assetsToLoad.indexOf(url),1);};
}
assets['blank']=document.createElement('canvas');assets['blank'].width=8;assets['blank'].height=8;assets['blank'].alt='blank';

var Pic=function(url)
{
	if (assets[url]) return assets[url];
	else loadAsset(url);
	return assets['blank'];
}


//file system

let FS={
	//roughly adapted from https://cordova.apache.org/docs/en/latest/reference/cordova-plugin-file/
	/*
		use:
		
		FS.write('save.txt',{mydata:'stuff'})
		.then(()=>FS.read('save.txt'))
		.then(out=>console.log('...saved data :',out));
		
		FS.del('save.txt');
		FS.clone('save.txt','save2.txt');
		
		note: uses localstorage as backup in case of failure
		note: will create a file if it can't find it, even when doing a simple read
	*/
	file:0,
	fileUrl:0,
	dir:0,
	broken:false,
	setFile:function(url)
	{
		let me=this;
		if (url==me.fileUrl) return new Promise(function(win,fail){win(me.file);});
		return new Promise(function(win,fail){
			//me.fs.root.getFile(url,{create:true,exclusive:false},function(fileEntry)
			if (!me.dir || !me.dir.getFile) {me.broken=true;win();}
			else
			{
				me.dir.getFile(url,{create:true,exclusive:false},function(fileEntry)
				{
					me.file=fileEntry;
					me.fileUrl=url;
					win(me.file);
				},fail);
			}
		});
	},
	read:function(url)
	{
		let me=this;
		return new Promise(function(win,fail){
			me.setFile(url).then(()=>{
			if (me.broken)
			{
				var out=localStorage.getItem(url);
				if (!out) out=false;
				try {out=JSON.parse(out);}
				catch(e) {out=false;}
				win(out);
			}
			else
			{
				me.file.file(function(file)
				{
					var reader=new FileReader();
					reader.onloadend=function()
					{
						var out=this.result;
						if (!out) out=localStorage.getItem(url);
						if (!out) out=false;
						try {out=JSON.parse(out);}
						catch(e) {out=false;}
						win(out);
					};
					reader.readAsText(file);
				},e=>
				{
					//return false if file doesn't exist
					var out=localStorage.getItem(url);
					if (!out) out=false;
					try {out=JSON.parse(out);}
					catch(e) {out=false;}
					win(out);
				});
			}
			});
		});
	},
	write:function(url,data)
	{
		if (typeof data==='string') data={data:data};
		data=JSON.stringify(data);
		localStorage.setItem(url,data);
		let me=this;
		return new Promise(function(win,fail){
			me.setFile(url).then(()=>{
			if (me.broken) win();
			else
			{
				me.file.createWriter(function(fileWriter)
				{
					fileWriter.onwriteend=win;
					fileWriter.onerror=win;
					data=new Blob([data],{type:'text/plain'});
					fileWriter.write(data);
				},(error)=>{
					win();
				});
			}
			});
		});
	},
	del:function(url)
	{
		let me=this;
		return new Promise(function(win,fail){
			if (me.broken) win();
			else
			{
				me.setFile(url).then(()=>{
					me.file.remove(win,fail,win);
					localStorage.removeItem(url);
				});
			}
		});
	},
	clone:function(url,toUrl)
	{
		let me=this;
		return new Promise(function(win,fail){
			if (me.broken) win();
			else
			{
				me.dir.getFile(url,{create:false},()=>{
					me.setFile(url).then(()=>{
						localStorage.setItem(toUrl,localStorage.getItem(url)||'');
						me.file.copyTo(me.dir,toUrl,win,win);
					});
				},()=>{win();});
			}
		});
	},
	getAllFiles:function()
	{
		let me=this;
		return new Promise(function(win,fail){
			if (cordova.platformId==='browser') win(Object.keys(localStorage));
			else
			{
				let reader=me.dir.createReader();
				reader.readEntries((files)=>{
					let arr=[];
					files.forEach(entry=>{
						if (entry.isFile){arr.push(entry.name);}
					});
					win(arr);
				},fail);
			}
		});
	},
	//fs:0,
	ready:false,
	init:function()
	{
		let me=this;
		
		return new Promise(function(win,fail){
			if (me.ready) {win();return false;}
			me.ready=true;
			//window.requestFileSystem(LocalFileSystem.PERSISTENT,0,function(fs)
			window.resolveLocalFileSystemURL(/*cordova.file.externalDataDirectory||*/cordova.file.dataDirectory,function(dir)
			{
				//console.log('File system initialized : "'+fs.name+'"');
				//me.fs=fs;
				me.dir=dir;
				win();
			},e=>{win();});
		});
	},
};



//let reloadApp=()=>{location.reload();};
//see https://stackoverflow.com/questions/15477887/restart-my-phonegap-app-programmatically/21207341
let initialHref=window.location.href;
let reloadingApp=false;
let reloadApp=()=>{
	//navigator.app.loadUrl("file:///android_asset/www/index.html",{wait:200,loadingDialog:"Loading...",loadUrlTimeoutValue:60000});
	if (reloadingApp) return false;
	reloadingApp=true;
	/*(typeof admob!=='undefined')?(admob.banner.hide(G.admobId)):(new Promise(function(win,fail){win();})).then(()=>{
		if (navigator && navigator.app && navigator.app.loadUrl) navigator.app.loadUrl("file:///android_asset/www/index.html");
		else window.location=initialHref;
	});*/
	if (typeof admob!=='undefined') admob=null;//this prevents "Alert - invalid action" messages - note: no longer working with previous setup as of 2022; now using the diagnostics plugin to restart instead which does not cause this issue
	/*if (navigator && navigator.app && navigator.app.loadUrl) navigator.app.loadUrl("file:///android_asset/www/index.html");
	else window.location=initialHref;*/
	if (cordova && cordova.plugins && cordova.plugins.diagnostic) cordova.plugins.diagnostic.restart(G.Crash,false);
	else window.location=initialHref;
};




G={};

G.Launch=function()
{
	G.l=l('game');
	G.lSizer=l('gameSizer');
	G.wrapl=l('wrap');
	
	let hasCrashed=false;
	G.Crash=function(e,url,line,col)
	{
		console.log(e,url,line,col);
		
		if (typeof e==='object' && e.reason)
		{
			if (typeof e.reason==='object')
			{
				url=e.reason.fileName;
				line=e.reason.lineNumber;
				col=e.reason.columnNumber;
				e=e.reason.message;
			}
			else e=e.reason;
		}
		
		let info=``;
		if (url) info+=url.substring(url.lastIndexOf('/')+1);
		if (line) info+=` line `+line+(col?`:`+col:``);
		if (!G.wrapl) return false;
		if (!hasCrashed)
		{
			hasCrashed=true;
			G.wrapl.innerHTML=`
				<div style="position:absolute;left:0px;top:0px;right:0px;bottom:0px;z-index:10000000000;background:rgba(255,255,255,0.8);color:rgba(0,0,0,0.9);padding:24px 16px;margin:8px;box-shadow:0px 0px 12px #fff inset;border-radius:8px;text-shadow:none;font-weight:bold;font-size:13px;text-align:center;overflow-y:auto;">
				<div style=""><span class="tinyIcon" style="background-position:${-17*48}px ${-5*48}px;margin:-24px -12px -24px -26px;"></span> Runtime error</div>
				<div id="runtimeErrors" style="color:rgba(200,0,0,0.9);margin:12px 0px;"></div>
				<div style="font-size:75%;">if you could notify Orteil that'd be great</div>
				`+(typeof VERSION!=='undefined'?`<div style="font-size:75%;opacity:0.3;margin-top:8px;">v.${VERSION}${TEST?' ALPHA':''}</div>`:'')+`
				<div class="button bumpButton" id="crashReload" style="position:absolute;margin:auto;bottom:30px;padding:8px 24px;pointer-events:auto;background-color:#333;color:#fff;font-size:120%;width:200px;left:0px;right:0px;">Reload</div>
				</div>
			`;
			AddEvent(l('crashReload'),['touchend','touchcancel'],function(e){e.preventDefault();reloadApp();});
		}
		if (typeof e==='object')
		{
			if (e.target && e.target.src) e='Src: '+e.target.src;
		}
		l('runtimeErrors').insertAdjacentHTML('beforeend',`<div>${info!=''?'['+info+'] ':''}${e}</div>`);
	}
	window.onerror=G.Crash;
	window.onunhandledrejection=G.Crash;
	
	G.data=[];
	G.addData=function(data)
	{
		G.data.push(data);
	}
	G.postData=[];
	G.addPostData=function(data)
	{
		G.postData.push(data);
	}
	
	//the game uses a CSS transform to scale itself properly on any device sizes; these functions are used to make up for this where needed (ie. touch position, clientRects etc)
	Rescale=function(val)
	{
		var scale=G.scale;
		return val/scale;
	}
	RescaleBox=function(val)
	{
		//for .getBoundingClientRect()
		var scale=G.scale;
		val.left/=scale;
		val.top/=scale;
		val.right/=scale;
		val.bottom/=scale;
		val.width/=scale;
		val.height/=scale;
		val.x/=scale;
		val.y/=scale;
		return val;
	}
	
	G.Init=function(StartLoop){StartLoop();};
	G._Init=function()
	{
		G.T=0;
		G.drawT=0;
		G.fps=30;
		
		G.hasFocus=true;
		window.addEventListener('pause',function(event){G.hasFocus=false;});
		window.addEventListener('resume',function(event){G.hasFocus=true;});
		window.addEventListener('visibilitychange',function(event){G.hasFocus=document.hidden?false:true;});
		
		G.w=G.l.clientWidth;
		G.h=G.l.clientHeight;
		G.scale=1;
		G.resizing=false;
		if (!G.stabilizeResize) G.stabilizeResize=function(){};
		G._stabilizeResize=function()
		{
			var w=G.lSizer.offsetWidth;
			var siteWidth=320;
			var scale=w/siteWidth;
			//document.querySelector('meta[name="viewport"]').setAttribute('content','maximum-scale=1.0, user-scalable=no, width='+siteWidth+', height=device-height,initial-scale='+scale+'');
			//document.querySelector('meta[name="viewport"]').setAttribute('content','width='+siteWidth+',initial-scale=1');
			
			G.l.style.transform='scale('+(scale)+')';
			G.l.style.width=siteWidth+'px';
			G.l.style.height=(G.lSizer.offsetHeight/scale)+'px';
			
			G.scale=scale;
			
			G.w=G.l.clientWidth;
			G.h=G.l.clientHeight;
			
			G.resizing=false;
			G.stabilizeResize();
		}
		G.resize=function()
		{
			G.resizing=true;
		}
		window.addEventListener('resize',function(event)
		{
			G.resize();
		});
		setTimeout(G.resize,50);
	
		G.mouseDown=false;//mouse button just got pressed
		G.mouseUp=false;//mouse button just got released
		G.mousePressed=false;//mouse button is currently down
		G.clickL=0;//what element got clicked
		//AddEvent(document,'mousedown',function(event){G.mouseDown=true;G.mousePressed=true;G.mouseDragFrom=event.target;G.mouseDragFromX=G.mouseX;G.mouseDragFromY=G.mouseY;});
		//AddEvent(document,'mouseup',function(event){G.mouseUp=true;G.mouseDragFrom=0;});
		//AddEvent(document,'click',function(event){G.clickL=event.target;});
		
		//note: most of this isn't used as this is a mobile app, of course
		
		G.keys=[];//key is being held down
		G.keysD=[];//key was just pressed down
		G.keysU=[];//key was just pressed up
		//shift=16, ctrl=17
		AddEvent(window,'keyup',function(e){
			if ((document.activeElement.nodeName=='TEXTAREA' || document.activeElement.nodeName=='INPUT') && e.keyCode!=27) return;
			if (e.keyCode==27) {}//esc
			else if (e.keyCode==13) {}//enter
			G.keys[e.keyCode]=0;
			G.keysD[e.keyCode]=0;
			G.keysU[e.keyCode]=1;
		});
		AddEvent(window,'keydown',function(e){
			if (!G.keys[e.keyCode])//prevent repeats
			{
				if (e.ctrlKey && e.keyCode==83) {e.preventDefault();}//ctrl-s
				if ((document.activeElement.nodeName=='TEXTAREA' || document.activeElement.nodeName=='INPUT') && e.keyCode!=27) return;
				if (e.keyCode==32) {e.preventDefault();}//space
				G.keys[e.keyCode]=1;
				G.keysD[e.keyCode]=1;
				G.keysU[e.keyCode]=0;
				//console.log('Key pressed : '+e.keyCode);
			}
		});
		AddEvent(window,'blur',function(e){
			G.keys=[];
			G.keysD=[];
			G.keysU=[];
		});
		
		//latency compensator stuff
		G.time=new Date().getTime();
		G.fpsMeasure=new Date().getTime();
		G.delta=0;
		G.accumulatedDelay=0;
		G.catchupLogic=0;
		G.fpsStartTime=0;
		G.frameNumber=0;
		G.getFps=function()
		{
			G.frameNumber++;
			var currentTime=(Date.now()-G.fpsStartTime )/1000;
			var result=Math.floor((G.frameNumber/currentTime));
			if (currentTime>1)
			{
				G.fpsStartTime=Date.now();
				G.frameNumber=0;
			}
			return result;
		}
		
		
		G._debug='';
		G.debug=function(str){G._debug=str;l('debug').innerHTML=G._debug;l('debug').style.display='block';}
		
		var div=document.createElement('div');
		div.innerHTML='<div id="debug" style="display:none;"></div>';
		div.style.cssText='position:absolute;right:8px;bottom:8px;';
		G.wrapl.appendChild(div);
		
		var div=document.createElement('div');
		div.id='fpsCounter';
		div.style.display='none';
		G.wrapl.appendChild(div);
		G.fpsCounter=div;
		var div=document.createElement('canvas');
		div.id='fpsGraph';
		div.style.display='none';
		div.width=128;
		div.height=64;
		G.wrapl.appendChild(div);
		G.fpsGraphOn=false;
		G.fpsGraph=div;
		G.fpsGraphCtx=G.fpsGraph.getContext('2d');
		var ctx=G.fpsGraphCtx;
		ctx.fillStyle='#000';
		ctx.fillRect(0,0,128,64);
		G.currentFps=0;
		G.previousFps=0;
		
		G.fpsGraphShow=function()
		{
			G.fpsGraphOn=true;
			G.fpsGraph.style.display='block';
			G.fpsCounter.style.display='block';
		}
		G.fpsGraphHide=function()
		{
			G.fpsGraphOn=false;
			G.fpsGraph.style.display='none';
			G.fpsCounter.style.display='none';
		}
		
		G.resize();
		
		G.Init(G.Loop);
		/*try{
			G.Init(G.Loop);
		}catch(e){
			G.Crash(e);
		}*/
		return true;
	}
	
	G._LaunchAd=async function()
	{
		//banner
		if (typeof admob!=='undefined')
		{
			if (cordova.platformId==='browser') return true;
			
			/*
			//consent form through cordova-plugin-consent
			//note: this has never worked so we'll just let google handle it
			if (typeof consent!=='undefined')
			{
				try{
					if (cordova.platformId==='ios')
					{
						//const status=await consent.trackingAuthorizationStatus();
						//const statusNew=await consent.requestTrackingAuthorization();
					}
					const consentStatus=await consent.getConsentStatus();
					if (consentStatus===consent.ConsentStatus.Required)
					{
						await consent.requestInfoUpdate();
					}
					const formStatus=await consent.getFormStatus();
					if (formStatus===consent.FormStatus.Available)
					{
						const form=await consent.loadForm();
						form.show();
					}
					
					PRINT('consentStatus:'+JSON.stringify(consentStatus));
					PRINT('formStatus:'+JSON.stringify(formStatus));
				}catch(e){
					PRINT('error:'+JSON.stringify(e));
				}
			}
			*/
			
			G.admobId={
				//android: 'ca-app-pub-3940256099942544/6300978111',//test
				//ios: 'ca-app-pub-3940256099942544/6300978111',//test
				android: 'ca-app-pub-8491708950677704/3410762946',
				ios: 'ca-app-pub-8491708950677704/3875411775',
			};
			
			try{
				/*
				//cordova-plugin-admob-free
				admob.banner.config({
					id:G.admobId.android,
				});
				admob.banner.prepare();
				admob.banner.show();
				*/
				
				//admob-plus-cordova
				await admob.start();
				
				let banner=new admob.BannerAd({
					adUnitId:G.admobId.android,
				});

				await banner.show();
				AddEvent(document,'impression',G.resize);
				AddEvent(document,'admob.banner.size',G.resize);
				G.resize();
				
				G.wrapl.classList.add('adActive');
			}catch(e){
				G.wrapl.classList.remove('adActive');
				G.resize();
				//well... no ad I guess
			}
		}
		G.resize();
		return true;
	}
	
	/*
	//dom explorer
	PRINT(`<div id="debugDom">Loading dom...</div>`,'height:auto;');
	let el=l('debugDom');
	let parentNode=0;
	let prevRoot=0;
	let debugDom=function(root)
	{
		if (!root || root==document.body.parentNode.parentNode) return false;
		parentNode=root.parentNode||0;
		root.classList.add('glow');
		if (prevRoot) prevRoot.classList.remove('glow');
		prevRoot=root;
		el.innerHTML='';
		let node=root;
		let it=document.createElement('div');
		it.innerHTML=`&lt;${node.tagName.toLowerCase()}&gt;${node.id?' "'+node.id+'"':''}${node.className?' ('+node.className+')':''}`;
		it.style.cssText=`border:2px outset #999;padding:2px 4px;`;
		it.onclick=()=>{debugDom(parentNode);};
		el.appendChild(it);
		let nodes=Array.from(root.children);
		for (let i in nodes)
		{
			let node=nodes[i];
			let it=document.createElement('div');
			it.innerHTML=` | -> &lt;${node.tagName.toLowerCase()}&gt;${node.id?' "'+node.id+'"':''}${node.className?' ('+node.className+')':''}`;
			it.style.cssText=`border:2px outset #999;padding:2px 4px;`;
			it.onclick=()=>{debugDom(node);};
			el.appendChild(it);
		}
	}
	debugDom(document.body);
	*/
	
	//callbacks system : basically we have functions that return HTML but also add a callback to the callbacks array; after the HTML has been added to the DOM we call G.addCallbacks() to apply all the pending callbacks - this lets us centralize HTML and callbacks in one function
	G.Callbacks=[];
	G.addCallbacks=function()
	{
		var callbacks=G.Callbacks;
		G.Callbacks=[];
		var len=callbacks.length;
		for (var i=0;i<len;i++)
		{callbacks[i]();}
	}
	G.pushCallback=function(func)
	{
		G.Callbacks.push(func);
	}
	
	G.buttonsN=0;
	G.button=function(obj)
	{
		//returns a string for a new button; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		//obj can have text, onclick (function executed when button is clicked), classes (CSS classes added to the button), id (force button to have that id), cond (a function executed a few times per second which displays or hides the button if it returns true or false)
		let id=obj.id||('button-'+G.buttonsN);
		var str='<div '+(obj.style?('style="'+obj.style+'" '):'')+'class="button'+(obj.classes?(' '+obj.classes):'')+'" id="'+id+'">'+(obj.text||'-')+'</div>';
		if (obj.onclick)
		{
			G.pushCallback(function(){
				if (l(id))
				{
					if (obj.onclick) G.onclick(l(id),(e)=>{
						if (!obj.cond || obj.cond()) obj.onclick(e,l(id));
					});
				}
			});
		}
		if (obj.cond) G.displayIf(id,obj.cond,obj.inline||false);
		G.buttonsN++;
		return str;
	}
	
	G.textN=0;
	G.updateTextTimer=function(id,func)
	{
		var el=l('updatabletextspan-'+id);
		if (el)
		{
			var newHTML=func();
			if (el.innerHTML!=newHTML) el.innerHTML=newHTML;
			setTimeout(function(){G.updateTextTimer(id,func);},150);
		}
	}
	G.selfUpdatingText=function(func)
	{
		//returns a string for a span of text that updates itself 10 times per second; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		//warning : this can quickly fill up memory and use a lot of CPU if the text created involves lots of other HTML elements as they take a moment to be garbage-collected once updated
		let id=G.textN;
		var str='<span class="updatabletextspan" id="updatabletextspan-'+id+'">'+func()+'</span>';
		G.pushCallback(function(){
			G.updateTextTimer(id,func);
		});
		G.textN++;
		return str;
	}
	
	G.displayIfTimer=function(id,cond,inline)
	{
		var el=l(id);
		if (el)
		{
			if (cond()) el.style.display=inline?'inline-block':'block';
			else el.style.display='none';
			setTimeout(function(){G.displayIfTimer(id,cond,inline);},300);
		}
	}
	G.displayIf=function(id,cond,inline)
	{
		//makes it so the element with the given id will only be displayed when the provided condition is true; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		if (l(id)) return false;
		G.pushCallback(function(){
			G.displayIfTimer(id,cond,inline);
		});
	}
	
	
	G.scrollableList=function(obj)
	{
		/*
		creates a list that fills itself with data as you scroll through it
		{
			id: dom id
			style: dom css style string
			classes: dom css classes (space-separated)
			itemH: height of each item in the list, in pixels
			dataFunc: push stuff to the list to add it as data
			renderFunc: return a string for an individual data point
			redrawFunc: called on DOM creation, then every few seconds; takes in a data point and an element, and changes some of its HTML
		}
		the data is refreshed twice per second
		the data is rendered when the list is first shown, when the list is scrolled, or when the data changes
		
		NOTE : looking back, unsure why I coded this so that the whole view is re-rendered on scroll instead of only the new ones
		*/
		let id=obj.id||('button-'+G.buttonsN);
		var str='<div '+(obj.style?('style="'+obj.style+'" '):'')+'class="scrollableList'+(obj.classes?(' '+obj.classes):'')+'" id="'+id+'"></div>';
		
		
		G.pushCallback(function(){
			/*
				note : the commented-out section below is an alternative way of handling scrolling
				it reimplements scrolling from scratch and bypasses the effect where javascript gets paused while scrolling
				however, it is still pretty janky and for some reason does not register touch end on every odd touch (this is caused by the DOM updating for some reason)
			*/
			/*if (l(id))
			{
				let el=l(id);
				let scrollY=0;
				let scrollYonLastRender=scrollY;
				let toUpdate=true;
				let data=[];
				let oldData=[];
				let view=[];
				let oldView=[];
				
				let contentsL=document.createElement('div');
				contentsL.className='scrollableListContents';
				el.appendChild(contentsL);
				
				let onX=0;
				let onY=0;
				let fromX=0;
				let fromY=0;
				let velX=0;
				let velY=0;
				
				let dY=0;
				
				let dragging=0;
				
				let minY=0;
				let maxY=0;
				
				let setStyle=function()
				{
					contentsL.style.transform='translate3d(0px,'+Math.floor(scrollY)+'px,0)';
				}
				
				AddEvent(el,'touchstart',function(e){
					if (!dragging && e.touches.length==1)
					{
						dragging=1;
						el.classList.add('scrollableListScrolling');
						clearTimeout(momentumTimeout);dY=0;
					}
				},true);
				
				let startTouch=function(e){
					if (e.touches.length==1)
					{
						var touch=e.touches[0];
						fromX=touch.pageX;
						fromY=touch.pageY-scrollY;
						onX=fromX;
						onY=fromY;
						velX=0;
						velY=0;
					}
				};
				
				AddEvent(G.l,'touchstart',startTouch,true);
				
				let moveTouch=function(e){
					if (dragging && e.touches.length>0)
					{
						var touch=e.touches[0];
						
						velX=onX-touch.pageX;
						velY=onY-touch.pageY;
						
						onX=touch.pageX;
						onY=touch.pageY;
						
						scrollY=onY-fromY;
						scrollY=Math.min(-minY,Math.max(-maxY,scrollY));
						window.requestAnimationFrame(setStyle);
						//G.debug('moving '+Math.floor(scrollY)+', '+Math.floor(onY)+' '+Math.floor(fromY));
					}
				};
				
				AddEvent(G.l,'touchmove',moveTouch,true);
				
				let momentumTimeout;
				
				let momentumLoop=function()
				{
					scrollY+=dY;
					scrollY=Math.min(-minY,Math.max(-maxY,scrollY));
					window.requestAnimationFrame(setStyle);
					dY*=0.95;
					if (Math.abs(dY)>0.05) momentumTimeout=setTimeout(function(){window.requestAnimationFrame(momentumLoop);},1000/60);
				}
				
				let endTouch=function(e)
				{
					if (dragging && e.touches.length==0)
					{
						dY=-velY;
						momentumLoop();
						
						dragging=0;
						velX=0;
						velY=0;
						el.classList.remove('scrollableListScrolling');
					}
				}
				
				AddEvent(G.l,['touchend','touchcancel'],endTouch,true);
				AddEvent(G.l,'click',endTouch,true);
				
				let render=function()
				{
					var str=``;
					var h=el.clientHeight;
					var offY=-scrollY;
					var first=Math.max(0,Math.floor(offY/obj.itemH));
					var last=Math.min(data.length,first+Math.ceil(h/obj.itemH+1));
					
					view=[];
					for (var i=first;i<last;i++)
					{
						view.push(data[i]);
					}
					
					for (var i=0;i<view.length;i++)
					{
						str+=`<div class="scrollableListItem${oldView.indexOf(view[i])==-1?' scrollableListItemNew':''}" style="top:${(first+i)*obj.itemH}px;">${obj.renderFunc(view[i],updateOnce)}</div>`;
					}
					contentsL.innerHTML=str;
					oldView=view;
					G.addCallbacks();
					scrollYonLastRender=scrollY;
				}
				
				
				let updateOnce=function()
				{
					if (l(id))
					{
						oldData=data;
						data=obj.dataFunc();
						minY=0;maxY=data.length*obj.itemH-el.clientHeight;
						contentsL.style.height=Math.max(data.length*obj.itemH,el.clientHeight)+'px';
						render();
					}
				}
				
				let updateLoop=function()
				{
					if (l(id))
					{
						oldData=data;
						data=obj.dataFunc();
						if (Math.abs(scrollYonLastRender-scrollY)>=obj.itemH/2) toUpdate=true;
						else if (data.length!=oldData.length) {toUpdate=true;contentsL.style.height=Math.max(data.length*obj.itemH,el.clientHeight)+'px';}
						else
						{
							for (var i in data)
							{
								if (data[i]!=oldData[i]) {toUpdate=true;contentsL.style.height=Math.max(data.length*obj.itemH,el.clientHeight)+'px';break;}
							}
						}
						if (toUpdate)
						{
							minY=0;maxY=data.length*obj.itemH-el.clientHeight;
							render();
							toUpdate=false;
						}
						setTimeout(function(){window.requestAnimationFrame(updateLoop);},200);
					}
					else
					{
						G.l.removeEventListener('touchstart',startTouch);
						G.l.removeEventListener('touchmove',moveTouch);
						G.l.removeEventListener(['touchend','touchcancel'],endTouch);
						G.l.removeEventListener('click',endTouch);
					}
				}
				updateLoop();
				render();
			}
			*/
			if (l(id))
			{
				let el=l(id);
				let scrollY=el.scrollTop;
				let scrollYonLastRender=scrollY;
				let toUpdate=true;
				let data=[];
				let oldData=[];
				let view=[];
				let oldView=[];
				let first=0;
				let last=0;
				
				let render=function()
				{
					var str=``;
					var h=el.clientHeight;
					var offY=scrollY;
					first=Math.max(0,Math.floor(offY/obj.itemH));
					last=Math.min(data.length,first+Math.ceil(h/obj.itemH+1));
										
					str+=`<div class="scrollableListFiller" style="height:${data.length*obj.itemH}px;"></div>`;
					
					view=[];
					for (var i=first;i<last;i++)
					{
						view.push(data[i]);
					}
					
					for (var i=0;i<view.length;i++)
					{
						str+=`<div id="${id+'-item'+(i+first)}" class="scrollableListItem${oldView.indexOf(view[i])==-1?' scrollableListItemNew':''}" style="top:${(first+i)*obj.itemH}px;">${obj.renderFunc(view[i],updateOnce)}</div>`;
					}
					el.innerHTML=str;
					if (obj.redrawFunc)
					{
						for (var i=0;i<view.length;i++)
						{
							obj.redrawFunc(view[i],l(id+'-item'+(i+first)));
						}
					}
					oldView=view;
					G.addCallbacks();
					scrollYonLastRender=scrollY;
				}
				
				//todo : add a loading spinner graphic while a render is pending
				
				let updateOnce=function()
				{
					oldData=data;
					data=obj.dataFunc();
					render();
				}
				
				let redrawI=0;
				
				let updateLoop=function()
				{
					if (l(id))
					{
						oldData=data;
						data=obj.dataFunc();
						if (Math.abs(scrollYonLastRender-el.scrollTop)>=obj.itemH/2) toUpdate=true;
						else if (data.length!=oldData.length) toUpdate=true;
						else
						{
							for (var i=0;i<data.length;i++)
							{
								if (data[i]!=oldData[i]) {toUpdate=true;break;}
							}
						}
						scrollY=el.scrollTop;
						if (toUpdate)
						{
							render();
							toUpdate=false;
						}
						else
						{
							if (obj.redrawFunc && view.length>0)
							{
								for (var i=0;i<2;i++)
								{
									if (redrawI>=view.length) redrawI=0;
									obj.redrawFunc(view[redrawI],l(id+'-item'+(redrawI+first)));
									redrawI++;
								}
							}
						}
						setTimeout(updateLoop,250);
					}
				}
				updateLoop();
				render();
			}
		});
		
		G.buttonsN++;
		return str;
	}
	
	
	/*=====================================================================================
	LOGIC
	=======================================================================================*/
	G.Logic=function(){}
	G._Logic=function(delta)
	{
		G.Logic(Math.max(0,delta));
		
		if (G.T%(G.fps*60)==0) {G.resize();}//force a resize every minute; could possibly help with ads messing with screen size?
		if (G.T%5==0 && G.resizing) {G._stabilizeResize();}
		
		if (G.mouseUp) G.mousePressed=false;
		G.mouseDown=false;
		G.mouseUp=false;
		G.clickL=0;
		G.keysD=[];
		G.keysU=[];
		if (document.activeElement.nodeName=='TEXTAREA' || document.activeElement.nodeName=='INPUT') G.keys=[];
		
		G.T++;
	}
	
	/*=====================================================================================
	DRAW
	=======================================================================================*/
	G.Draw=function(){}
	G._Draw=function()
	{
		G.Draw();
		G.drawT++;
	}
	
	/*=====================================================================================
	MAIN LOOP
	=======================================================================================*/
	G.paused=false;
	G.Pause=function()
	{
		G.paused=true;
	}
	G.Unpause=function()
	{
		G.paused=false;
		G.Loop();
	}
	G.Loop=function()
	{
		if (G.paused || hasCrashed) return false;
		//update game logic !
		G.accumulatedDelay=((new Date().getTime()-G.time)-1000/G.fps);
		G.time=new Date().getTime();
		
		G.delta=1+(G.accumulatedDelay*G.fps)/1000;
		G._Logic(G.delta);
		//delta is 1 in ideal conditions; it represents 1 frame per second, or 1/G.fps
		
		/*
		//NOTE : system disabled in favor of delta calculation
		
		G.catchupLogic=0;
		G._Logic();
		G.catchupLogic=1;
		
		//latency compensator
		G.accumulatedDelay+=((new Date().getTime()-G.time)-1000/G.fps);
		G.accumulatedDelay=Math.min(G.accumulatedDelay,1000*5);//don't compensate over 5 seconds; if you do, something's probably very wrong
		G.time=new Date().getTime();
		
		while (G.accumulatedDelay>0)
		{
			//G._Logic();
			G.accumulatedDelay-=1000/G.fps;//as long as we're detecting latency (slower than target fps), execute logic (this makes drawing slower but makes the logic behave closer to correct target fps)
		}
		G.catchupLogic=0;
		*/
		
		if (G.hasFocus || G.T%5==0) window.requestAnimationFrame(G._Draw);
		
		//fps counter and graph
		G.previousFps=G.currentFps;
		G.currentFps=G.getFps();
		if (G.fpsGraphOn)
		{
			G.fpsCounter.innerHTML=G.currentFps+' fps';
			var ctx=G.fpsGraphCtx;
			ctx.drawImage(G.fpsGraph,-1,0);
			ctx.fillStyle='rgb('+Math.round((1-G.currentFps/G.fps)*128)+',0,0)';
			ctx.fillRect(128-1,0,1,64);
			ctx.strokeStyle='#fff';
			ctx.beginPath();
			ctx.moveTo(128-1,(1-G.previousFps/G.fps)*64);
			ctx.lineTo(128,(1-G.currentFps/G.fps)*64);
			ctx.stroke();
		}
		
		if (DEV) l('debug').innerHTML=G._debug;
		
		setTimeout(G.Loop,1000/G.fps);
	}
}

DEV=0;
TEST=0;//are we on the test version ?
/*
note : on the TEST version, all assets are the same save for main.js and data.js, which are replaced by test_main.js and test_data.js
the save slot is also different
*/
SetTest=function(val){localStorage.setItem('isTest',val?'1':'0');};

G.Launch();

G.panicError=function(str,css)
{
	if (!l('panicErrors')) document.body.insertAdjacentHTML('beforeend',`<div id="panicErrors" style="position:absolute;left:2px;top:2px;right:2px;bottom:2px;pointer-events:none;z-index:10000000000;overflow-y:auto;"></div>`);
	l('panicErrors').insertAdjacentHTML('afterbegin',`<div style="word-wrap:break-word;margin-bottom:2px;background:rgba(255,255,255,0.8);color:rgba(0,0,0,0.9);padding:2px 8px;box-shadow:0px 0px 3px #fff inset;border-radius:2px;text-shadow:none;font-weight:bold;font-size:13px;text-align:left;${css||''}">${str}</div>`);
}
const PRINT=G.panicError;
const TRACK=(id,str)=>{
	if (!l('TRACK-'+id)) PRINT(`${id}: <div id="TRACK-${id}"></div>`);
	l('TRACK-'+id).innerHTML=str;
}

let app={
	initialize:function(){
		app.bindEvents();
	},
	bindEvents:function(){
		
		let failsafeReady=()=>
		{
			//wait for file plugin to load
			if (G.ready) return false;
			if (cordova && cordova.file) app.onDeviceReady();
			else setTimeout(failsafeReady,300);
		};
		
		setTimeout(app.onDeviceReady,10000);//failsafe, since 'deviceready' apparently doesn't trigger by itself anymore?
		
		document.addEventListener('deviceready',app.onDeviceReady,false);
	},
	onDeviceReady:function(){
		if (!G.ready)
		{
			G.ready=true;
			if (!cordova) {G.Crash(`Cordova couldn't launch.<br>There may be a compatibility issue with your device.`);return false;}
			if (!cordova.file) {G.Crash(`Cordova file plugin couldn't launch.<br>There may be a compatibility issue with your device.`);return false;}
			TEST=localStorage.getItem('isTest')=='1'?true:false;
			FS.init()
			.then(()=>LoadScript((TEST?'test_':'')+'main.js'),e=>{G.Crash(e);})
			.then(()=>LoadScript((TEST?'test_':'')+'data.js'),e=>{G.Crash(e);})
			.then(()=>G._Init())
			.then(()=>G._LaunchAd())
			.catch(e=>{G.Crash(e);});
		}
	}
};
