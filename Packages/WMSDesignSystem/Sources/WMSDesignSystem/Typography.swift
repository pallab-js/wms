import SwiftUI

public extension Font {
    static let wmsLargeTitle = Font.largeTitle.weight(.bold)
    static let wmsTitle = Font.title2.weight(.semibold)
    static let wmsHeadline = Font.headline
    static let wmsBody = Font.body
    static let wmsCallout = Font.callout
    static let wmsCaption = Font.caption.weight(.medium)
    static let wmsMonospace = Font.system(.body, design: .monospaced)
    static let wmsMonospaceCaption = Font.system(.caption, design: .monospaced)
}
