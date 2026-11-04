import Foundation

/// Served in place of the APK's `cordova.js`. It gives the game the same `cordova` object it
/// expects on Android, with every call forwarded to `NativeBridge` in Swift.
enum CordovaBridgeScript {
    static let source = #"""
(function(){
  function call(action, args){
    return window.webkit.messageHandlers.native.postMessage({action: action, args: args || {}});
  }
  function noop(){}

  // --- cordova-plugin-file (save files) ---
  function FileEntry(name){ this.name = name; this.isFile = true; this.isDirectory = false; this.fullPath = '/' + name; }
  FileEntry.prototype.file = function(win, fail){
    call('readFile', {name: this.name})
      .then(function(text){ win(new Blob([text || ''], {type: 'text/plain'})); }, fail || noop);
  };
  FileEntry.prototype.createWriter = function(win, fail){
    var name = this.name;
    var writer = {
      onwriteend: null, onerror: null,
      write: function(data){
        var w = this;
        var textPromise = (data instanceof Blob) ? data.text() : Promise.resolve(String(data));
        textPromise
          .then(function(text){ return call('writeFile', {name: name, data: text}); })
          .then(function(){ if (w.onwriteend) w.onwriteend({}); },
                function(e){ if (w.onerror) w.onerror(e); });
      }
    };
    win(writer);
  };
  FileEntry.prototype.remove = function(win, fail){ call('removeFile', {name: this.name}).then(win || noop, fail || noop); };
  FileEntry.prototype.copyTo = function(dir, newName, win, fail){
    call('copyFile', {name: this.name, to: newName})
      .then(function(){ (win || noop)(new FileEntry(newName)); }, fail || noop);
  };

  function DirectoryEntry(){ this.isFile = false; this.isDirectory = true; this.name = 'files'; this.fullPath = '/'; }
  DirectoryEntry.prototype.getFile = function(name, opts, win, fail){
    call('getFile', {name: name, create: !!(opts && opts.create)})
      .then(function(ok){ if (ok) (win || noop)(new FileEntry(name)); else (fail || noop)({code: 1}); }, fail || noop);
  };
  DirectoryEntry.prototype.createReader = function(){
    return { readEntries: function(win, fail){
      call('listFiles').then(function(names){ win(names.map(function(n){ return new FileEntry(n); })); }, fail || noop);
    }};
  };

  window.resolveLocalFileSystemURL = function(url, win, fail){ setTimeout(function(){ win(new DirectoryEntry()); }, 0); };
  window.LocalFileSystem = {PERSISTENT: 1, TEMPORARY: 0};

  // --- the cordova object the game uses ---
  window.cordova = {
    platformId: 'ios',
    file: { dataDirectory: 'cdvfile://localhost/library-nosync/' },
    InAppBrowser: { open: function(url){ call('openURL', {url: url}); return {}; } },
    plugins: {
      safMediastore: {
        saveFile: function(o){ return call('saveFile', {data: o.data, filename: o.filename}); },
        selectFile: function(){ return call('selectFile'); },
        getFileName: function(uri){ return call('getFileName', {uri: uri}); },
        readFile: function(uri){
          return call('readPickedFile', {uri: uri}).then(function(b64){
            var s = atob(b64), a = new Uint8Array(s.length);
            for (var i = 0; i < s.length; i++) a[i] = s.charCodeAt(i);
            return a.buffer;
          });
        }
      },
      diagnostic: { restart: function(){ location.reload(); } }
    }
  };

  // iOS keeps web audio muted until the first touch
  ['touchstart', 'touchend'].forEach(function(type){
    document.addEventListener(type, function(){
      try { if (typeof AudioCtx !== 'undefined' && AudioCtx.state !== 'running') AudioCtx.resume(); } catch (e) {}
    }, true);
  });

  // --- edge-to-edge on notched iPhones ---
  // Backgrounds fill the whole screen; the top bar, screens, popups and tabs are kept clear of the
  // notch and home bar. Swift sends the safe-area sizes; they're converted to the game's 320px-wide units.
  var safeTop = 0, safeBottom = 0, screenWidth = 0;
  function applySafeArea(){
    // insets arrive in screen points; the game's layout is 320 units across the screen width
    var w = screenWidth || ((document.documentElement.clientWidth || 320) * ((window.visualViewport && window.visualViewport.scale) || 1));
    var k = 320 / w, s = document.documentElement.style;
    s.setProperty('--cc-sat', (safeTop * k) + 'px');
    s.setProperty('--cc-sab', (safeBottom * k) + 'px');
  }
  window.__ccSafeInsets = function(top, bottom, width){
    safeTop = top || 0; safeBottom = bottom || 0; screenWidth = width || 0; applySafeArea();
  };
  window.addEventListener('resize', applySafeArea);
  var css = document.createElement('style');
  css.textContent = [
    '#topStuff{top:var(--cc-sat,0px);bottom:var(--cc-sab,0px);}',
    '#screens{top:var(--cc-sat,0px);bottom:calc(40px + var(--cc-sab,0px));}',
    '#tabs{box-sizing:content-box;height:40px;padding-bottom:var(--cc-sab,0px);}',
    '#tabs.bottomShelf:before{bottom:calc(var(--cc-sab,0px) - 3px);}',
    '#tabs.bottomShelf:after{content:"";pointer-events:none;position:absolute;left:0;right:0;bottom:0;' +
      'height:var(--cc-sab,0px);background:url(hd/bottomShelf.webp) center bottom -3px / 320px 73px no-repeat;transform:scaleY(-1);z-index:-1;}',
    '.popup{margin-top:calc(60px + var(--cc-sat,0px));margin-bottom:calc(44px + var(--cc-sab,0px));}',
    'html{-webkit-text-size-adjust:100%;text-size-adjust:100%;}',
    // The 3D look is only needed during the 0.2s tab-switch animation. Keeping it on all the time stops
    // iOS from scrolling the store lists on its fast path, so icons and text trail behind the scroll.
    '#screens:not(:has(.switchLeft,.switchLeftIn,.switchRight,.switchRightIn,.switchTopIn)){perspective:none;}',
    '#screens:not(:has(.switchLeft,.switchLeftIn,.switchRight,.switchRightIn,.switchTopIn)) .sectionTrimOverlay{transform:none;}',
    '.storeList{will-change:scroll-position;}'
  ].join('\n');
  (document.head || document.documentElement).appendChild(css);

  // --- sharp canvases ---
  // The falling cookies (#rain) and the cursor ring (#cursorCanvas) are drawn on canvases sized in the
  // game's 320-wide units. Give them device-resolution pixels; the game still sees its usual sizes.
  function pixelScale(){
    var dpr = window.devicePixelRatio || 1;
    var zoom = (window.visualViewport && window.visualViewport.scale) || 1;
    return Math.max(1, Math.min(4, dpr * zoom));
  }
  var CW = Object.getOwnPropertyDescriptor(HTMLCanvasElement.prototype, 'width');
  var CH = Object.getOwnPropertyDescriptor(HTMLCanvasElement.prototype, 'height');
  var getCtx = HTMLCanvasElement.prototype.getContext;
  var sharpIds = { rain: true, cursorCanvas: true };
  HTMLCanvasElement.prototype.getContext = function(type){
    var ctx = getCtx.apply(this, arguments);
    if (type !== '2d' || !ctx || this.__sharp || !sharpIds[this.id]) return ctx;
    var canvas = this, k = pixelScale();
    var lw = CW.get.call(canvas), lh = CH.get.call(canvas);
    var setT = ctx.setTransform, resetT = ctx.resetTransform;
    function base(){ setT.call(ctx, k, 0, 0, k, 0, 0); ctx.imageSmoothingQuality = 'high'; }
    function resize(){
      CW.set.call(canvas, Math.round(lw * k));
      CH.set.call(canvas, Math.round(lh * k));
      canvas.style.width = lw + 'px';
      canvas.style.height = lh + 'px';
      base();
    }
    Object.defineProperty(canvas, 'width', { configurable: true, get: function(){ return lw; }, set: function(v){ lw = +v || 0; resize(); } });
    Object.defineProperty(canvas, 'height', { configurable: true, get: function(){ return lh; }, set: function(v){ lh = +v || 0; resize(); } });
    ctx.setTransform = function(a, b, c, d, e, f){
      if (typeof a !== 'number') { setT.apply(ctx, arguments); var m = ctx.getTransform(); a = m.a; b = m.b; c = m.c; d = m.d; e = m.e; f = m.f; }
      setT.call(ctx, a * k, b * k, c * k, d * k, e * k, f * k);
    };
    ctx.resetTransform = base;
    canvas.__sharp = true;
    resize();
    return ctx;
  };

  // --- sharper artwork ---
  // AI-upscaled copies of the main artwork live in the app's hd folder. Each is shown at exactly
  // the original's on-screen size, so only the sharpness changes. The originals in www are untouched.
  var hdCss = document.createElement('style');
  hdCss.textContent = [
    '#bigCookie{background-image:url(hd/perfectCookie.webp);}',
    '#back,#back2{background-image:url(hd/bgBlue.webp);background-size:512px 512px;}',
    '.bottomShelf:before{background-image:url(hd/bottomShelf.webp);}',
    '.storeList,.storeList .scrollableListContents{background-image:url(hd/marbleSlabs.webp),url(hd/marbleSolid.webp);}',
    '.nameBox{background-image:linear-gradient(0deg,rgba(0,0,0,0.5),rgba(0,0,0,0.1)),url(hd/marbleSolid.webp);}',
    '.popup{background-image:url(hd/darkNoise.webp);background-size:512px 512px;}',
    '.woodBG{background-image:url(hd/woodPanels.webp);}',
    '.buildingIcon{background-image:url(hd/buildings.webp);background-size:256px 1600px;}'
  ].join('\n');
  (document.head || document.documentElement).appendChild(hdCss);

  // --- store rows scroll in sync with their background ---
  // The game paints the stone slabs on the scrolling list itself ("background-attachment: local").
  // iOS can't move that kind of background on its fast scrolling path, so the slabs trail the rows'
  // icons and text. Paint the same slab slice on each row (and on the upgrades list's full-height
  // spacer) instead, so the picture is part of what scrolls. It looks the same as before.
  var rowCss = [
    '.storeList > .bar{background-image:url(hd/marbleSlabs.webp),url(hd/marbleSolid.webp);background-size:346px;' +
      'height:49px;margin-bottom:0;border-bottom:1px solid transparent;isolation:isolate;}',
    '.storeList > .bar.cantAfford,.storeList > .bar.mysterious{background-color:transparent;}',
    '.storeList > .bar.cantAfford:before,.storeList > .bar.mysterious:before{content:"";position:absolute;' +
      'left:0;right:0;top:0;bottom:0;background:rgba(50,50,50,0.6);z-index:-1;pointer-events:none;}',
    '.storeList .scrollableListFiller{visibility:visible;background-image:url(hd/marbleSlabs.webp),url(hd/marbleSolid.webp);background-size:346px;}'
  ];
  for (var row = 1; row <= 80; row++) {
    rowCss.push('.storeList > .bar:nth-child(' + row + '){background-position:0 ' + (-(row - 1) * 49) + 'px;}');
  }
  var rowStyle = document.createElement('style');
  rowStyle.textContent = rowCss.join('\n');
  (document.head || document.documentElement).appendChild(rowStyle);

  // wallpapers and milk are switched by the game while playing; follow those changes
  var HD = null;
  function hdSwap(el){
    var bg = el.style.backgroundImage;
    if (!HD || !bg || bg.indexOf('img/') < 0) return;
    var m = /img\/([A-Za-z0-9_]+)\.(png|jpg)/.exec(bg);
    var size = m && HD[m[1] + '.' + m[2]];
    if (!size) return;
    el.style.backgroundImage = 'url(hd/' + m[1] + '.webp)';
    el.style.backgroundSize = size[0] + 'px ' + size[1] + 'px';
  }
  function watchArt(){
    var missing = false;
    ['back', 'back2', 'milk'].forEach(function(id){
      var el = document.getElementById(id);
      if (!el) { missing = true; return; }
      if (el.__hdWatched) return;
      el.__hdWatched = true;
      new MutationObserver(function(){ hdSwap(el); }).observe(el, { attributes: true, attributeFilter: ['style'] });
      hdSwap(el);
    });
    if (missing) setTimeout(watchArt, 300);
  }
  fetch('hd/manifest.json').then(function(r){ return r.json(); }).then(function(map){ HD = map; watchArt(); }).catch(function(){});

  // --- iPhone extras ---
  // Save export/check/import for backups and QR transfer (same data as the game's own Export/Import).
  // Packs the long upgrade/achievement lists ({"0":3,"1":0,...}) into bits so a save fits in one QR code.
  // Lossless: unpackSave gives back exactly the same save.
  function packSave(save){
    var out = {};
    Object.keys(save).forEach(function(k){
      var v = save[k], keys = (v && typeof v === 'object' && !Array.isArray(v)) ? Object.keys(v) : null;
      var packable = keys && keys.length > 16 && keys.every(function(key){
        var x = v[key]; return /^\d+$/.test(key) && x === (x | 0) && x >= 0 && x <= 3;
      });
      if (!packable) { out[k] = v; return; }
      var ids = keys.map(Number).sort(function(a, b){ return a - b; });
      var n = ids[ids.length - 1] + 1;
      var bytes = new Uint8Array(Math.ceil(n / 8) + Math.ceil(ids.length / 4));
      var base = Math.ceil(n / 8);
      ids.forEach(function(id, i){
        bytes[id >> 3] |= 1 << (id & 7);
        bytes[base + (i >> 2)] |= v[id] << ((i & 3) * 2);
      });
      var bin = ''; for (var i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
      out[k] = { '#p': btoa(bin), n: n, c: ids.length };
    });
    return out;
  }
  function unpackSave(save){
    var out = {};
    Object.keys(save).forEach(function(k){
      var v = save[k];
      if (!v || typeof v !== 'object' || typeof v['#p'] !== 'string') { out[k] = v; return; }
      var bin = atob(v['#p']), base = Math.ceil(v.n / 8), obj = {}, i = 0;
      for (var id = 0; id < v.n; id++) {
        if (bin.charCodeAt(id >> 3) >> (id & 7) & 1) {
          obj[id] = (bin.charCodeAt(base + (i >> 2)) >> ((i & 3) * 2)) & 3;
          i++;
        }
      }
      out[k] = obj;
    });
    return out;
  }
  function readSave(text){
    text = String(text).trim();
    if (text[0] !== '{') text = atob(text);
    return unpackSave(JSON.parse(text));
  }

  window.__ccExportSave = function(){
    if (!window.G || !G.Save) return null;
    var save = G.Save(true);
    return { json: JSON.stringify(save), compact: JSON.stringify(packSave(save)), cookies: B(G.cookies) };
  };
  window.__ccCheckSave = function(text){
    try {
      var d = readSave(text);
      if (!('cookies' in d) || !('buildings' in d) || !('upgrades' in d) || !('achievs' in d))
        return { ok: false, error: "That isn't a Cookie Clicker save." };
      if (d.lastVersion > VERSION) return { ok: false, error: 'That save is from a newer version of the game.' };
      return { ok: true, cookies: B(d.cookies), played: sayTime(Date.now() - d.time) };
    } catch (e) { return { ok: false, error: "Couldn't read that save." }; }
  };
  window.__ccImportSave = function(text){
    var d = readSave(text);
    if (G.closePopup) G.closePopup();
    return G.Reset(true).then(function(){ G.LoadFromObject(d); });
  };

  // numbers for the Live Activity
  var SUFFIX = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];
  function shortNumber(n){
    if (!isFinite(n)) return String(n);
    if (n < 1000) return String(Math.floor(n));
    var tier = Math.floor(Math.log10(n) / 3);
    if (tier >= SUFFIX.length) return n.toExponential(1).replace('+', '');
    var v = n / Math.pow(1000, tier);
    return (v >= 100 ? Math.floor(v) : Math.floor(v * 10) / 10) + SUFFIX[tier];
  }
  setInterval(function(){
    if (!window.G || typeof G.cookies !== 'number' || typeof B !== 'function') return;
    call('stats', { cookies: B(G.cookies), short: shortNumber(G.cookies), cps: B(G.cookiesPs, 1) }).catch(noop);
  }, 5000);

  // "iPhone extras..." button under Export/Import in the Misc screen
  setInterval(function(){
    if (document.getElementById('ccExtras')) return;
    var exportButton = Array.prototype.find.call(document.querySelectorAll('.bumpButton'), function(b){
      return b.textContent.trim() === 'Export save file...';
    });
    if (!exportButton || !exportButton.parentNode) return;
    var button = document.createElement('div');
    button.id = 'ccExtras';
    button.className = 'bumpButton';
    button.textContent = 'iPhone extras...';
    button.style.cssText = 'font-size:10px;background:rgba(0,0,0,0.25);margin-top:4px;';
    button.addEventListener('click', function(e){
      e.preventDefault();
      try { PlaySound('snd/press.mp3', 0.15); } catch (x) {}
      call('openExtras').catch(noop);
    });
    exportButton.parentNode.appendChild(document.createElement('br'));
    exportButton.parentNode.appendChild(button);
  }, 700);

  // what Cordova does once its plugins are ready
  document.addEventListener('DOMContentLoaded', function(){
    setTimeout(function(){ document.dispatchEvent(new Event('deviceready')); }, 0);
  });
})();
"""#
}
