import Foundation

/// Automatic save backups into a folder the player picks once (normally in iCloud Drive).
/// A free Apple ID can't give a sideloaded app its own iCloud container, so instead the app remembers
/// access to a folder chosen in the Files picker, which works the same way for iCloud Drive folders.
/// Backups use the same format as the game's own "Export save file...", so they can also be
/// restored with the game's "Import save file..." button.
final class BackupManager: ObservableObject {
    static let shared = BackupManager()

    @Published private(set) var folderName: String?
    @Published private(set) var lastBackup: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isBackingUp = false

    private let defaults = UserDefaults.standard
    private let bookmarkKey = "backupFolderBookmark"
    private let prefix = "CookieClicker Backup "
    private let keepCount = 10

    private init() {
        lastBackup = defaults.object(forKey: "lastBackup") as? Date
        folderName = resolveFolder()?.lastPathComponent
    }

    var hasFolder: Bool { defaults.data(forKey: bookmarkKey) != nil }

    func setFolder(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(bookmark, forKey: bookmarkKey)
            folderName = url.lastPathComponent
            lastError = nil
        } catch {
            lastError = "Couldn't use that folder: \(error.localizedDescription)"
        }
    }

    func resolveFolder() -> URL? {
        guard let bookmark = defaults.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil,
                                 bookmarkDataIsStale: &stale) else { return nil }
        if stale, let fresh = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
            defaults.set(fresh, forKey: bookmarkKey)
        }
        return url
    }

    /// `exportText` is the game's export format (base64 of the save JSON).
    func backUp(exportText: String, completion: ((Bool) -> Void)? = nil) {
        guard let folder = resolveFolder() else {
            completion?(false)
            return
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH-mm"
        let name = prefix + formatter.string(from: Date()) + ".txt"
        isBackingUp = true

        DispatchQueue.global(qos: .utility).async {
            let scoped = folder.startAccessingSecurityScopedResource()
            defer { if scoped { folder.stopAccessingSecurityScopedResource() } }

            let coordinator = NSFileCoordinator()
            var coordinationError: NSError?
            var writeError: String?
            var success = false
            coordinator.coordinate(writingItemAt: folder.appendingPathComponent(name), options: .forReplacing,
                                   error: &coordinationError) { url in
                do {
                    try Data(exportText.utf8).write(to: url, options: .atomic)
                    success = true
                } catch {
                    writeError = error.localizedDescription
                }
            }
            if let coordinationError = coordinationError { writeError = coordinationError.localizedDescription }
            if success { self.removeOldBackups(in: folder, coordinator: coordinator) }

            DispatchQueue.main.async {
                self.isBackingUp = false
                if success {
                    let now = Date()
                    self.lastBackup = now
                    self.defaults.set(now, forKey: "lastBackup")
                    self.lastError = nil
                } else {
                    self.lastError = "Backup failed: \(writeError ?? "unknown error")"
                }
                completion?(success)
            }
        }
    }

    /// Keeps the newest backups (the names sort by date and time).
    private func removeOldBackups(in folder: URL, coordinator: NSFileCoordinator) {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: folder.path) else { return }
        let backups = names.filter { $0.hasPrefix(prefix) && $0.hasSuffix(".txt") }.sorted()
        for old in backups.dropLast(keepCount) {
            var error: NSError?
            coordinator.coordinate(writingItemAt: folder.appendingPathComponent(old), options: .forDeleting,
                                   error: &error) { url in
                try? fm.removeItem(at: url)
            }
        }
    }
}
