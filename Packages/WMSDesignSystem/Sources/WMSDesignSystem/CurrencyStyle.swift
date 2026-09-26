import Foundation

public extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static var wmsCurrency: Self {
        var style = Self.currency(code: "INR")
        style.locale = Locale(identifier: "en_IN")
        return style
    }
}
