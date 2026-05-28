import SwiftUI

public extension Color {
    static let wmsAccent = Color.accentColor
    static let wmsSurface = Color(nsColor: .controlBackgroundColor)
    static let wmsBackground = Color(nsColor: .windowBackgroundColor)
    static let wmsDestructive = Color.red
    static let wmsWarning = Color.orange
    static let wmsSuccess = Color.green
    static let wmsInfo = Color.blue
    static let wmsTextPrimary = Color(nsColor: .labelColor)
    static let wmsTextSecondary = Color(nsColor: .secondaryLabelColor)
    static let wmsTextTertiary = Color(nsColor: .tertiaryLabelColor)
    static let wmsSeparator = Color(nsColor: .separatorColor)
}
