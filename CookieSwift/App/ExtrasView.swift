import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// What the extras screen needs from the game.
protocol GameHost: AnyObject {
    /// The current save as JSON, the same save packed small (for QR codes), and the cookie count.
    func currentSave(_ completion: @escaping (_ json: String?, _ compact: String?, _ cookies: String?) -> Void)
    /// Checks a save, asks to confirm, then loads it into the game.
    func receiveSave(_ json: String)
    func backUpNow(_ completion: ((Bool) -> Void)?)
    func applySettings()
}

struct ExtrasView: View {
    weak var host: GameHost?
    var close: () -> Void

    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var backups = BackupManager.shared

    private enum Sheet: Identifiable {
        case share(UIImage, Int)
        case receive
        var id: String {
            switch self {
            case .share: return "share"
            case .receive: return "receive"
            }
        }
    }
    @State private var sheet: Sheet?
    @State private var showImporter = false
    @State private var importingFolder = true
    @State private var note: String?
    @State private var working = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display"), footer: Text("120 Hz makes scrolling and the game's effects smoother on iPhones with ProMotion. The game itself still runs at its normal speed.")) {
                    Toggle("120 Hz smooth motion", isOn: $settings.highRefresh)
                    Toggle("Keep screen awake", isOn: $settings.keepAwake)
                }

                Section(header: Text("Sugar lumps & garden"), footer: Text("Auto-harvest picks your sugar lump as soon as it's ripe while the game is open. The notification tells you when it's ripe while the game is closed. Garden messages pop up in the game when plants are ready or about to wither (the garden only grows while the game is open).")) {
                    Toggle("Auto-harvest sugar lumps", isOn: $settings.autoHarvest)
                    Toggle("Notify me when a lump is ripe", isOn: $settings.lumpNotify)
                    Toggle("Garden messages", isOn: $settings.gardenAlerts)
                }

                Section(header: Text("Live Activity"), footer: Text(LiveActivityManager.shared.isAvailable || !settings.liveActivity
                    ? "Shows your cookies on the Lock Screen and in the Dynamic Island. It updates while you play."
                    : "Live Activities are turned off for this app. Turn them on in Settings → Cookie Clicker.")) {
                    Toggle("Show on Lock Screen", isOn: $settings.liveActivity)
                }

                Section(header: Text("iCloud backup"), footer: Text("Pick a folder in iCloud Drive once. Your save is backed up there when you leave the app and every 10 minutes while you play. The last 10 backups are kept. Backups also work with the game's own \"Import save file...\" button.")) {
                    Button {
                        importingFolder = true
                        showImporter = true
                    } label: {
                        HStack {
                            Text(backups.folderName == nil ? "Choose backup folder…" : "Backup folder")
                            Spacer()
                            if let name = backups.folderName { Text(name).foregroundColor(.secondary) }
                        }
                    }
                    if backups.folderName != nil {
                        Toggle("Back up automatically", isOn: $settings.autoBackup)
                        Button(backups.isBackingUp ? "Backing up…" : "Back up now") {
                            host?.backUpNow(nil)
                        }
                        .disabled(backups.isBackingUp)
                    }
                    Button("Restore a backup…") {
                        importingFolder = false
                        showImporter = true
                    }
                    if let last = backups.lastBackup {
                        HStack {
                            Text("Last backup")
                            Spacer()
                            Text(last, style: .relative).foregroundColor(.secondary)
                            Text("ago").foregroundColor(.secondary)
                        }
                    }
                    if let error = backups.lastError {
                        Text(error).font(.footnote).foregroundColor(.red)
                    }
                }

                Section(header: Text("Move your save to another phone"), footer: Text("\"Send\" shows your save as a picture of QR codes. On the other phone, choose \"Receive\" and point the camera at it, or pick a screenshot or photo of it from the photo library.")) {
                    Button(working ? "Making QR codes…" : "Send my save (QR codes)") { makeQRCodes() }
                        .disabled(working)
                    Button("Receive a save") { sheet = .receive }
                }

                if let note = note {
                    Section { Text(note).font(.footnote) }
                }
            }
            .navigationTitle("iPhone extras")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done", action: close) }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: settings.highRefresh) { _ in host?.applySettings() }
        .onChange(of: settings.keepAwake) { _ in host?.applySettings() }
        .onChange(of: settings.liveActivity) { _ in host?.applySettings() }
        .onChange(of: settings.autoHarvest) { _ in host?.applySettings() }
        .onChange(of: settings.lumpNotify) { _ in host?.applySettings() }
        .onChange(of: settings.gardenAlerts) { _ in host?.applySettings() }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: importingFolder ? [.folder] : [.plainText, .text, .data],
                      allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            if importingFolder {
                backups.setFolder(url)
                if backups.folderName != nil { host?.backUpNow(nil) }
            } else {
                restore(from: url)
            }
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .share(let image, let count):
                QRShareView(image: image, codeCount: count)
            case .receive:
                ReceiveSaveView { json in
                    sheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { host?.receiveSave(json) }
                }
            }
        }
    }

    private func makeQRCodes() {
        working = true
        host?.currentSave { _, compact, cookies in
            DispatchQueue.global(qos: .userInitiated).async {
                let payloads = compact.flatMap { SaveTransfer.payloads(forSaveJSON: $0) }
                let image = payloads.flatMap { SaveTransfer.sheetImage(payloads: $0, cookies: cookies) }
                DispatchQueue.main.async {
                    working = false
                    if let image = image, let payloads = payloads {
                        sheet = .share(image, payloads.count)
                    } else {
                        note = "Couldn't make the QR codes. Try again in a moment."
                    }
                }
            }
        }
    }

    private func restore(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), var text = String(data: data, encoding: .utf8) else {
            note = "Couldn't read that file."
            return
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.hasPrefix("{"), let decoded = Data(base64Encoded: text), let json = String(data: decoded, encoding: .utf8) {
            text = json
        }
        host?.receiveSave(text)
    }
}

// MARK: - Sending: the QR code picture

private struct QRShareView: View {
    let image: UIImage
    let codeCount: Int
    @Environment(\.presentationMode) private var presentationMode
    @State private var saved = false
    @State private var sharing = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text("On the other phone: Misc → iPhone extras → Receive a save. Point its camera here, or save this picture (or take a screenshot) and pick it from Photos there.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        saved = true
                    } label: {
                        Label(saved ? "Saved to Photos" : "Save to Photos", systemImage: saved ? "checkmark" : "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        sharing = true
                    } label: {
                        Label("Share…", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Send my save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { presentationMode.wrappedValue.dismiss() } }
            }
            .sheet(isPresented: $sharing) { ActivitySheet(items: [image]) }
            .preferredColorScheme(.light)
        }
        .navigationViewStyle(.stack)
    }
}

private struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Receiving: camera or a photo

private struct ReceiveSaveView: View {
    let onSave: (String) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var collector = SaveCollector()
    @State private var pickingPhoto = false
    @State private var status = "Point the camera at the QR codes on the other phone."
    @State private var done = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                QRCameraView { codes in handle(codes) }
                    .ignoresSafeArea(edges: .bottom)
                VStack(spacing: 12) {
                    Text(collector.total > 0 ? "Found \(collector.found) of \(collector.total) codes" : status)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    if collector.total > 0 && collector.found < collector.total {
                        Text("Keep the camera on the codes, or move it around until every code has been read.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    Button {
                        pickingPhoto = true
                    } label: {
                        Label("Scan a photo instead", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .padding()
            }
            .navigationTitle("Receive a save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { presentationMode.wrappedValue.dismiss() } }
            }
            .sheet(isPresented: $pickingPhoto) {
                PhotoPicker { image in
                    pickingPhoto = false
                    guard let image = image else { return }
                    DispatchQueue.global(qos: .userInitiated).async {
                        let codes = SaveTransfer.readCodes(in: image)
                        DispatchQueue.main.async {
                            if codes.isEmpty { status = "No QR codes found in that picture. Try a clearer screenshot." }
                            handle(codes)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func handle(_ codes: [String]) {
        guard !done else { return }
        if let json = collector.add(codes) {
            done = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSave(json)
        }
    }
}

private struct QRCameraView: UIViewControllerRepresentable {
    let onCodes: ([String]) -> Void
    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.onCodes = onCodes
        return controller
    }
    func updateUIViewController(_ controller: QRScannerController, context: Context) {
        controller.onCodes = onCodes
    }
}

private struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage?) -> Void
        init(onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                return onPick(nil)
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async { self.onPick(object as? UIImage) }
            }
        }
    }
}
