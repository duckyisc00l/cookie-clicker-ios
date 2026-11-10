import UIKit

// Temporary stand-ins while the screens are being ported.
final class AscendView {
    let options: PopupOptions
    init(mode: Int) { options = PopupOptions(build: { c in c.h3("Ascending") }, close: nil, fullPopup: true) }
}
