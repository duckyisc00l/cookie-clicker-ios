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
  var safeTop = 0, safeBottom = 0;
  function applySafeArea(){
    var w = document.documentElement.clientWidth || window.innerWidth || 320;
    var k = 320 / w, s = document.documentElement.style;
    s.setProperty('--cc-sat', (safeTop * k) + 'px');
    s.setProperty('--cc-sab', (safeBottom * k) + 'px');
  }
  window.__ccSafeInsets = function(top, bottom){ safeTop = top || 0; safeBottom = bottom || 0; applySafeArea(); };
  window.addEventListener('resize', applySafeArea);
  var css = document.createElement('style');
  css.textContent = [
    '#topStuff{top:var(--cc-sat,0px);bottom:var(--cc-sab,0px);}',
    '#screens{top:var(--cc-sat,0px);bottom:calc(40px + var(--cc-sab,0px));}',
    '#tabs{box-sizing:content-box;height:40px;padding-bottom:var(--cc-sab,0px);}',
    '#tabs.bottomShelf:before{bottom:calc(var(--cc-sab,0px) - 3px);}',
    '#tabs.bottomShelf:after{content:"";pointer-events:none;position:absolute;left:0;right:0;bottom:0;' +
      'height:var(--cc-sab,0px);background:url(img/bottomShelf.png) center bottom -3px / 320px 73px no-repeat;transform:scaleY(-1);z-index:-1;}',
    '.popup{margin-top:calc(60px + var(--cc-sat,0px));margin-bottom:calc(44px + var(--cc-sab,0px));}'
  ].join('\n');
  (document.head || document.documentElement).appendChild(css);

  // what Cordova does once its plugins are ready
  document.addEventListener('DOMContentLoaded', function(){
    setTimeout(function(){ document.dispatchEvent(new Event('deviceready')); }, 0);
  });
})();
"""#
}
