import UIKit
import WebKit
import UniformTypeIdentifiers

/// Native side of the plugins the game calls through Cordova on Android:
/// save files, save export/import, and opening links.
final class NativeBridge: NSObject, WKScriptMessageHandlerWithReply {
    static let name = "native"

    weak var viewController: UIViewController?
    weak var webView: WKWebView?

    private var pendingPick: ((Any?, String?) -> Void)?

    /// Save files live here (the iOS equivalent of Cordova's dataDirectory).
    private lazy var savesDir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Saves", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private func saveURL(_ name: Any?) -> URL? {
        guard let name = name as? String else { return nil }
        let clean = (name as NSString).lastPathComponent
        guard !clean.isEmpty, clean != ".", clean != ".." else { return nil }
        return savesDir.appendingPathComponent(clean)
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        guard let body = message.body as? [String: Any], let action = body["action"] as? String else {
            return replyHandler(nil, "Bad message")
        }
        let args = body["args"] as? [String: Any] ?? [:]
        let fm = FileManager.default

        switch action {
        case "getFile":
            guard let url = saveURL(args["name"]) else { return replyHandler(false, nil) }
            if !fm.fileExists(atPath: url.path) {
                if (args["create"] as? Bool) == true {
                    fm.createFile(atPath: url.path, contents: Data())
                } else {
                    return replyHandler(false, nil)
                }
            }
            replyHandler(true, nil)

        case "readFile":
            guard let url = saveURL(args["name"]),
                  let data = try? Data(contentsOf: url) else { return replyHandler("", nil) }
            replyHandler(String(decoding: data, as: UTF8.self), nil)

        case "writeFile":
            guard let url = saveURL(args["name"]) else { return replyHandler(nil, "Bad file name") }
            let text = args["data"] as? String ?? ""
            do {
                try Data(text.utf8).write(to: url, options: .atomic)
                replyHandler(true, nil)
            } catch {
                replyHandler(nil, error.localizedDescription)
            }

        case "removeFile":
            if let url = saveURL(args["name"]) { try? fm.removeItem(at: url) }
            replyHandler(true, nil)

        case "copyFile":
            guard let from = saveURL(args["name"]), let to = saveURL(args["to"]) else {
                return replyHandler(nil, "Bad file name")
            }
            try? fm.removeItem(at: to)
            do {
                try fm.copyItem(at: from, to: to)
                replyHandler(true, nil)
            } catch {
                replyHandler(nil, error.localizedDescription)
            }

        case "listFiles":
            let names = (try? fm.contentsOfDirectory(atPath: savesDir.path)) ?? []
            replyHandler(names, nil)

        case "openURL":
            if let s = args["url"] as? String, let url = URL(string: s) { UIApplication.shared.open(url) }
            replyHandler(true, nil)

        case "saveFile":
            exportSave(base64: args["data"] as? String ?? "", filename: args["filename"] as? String,
                       reply: replyHandler)

        case "selectFile":
            pickFile(reply: replyHandler)

        case "getFileName":
            guard let s = args["uri"] as? String, let url = URL(string: s) else { return replyHandler(nil, "No file.") }
            replyHandler(url.lastPathComponent, nil)

        case "readPickedFile":
            guard let s = args["uri"] as? String, let url = URL(string: s) else { return replyHandler(nil, "No file.") }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return replyHandler(nil, "Couldn't read file.") }
            replyHandler(data.base64EncodedString(), nil)

        default:
            replyHandler(nil, "Unknown action \(action)")
        }
    }

    // MARK: - Export save (share sheet)

    private func exportSave(base64: String, filename: String?, reply: @escaping (Any?, String?) -> Void) {
        guard let data = Data(base64Encoded: base64), let vc = viewController else {
            return reply(nil, "Couldn't export.")
        }
        let name = ((filename ?? "CookieClickerSave.txt") as NSString).lastPathComponent
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return reply(nil, error.localizedDescription)
        }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = vc.view
            pop.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        vc.present(sheet, animated: true)
        reply(true, nil)
    }

    // MARK: - Import save (file picker)

    private func pickFile(reply: @escaping (Any?, String?) -> Void) {
        guard let vc = viewController else { return reply(nil, "No file.") }
        pendingPick?(nil, "Cancelled")
        pendingPick = reply
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        vc.present(picker, animated: true)
    }
}

extension NativeBridge: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            pendingPick?(url.absoluteString, nil)
        } else {
            pendingPick?(nil, "No file.")
        }
        pendingPick = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pendingPick?(nil, "Cancelled")
        pendingPick = nil
    }
}
