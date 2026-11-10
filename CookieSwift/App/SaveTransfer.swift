import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// Moving a save to another phone with a QR code.
/// The game packs its save tightly (see __ccExportSave), the app compresses it with LZMA, and the result
/// normally fits in one QR code. The other phone reads it with its camera or from a screenshot/photo.
/// If a save is ever too big for one code, it's split across several codes on the same picture.
enum SaveTransfer {
    static let tag = "CCQR2"
    /// one QR code (version 40, low error correction) holds 2953 characters
    static let singleCodeLimit = 2900
    static let chunkSize = 750

    /// QR code texts for a packed save: normally one "CCQR2|data", or "CCQR2|id|part|count|data" parts.
    static func payloads(forSaveJSON json: String) -> [String]? {
        guard let compressed = try? (Data(json.utf8) as NSData).compressed(using: .lzma) as Data else { return nil }
        let text = compressed.base64EncodedString()
        if text.count + tag.count + 1 <= singleCodeLimit { return ["\(tag)|\(text)"] }
        let id = idFor(text)
        var chunks: [String] = []
        var start = text.startIndex
        while start < text.endIndex {
            let end = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            chunks.append(String(text[start..<end]))
            start = end
        }
        return chunks.enumerated().map { "\(tag)|\(id)|\($0.offset + 1)|\(chunks.count)|\($0.element)" }
    }

    static func decode(_ text: String) -> String? {
        guard let data = Data(base64Encoded: text),
              let raw = try? (data as NSData).decompressed(using: .lzma) as Data else { return nil }
        return String(data: raw, encoding: .utf8)
    }

    static func idFor(_ text: String) -> String {
        var hash: UInt32 = 2166136261
        for byte in text.utf8 { hash = (hash ^ UInt32(byte)) &* 16777619 }
        return String(format: "%08x", hash)
    }

    static func qrImage(_ text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "L"
        guard let output = filter.outputImage else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }

    /// All the codes on one picture, with a title, ready to save to Photos or share.
    static func sheetImage(payloads: [String], cookies: String?) -> UIImage? {
        let codes = payloads.compactMap { qrImage($0) }
        guard !codes.isEmpty, codes.count == payloads.count else { return nil }
        let columns = codes.count == 1 ? 1 : 2
        let rows = (codes.count + columns - 1) / columns
        let cell: CGFloat = codes.count == 1 ? 1200 : 600
        let gap: CGFloat = 70, margin: CGFloat = 60, header: CGFloat = 150
        let width = margin * 2 + CGFloat(columns) * cell + CGFloat(columns - 1) * gap
        let height = margin * 2 + header + CGFloat(rows) * cell + CGFloat(rows - 1) * gap
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            let title = "Cookie Clicker save" + (cookies.map { " · \($0) cookies" } ?? "")
            let subtitle = codes.count == 1
                ? "Scan this on the other phone: Misc → iPhone extras → Receive a save."
                : "\(codes.count) codes. Scan them all in one go: Misc → iPhone extras → Receive a save."
            (title as NSString).draw(in: CGRect(x: margin, y: margin - 10, width: width - margin * 2, height: 64), withAttributes: [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold), .foregroundColor: UIColor.black])
            (subtitle as NSString).draw(in: CGRect(x: margin, y: margin + 54, width: width - margin * 2, height: 80), withAttributes: [
                .font: UIFont.systemFont(ofSize: 28), .foregroundColor: UIColor.darkGray])
            ctx.cgContext.interpolationQuality = .none
            for (i, code) in codes.enumerated() {
                let x = margin + CGFloat(i % columns) * (cell + gap)
                let y = margin + header + CGFloat(i / columns) * (cell + gap)
                // CGContext draws images upside down; flip around the cell
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: x, y: y + cell)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                ctx.cgContext.draw(code, in: CGRect(x: 0, y: 0, width: cell, height: cell))
                ctx.cgContext.restoreGState()
            }
        }
    }

    /// Reads every QR code in a picture (a screenshot or photo of the codes).
    static func readCodes(in image: UIImage) -> [String] {
        guard let cgImage = image.cgImage ?? CIImage(image: image).flatMap({ CIContext().createCGImage($0, from: $0.extent) })
        else { return [] }
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(image.imageOrientation), options: [:])
        try? handler.perform([request])
        return (request.results ?? []).compactMap { $0.payloadStringValue }
    }

    private static func cgOrientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

/// Collects QR code parts until the whole save has been read.
final class SaveCollector: ObservableObject {
    @Published private(set) var total = 0
    @Published private(set) var found = 0
    private var id: String?
    private var parts: [Int: String] = [:]

    /// Adds any codes that belong to a save. Returns the save once it has been read completely.
    func add(_ codes: [String]) -> String? {
        for code in codes {
            let fields = code.split(separator: "|", maxSplits: 4, omittingEmptySubsequences: false)
            guard fields.first == Substring(SaveTransfer.tag) else { continue }
            if fields.count == 2 {
                // the whole save in one code
                if let save = SaveTransfer.decode(String(fields[1])) {
                    total = 1
                    found = 1
                    return save
                }
                continue
            }
            guard fields.count == 5, let index = Int(fields[2]), let count = Int(fields[3]),
                  count > 0, index >= 1, index <= count else { continue }
            let codeID = String(fields[1])
            if codeID != id {
                id = codeID
                parts = [:]
                total = count
            }
            parts[index] = String(fields[4])
        }
        found = parts.count
        guard let id = id, total > 0, parts.count == total else { return nil }
        let text = (1...total).compactMap { parts[$0] }.joined()
        guard SaveTransfer.idFor(text) == id else { return nil }
        return SaveTransfer.decode(text)
    }
}
