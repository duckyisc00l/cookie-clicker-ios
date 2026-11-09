/*
	Sharper artwork everywhere.
	The app has AI-upscaled copies of the game's pictures in /hd (listed in /hd/manifest.json with each original's size).
	This swaps them in wherever the game shows one of the originals, and keeps them at the original's on-screen size,
	so only the sharpness changes:
	- style sheets (the game's own and the ones the minigames add while running)
	- inline styles the game sets on elements, including HTML it builds from text
	- pictures drawn on canvases
	Used by the game page and by the minigame page.
*/
(function(){
	if (window.__ccHDArt) return;
	window.__ccHDArt=true;
	var HD='/hd/';
	var MAN=null;
	try{
		var x=new XMLHttpRequest();
		x.open('GET',HD+'manifest.json',false);
		x.send();
		if (x.status==200 || x.status==0) MAN=JSON.parse(x.responseText);
	}catch(e){}
	if (!MAN) return;

	var RE=/img\/([A-Za-z0-9_]+)\.(png|jpg)/;
	var hdFor=function(str)
	{
		var m=RE.exec(str);
		if (!m) return null;
		var size=MAN[m[1]+'.'+m[2]];
		if (!size) return null;
		return {url:HD+m[1]+'.webp',w:size[0],h:size[1]};
	};

	//split "a, b(c, d), e" at the top-level commas
	var split=function(s)
	{
		var out=[],depth=0,start=0;
		for (var i=0;i<s.length;i++)
		{
			var c=s[i];
			if (c=='(') depth++;
			else if (c==')') depth--;
			else if (c==',' && depth==0) {out.push(s.slice(start,i).trim());start=i+1;}
		}
		out.push(s.slice(start).trim());
		return out;
	};

	//swap the pictures in one set of styles (an element's, or a style sheet rule's)
	var fixStyle=function(st,el)
	{
		var bi=st.backgroundImage;
		if (!bi || bi.indexOf('img/')<0) return;
		var layers=split(bi);
		var own=st.backgroundSize;
		//an element without its own size uses the one from the style sheets
		if (!own && el && el.isConnected) {try{own=getComputedStyle(el).backgroundSize;}catch(e){}}
		var sizesNow=own?split(own):[];
		var images=[],sizes=[],changed=false;
		for (var i=0;i<layers.length;i++)
		{
			var size=sizesNow.length?sizesNow[i%sizesNow.length]:'auto';
			var hd=layers[i].indexOf('url(')==0?hdFor(layers[i]):null;
			if (hd)
			{
				images.push('url("'+hd.url+'")');
				if (!size || /^(auto|auto auto|initial)$/.test(size)) size=hd.w+'px '+hd.h+'px';
				changed=true;
			}
			else images.push(layers[i]);
			sizes.push(size||'auto');
		}
		if (!changed) return;
		st.backgroundImage=images.join(', ');
		st.backgroundSize=sizes.join(', ');
	};

	var fixSheet=function(sheet)
	{
		var rules;
		try{rules=sheet.cssRules;}catch(e){return;}
		if (!rules) return;
		for (var i=0;i<rules.length;i++)
		{
			var r=rules[i];
			if (r.style) fixStyle(r.style);
			if (r.cssRules) fixSheet(r);
		}
	};
	var fixSheets=function()
	{
		for (var i=0;i<document.styleSheets.length;i++) fixSheet(document.styleSheets[i]);
	};

	var fixElement=function(el)
	{
		if (el.nodeType!==1) return;
		var tag=el.tagName;
		if (tag=='STYLE') {if (el.sheet) fixSheet(el.sheet);return;}
		if (tag=='LINK') {if (el.sheet) fixSheet(el.sheet);el.addEventListener('load',function(){fixSheet(el.sheet);});return;}
		var s=el.getAttribute('style');
		if (s && s.indexOf('img/')>=0) fixStyle(el.style,el);
		if (el.firstElementChild)
		{
			var list=el.querySelectorAll('[style*="img/"],style');
			for (var i=0;i<list.length;i++)
			{
				if (list[i].tagName=='STYLE') {if (list[i].sheet) fixSheet(list[i].sheet);}
				else fixStyle(list[i].style,list[i]);
			}
		}
	};

	var observer=new MutationObserver(function(records){
		for (var i=0;i<records.length;i++)
		{
			var r=records[i];
			if (r.type=='attributes')
			{
				var s=r.target.getAttribute('style');
				if (s && s.indexOf('img/')>=0) fixStyle(r.target.style,r.target);
			}
			else if (r.type=='childList')
			{
				for (var j=0;j<r.addedNodes.length;j++) fixElement(r.addedNodes[j]);
				//text changed inside a <style>
				if (r.target.tagName=='STYLE' && r.target.sheet) fixSheet(r.target.sheet);
			}
		}
	});
	var start=function()
	{
		observer.observe(document.documentElement,{subtree:true,childList:true,attributes:true,attributeFilter:['style']});
		fixSheets();
		fixElement(document.documentElement);
	};
	start();
	document.addEventListener('DOMContentLoaded',function(){fixSheets();fixElement(document.documentElement);});
	window.addEventListener('load',fixSheets);

	//---- canvases: draw the sharp copy at the same size
	var pics={};
	var hdPic=function(img)
	{
		var src=img.__ccSrc;
		if (src===undefined) {src=img.__ccSrc=(img.src||'');}
		if (src.indexOf('img/')<0) return null;
		var hd=hdFor(src);
		if (!hd) return null;
		var p=pics[hd.url];
		if (!p) {p=pics[hd.url]=new Image();p.src=hd.url;p.__ccW=hd.w;p.__ccH=hd.h;}
		return (p.complete && p.naturalWidth)?p:null;
	};
	var draw=CanvasRenderingContext2D.prototype.drawImage;
	CanvasRenderingContext2D.prototype.drawImage=function(img)
	{
		var p=(img && img.tagName=='IMG')?hdPic(img):null;
		if (!p) return draw.apply(this,arguments);
		var a=arguments,k=p.naturalWidth/p.__ccW,kh=p.naturalHeight/p.__ccH;
		if (a.length==3) return draw.call(this,p,a[1],a[2],p.__ccW,p.__ccH);
		if (a.length==5) return draw.call(this,p,a[1],a[2],a[3],a[4]);
		return draw.call(this,p,a[1]*k,a[2]*kh,a[3]*k,a[4]*kh,a[5],a[6],a[7],a[8]);
	};
	//patterns repeat at the picture's own size, so they keep the original
})();
