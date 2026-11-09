import Foundation
import WebKit

/// Serves the game's files from the app bundle under cookieclicker://app/...
/// Requests for `cordova.js` get the iOS bridge script instead of Android's Cordova runtime.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "cookieclicker"
    static let startURL = URL(string: "\(scheme)://app/index.html")!

    private let root: URL = Bundle.main.resourceURL!.appendingPathComponent("www", isDirectory: true)
    private let hdRoot: URL = Bundle.main.resourceURL!.appendingPathComponent("hd", isDirectory: true)
    private let modsRoot: URL = Bundle.main.resourceURL!.appendingPathComponent("mods", isDirectory: true)

    private static func joined(_ first: URL, _ extras: [URL]) -> Data? {
        guard var data = try? Data(contentsOf: first) else { return nil }
        for url in extras {
            if let extra = try? Data(contentsOf: url) {
                data.append(Data("\n;\n".utf8))
                data.append(extra)
            }
        }
        return data
    }

    private static let mimeTypes: [String: String] = [
        "html": "text/html", "js": "text/javascript", "css": "text/css",
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif",
        "ico": "image/x-icon", "mp3": "audio/mpeg", "ttf": "font/ttf", "json": "application/json",
        "txt": "text/plain", "xml": "text/xml", "webp": "image/webp",
    ]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        var path = url.path.removingPercentEncoding ?? url.path
        if path.hasPrefix("/") { path.removeFirst() }
        if path.isEmpty { path = "index.html" }

        let data: Data?
        let ext = (path as NSString).pathExtension.lowercased()
        if path == "hd-art.js" {
            // swaps in the sharper artwork from the hd folder (used by the game and the minigames)
            data = try? Data(contentsOf: modsRoot.appendingPathComponent("hd-art.js"))
        } else if path == "cordova.js" {
            data = CordovaBridgeScript.source.data(using: .utf8)
        } else if path == "index.html" {
            data = Self.sharpIndexHTML(from: root.appendingPathComponent("index.html"))
        } else if path == "lib/main.js" {
            data = Self.smoothScrollingLib(from: root.appendingPathComponent("lib/main.js"))
        } else if path == "main.js" || path == "test_main.js" {
            data = Self.patchedMainJS(from: root.appendingPathComponent(path))
        } else if path == "data.js" || path == "test_data.js" {
            // the game's data, followed by the extra buildings, upgrades and cookies
            data = Self.joined(root.appendingPathComponent(path), [
                modsRoot.appendingPathComponent("more-content.js"),
                modsRoot.appendingPathComponent("sugar-lumps.js"),
                modsRoot.appendingPathComponent("minigame-bridge.js"),
                modsRoot.appendingPathComponent("reminders.js"),
            ])
        } else if path.hasPrefix("minigames/") {
            // the minigame page and the desktop files it uses; anything else (art, sounds) comes from the game
            let rest = String(path.dropFirst("minigames/".count))
            let mg = modsRoot.appendingPathComponent("minigames").appendingPathComponent(rest).standardizedFileURL
            if mg.path.hasPrefix(modsRoot.standardizedFileURL.path), let d = try? Data(contentsOf: mg) {
                data = d
            } else if rest == "img/icons.png" || rest == "img/buildings.png" {
                data = (try? Data(contentsOf: modsRoot.appendingPathComponent((rest as NSString).lastPathComponent)))
                    ?? (try? Data(contentsOf: root.appendingPathComponent(rest)))
            } else {
                let f = root.appendingPathComponent(rest).standardizedFileURL
                data = f.path.hasPrefix(root.standardizedFileURL.path) ? try? Data(contentsOf: f) : nil
            }
        } else if path == "img/icons.png" || path == "img/buildings.png" {
            // the same sprite sheets with the new art added in extra columns/rows
            data = (try? Data(contentsOf: modsRoot.appendingPathComponent((path as NSString).lastPathComponent)))
                ?? (try? Data(contentsOf: root.appendingPathComponent(path)))
        } else {
            // "hd/..." is the folder of sharper artwork; everything else comes from the game's www folder
            let base = path.hasPrefix("hd/") ? hdRoot : root
            let relative = path.hasPrefix("hd/") ? String(path.dropFirst(3)) : path
            let fileURL = base.appendingPathComponent(relative).standardizedFileURL
            if fileURL.path.hasPrefix(base.standardizedFileURL.path) {
                data = try? Data(contentsOf: fileURL)
            } else {
                data = nil
            }
        }

        let status = data == nil ? 404 : 200
        var headers = [
            "Content-Type": Self.mimeTypes[ext] ?? "application/octet-stream",
            "Content-Length": String(data?.count ?? 0),
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "no-cache",
        ]
        if ext == "html" || ext == "js" || ext == "css" { headers["Content-Type"]! += "; charset=utf-8" }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data ?? Data())
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    /// Changes to the game's main.js, applied as it's served (the file on disk stays original).
    /// Each change is only made if its exact original text is found once.
    private static func patchedMainJS(from url: URL) -> Data? {
        guard let data = try? Data(contentsOf: url), var js = String(data: data, encoding: .utf8) else { return nil }
        let patches: [(old: String, new: String, all: Bool)] = [
            // golden cookie building buffs need a name pair for each new building
            ("'You':['Deduplication','Clone strike'],",
             "'You':['Deduplication','Clone strike'],'Black hole':['Event horizon','Evaporation'],'Galaxy':['Starburst','Galactic drift'],'Multiverse mixer':['Perfect blend','Lumpy batter'],'Big bang':['Cosmic dawn','Heat death'],",
             false),
            // sugar lumps are saved with the rest of the game
            ("'tippedN'];",
             "'tippedN','lumps','lumpsTotal','lumpT','lumpCurrentType','lumpRefill','cookiesPsRawHighest'];",
             false),
            // building levels are saved and loaded with each building
            ("var transfer=['amount','amountMax','bought','cookiesMade'];",
             "var transfer=['amount','amountMax','bought','cookiesMade','level','minigameSave'];",
             true),
            // each building level gives +1% to that building
            ("myCps=(myCps+G.pool['building'+me.id+'A'])*G.pool['building'+me.id+'M'];",
             "myCps=(myCps+G.pool['building'+me.id+'A'])*G.pool['building'+me.id+'M']*(1+(me.level||0)*0.01);",
             false),
            // minigame effects (garden plants, gods) apply while computing CpS
            ("G.pool['clickM']*=1+G.auraMult('Dragon Cursor')*0.05;",
             "if (window.__ccMinigameEffs) window.__ccMinigameEffs(G.pool);G.pool['clickM']*=1+G.auraMult('Dragon Cursor')*0.05;",
             false),
            // level section in each building's info popup
            ("<p class=\"switchTopIn\" style=\"text-align:right;color:rgba(255,255,255,0.65);\"><q>${me.getDesc()}</q></p>",
             "${window.__ccLevelBox?window.__ccLevelBox(me):''}<p class=\"switchTopIn\" style=\"text-align:right;color:rgba(255,255,255,0.65);\"><q>${me.getDesc()}</q></p>",
             false),
        ]
        for patch in patches {
            let count = js.components(separatedBy: patch.old).count - 1
            guard patch.all ? count >= 1 : count == 1 else { continue }
            js = js.replacingOccurrences(of: patch.old, with: patch.new)
        }
        return js.data(using: .utf8)
    }

    /// The upgrades list only builds the rows on screen and checks the scroll position 4 times a second,
    /// so fast scrolling shows empty space and late, fading rows. Build 6 extra rows above and below,
    /// rebuild as soon as you scroll, and don't fade rows that appear from scrolling.
    /// Each change only applies if the exact original code is found; otherwise the file is served unchanged.
    private static func smoothScrollingLib(from url: URL) -> Data? {
        guard let data = try? Data(contentsOf: url), var js = String(data: data, encoding: .utf8) else { return nil }
        let patches: [(String, String)] = [
            ("\tfirst=Math.max(0,Math.floor(offY/obj.itemH));",
             "\tfirst=Math.max(0,Math.floor(offY/obj.itemH)-6);"),
            ("\tlast=Math.min(data.length,first+Math.ceil(h/obj.itemH+1));",
             "\tlast=Math.min(data.length,Math.floor(offY/obj.itemH)+Math.ceil(h/obj.itemH+1)+6);"),
            ("let redrawI=0;",
             "let redrawI=0;el.addEventListener('scroll',function(){if(Math.abs(scrollYonLastRender-el.scrollTop)>=obj.itemH*3){scrollY=el.scrollTop;oldData=data;data=obj.dataFunc();oldView=data.slice();render();}},{passive:true});"),
        ]
        guard patches.allSatisfy({ js.components(separatedBy: $0.0).count == 2 }) else { return data }
        for (old, new) in patches { js = js.replacingOccurrences(of: old, with: new) }
        return js.data(using: .utf8)
    }

    /// The game lays itself out 320 units wide and normally blows that up with a CSS scale, which
    /// renders at 320px and then stretches the picture (blurry). Telling iOS the page is 320 wide
    /// makes iOS zoom the page itself, so everything is drawn at the screen's real resolution.
    private static func sharpIndexHTML(from url: URL) -> Data? {
        guard let data = try? Data(contentsOf: url), var html = String(data: data, encoding: .utf8) else { return nil }
        if let regex = try? NSRegularExpression(pattern: "<meta name=\"viewport\"[^>]*>", options: [.caseInsensitive]) {
            let range = NSRange(html.startIndex..., in: html)
            html = regex.stringByReplacingMatches(
                in: html, options: [], range: range,
                withTemplate: "<meta name=\"viewport\" content=\"width=320, user-scalable=no, viewport-fit=cover\">")
        }
        return html.data(using: .utf8)
    }
}
