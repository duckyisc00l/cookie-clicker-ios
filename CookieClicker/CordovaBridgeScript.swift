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

  // what Cordova does once its plugins are ready
  document.addEventListener('DOMContentLoaded', function(){
    setTimeout(function(){ document.dispatchEvent(new Event('deviceready')); }, 0);
  });
})();
"""#
}
