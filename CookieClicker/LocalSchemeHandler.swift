import Foundation
import WebKit

/// Serves the game's files from the app bundle under cookieclicker://app/...
/// Requests for `cordova.js` get the iOS bridge script instead of Android's Cordova runtime.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "cookieclicker"
    static let startURL = URL(string: "\(scheme)://app/index.html")!

    private let root: URL = Bundle.main.resourceURL!.appendingPathComponent("www", isDirectory: true)

    private static let mimeTypes: [String: String] = [
        "html": "text/html", "js": "text/javascript", "css": "text/css",
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif",
        "ico": "image/x-icon", "mp3": "audio/mpeg", "ttf": "font/ttf", "json": "application/json",
        "txt": "text/plain", "xml": "text/xml",
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
        } else {
            let fileURL = root.appendingPathComponent(path).standardizedFileURL
            if fileURL.path.hasPrefix(root.standardizedFileURL.path) {
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
}
