import Foundation
import WebKit

/// Serves the game's files from the app bundle under cookieclicker://app/...
/// Requests for `cordova.js` get the iOS bridge script instead of Android's Cordova runtime.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "cookieclicker"
    static let startURL = URL(string: "\(scheme)://app/index.html")!

    private let root: URL = Bundle.main.resourceURL!.appendingPathComponent("www", isDirectory: true)
    private let hdRoot: URL = Bundle.main.resourceURL!.appendingPathComponent("hd", isDirectory: true)

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
        if path == "cordova.js" {
            data = CordovaBridgeScript.source.data(using: .utf8)
        } else if path == "index.html" {
            data = Self.sharpIndexHTML(from: root.appendingPathComponent("index.html"))
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
