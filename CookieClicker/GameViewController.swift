import UIKit
import WebKit
import SwiftUI

/// Full-screen web view that runs the game files from the APK (bundled in the `www` folder).
final class GameViewController: UIViewController {
    private var webView: WKWebView!
    private var bridge: NativeBridge!

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: LocalSchemeHandler.scheme)
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsInlineMediaPlayback = true
        config.websiteDataStore = .default()

        bridge = NativeBridge()
        config.userContentController.addScriptMessageHandler(bridge, contentWorld: .page, name: NativeBridge.name)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsLinkPreview = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        HighRefresh.apply(AppSettings.shared.highRefresh, to: config.preferences)
        bridge.viewController = self
        bridge.webView = webView
        bridge.onOpenExtras = { [weak self] in self?.openExtras() }
        bridge.onStats = { stats in
            LiveActivityManager.shared.gameStats(
                cookies: stats["cookies"] as? String ?? "0",
                short: stats["short"] as? String ?? "0",
                perSecond: stats["cps"] as? String ?? "0")
        }

        let root = UIView()
        root.backgroundColor = .black
        root.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        // Fill the whole screen, edge to edge; the game keeps its UI clear of the notch and home bar.
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            webView.topAnchor.constraint(equalTo: root.topAnchor),
            webView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: LocalSchemeHandler.startURL))
        applySettings()

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(appBecameActive),
                           name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(appWillLeave),
                           name: UIApplication.willResignActiveNotification, object: nil)
        // regular backups while playing
        backupTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.autoBackup()
        }
    }

    private var backupTimer: Timer?

    @objc private func appBecameActive() {
        applySettings()
        GameNotifications.shared.clear()
    }

    /// Leaving the app: back up the save and send the latest numbers to the Live Activity.
    @objc private func appWillLeave() {
        LiveActivityManager.shared.push()
        webView.evaluateJavaScript("window.__ccLumpInfo ? window.__ccLumpInfo() : null") { result, _ in
            guard let info = result as? [String: Any],
                  let ripeAt = (info["ripeAt"] as? NSNumber)?.doubleValue,
                  let now = (info["now"] as? NSNumber)?.doubleValue else { return }
            GameNotifications.shared.scheduleLump(ripeAt: ripeAt, now: now,
                                                  autoHarvest: (info["autoHarvest"] as? Bool) ?? true)
        }
        let task = UIApplication.shared.beginBackgroundTask(withName: "backup", expirationHandler: nil)
        autoBackup { _ in UIApplication.shared.endBackgroundTask(task) }
    }

    private func autoBackup(_ completion: ((Bool) -> Void)? = nil) {
        guard AppSettings.shared.autoBackup, BackupManager.shared.hasFolder else {
            completion?(false)
            return
        }
        backUpNow(completion)
    }

    private weak var extrasController: UIViewController?

    private func openExtras() {
        guard extrasController == nil else { return }
        let view = ExtrasView(host: self, close: { [weak self] in self?.dismiss(animated: true) })
        let controller = UIHostingController(rootView: view)
        extrasController = controller
        present(controller, animated: true)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        sendSafeArea()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sendSafeArea()
    }

    private var lastSentInsets: UIEdgeInsets?
    private var lastSentWidth: CGFloat = 0

    /// Tells the game how much room the notch and home bar take up.
    fileprivate func sendSafeArea(force: Bool = false) {
        let insets = view.safeAreaInsets
        let width = view.bounds.width
        guard force || insets != lastSentInsets || width != lastSentWidth else { return }
        lastSentInsets = insets
        lastSentWidth = width
        webView?.evaluateJavaScript(
            "window.__ccSafeInsets && window.__ccSafeInsets(\(insets.top), \(insets.bottom), \(width));",
            completionHandler: nil)
    }
}

extension GameViewController: GameHost {
    func applySettings() {
        let settings = AppSettings.shared
        UIApplication.shared.isIdleTimerDisabled = settings.keepAwake
        if let prefs = webView?.configuration.preferences { HighRefresh.apply(settings.highRefresh, to: prefs) }
        if !settings.liveActivity { LiveActivityManager.shared.endAll() }
        sendGameSettings()
        GameNotifications.shared.askPermissionIfNeeded()
    }

    /// Tells the game about the settings it uses itself (auto-harvest, garden messages).
    private func sendGameSettings() {
        let s = AppSettings.shared
        webView?.evaluateJavaScript("window.__ccSettings={autoHarvest:\(s.autoHarvest),gardenAlerts:\(s.gardenAlerts)};", completionHandler: nil)
    }

    func currentSave(_ completion: @escaping (String?, String?, String?) -> Void) {
        webView.evaluateJavaScript("window.__ccExportSave ? window.__ccExportSave() : null") { result, _ in
            let info = result as? [String: Any]
            completion(info?["json"] as? String, info?["compact"] as? String, info?["cookies"] as? String)
        }
    }

    func backUpNow(_ completion: ((Bool) -> Void)?) {
        currentSave { json, _, _ in
            guard let json = json else {
                completion?(false)
                return
            }
            // same format as the game's "Export save file..."
            BackupManager.shared.backUp(exportText: Data(json.utf8).base64EncodedString(), completion: completion)
        }
    }

    func receiveSave(_ json: String) {
        let ask = { [weak self] in
            guard let self = self else { return }
            self.webView.callAsyncJavaScript("return window.__ccCheckSave(text);", arguments: ["text": json],
                                              in: nil, in: .page) { result in
                let info = (try? result.get()) as? [String: Any]
                guard let info = info, (info["ok"] as? Bool) == true else {
                    let reason = info?["error"] as? String ?? "That doesn't look like a Cookie Clicker save."
                    self.showMessage(title: "Can't load this save", message: reason)
                    return
                }
                let cookies = info["cookies"] as? String ?? "?"
                let played = info["played"] as? String ?? "?"
                let alert = UIAlertController(
                    title: "Load this save?",
                    message: "\(cookies) cookies, last played \(played) ago.\n\nThis replaces the game on this phone.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Load", style: .destructive) { _ in
                    self.webView.callAsyncJavaScript("window.__ccImportSave(text);", arguments: ["text": json],
                                                     in: nil, in: .page, completionHandler: nil)
                })
                self.present(alert, animated: true)
            }
        }
        if presentedViewController != nil { dismiss(animated: true, completion: ask) } else { ask() }
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension GameViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
        if url.scheme == LocalSchemeHandler.scheme || url.scheme == "about" || url.scheme == "blob" || url.scheme == "data" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        sendSafeArea(force: true)
        sendGameSettings()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

extension GameViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url { UIApplication.shared.open(url) }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
}
