import SwiftUI

/// Shared visual tokens for the iPhone and watch companion UI.
enum NextTouchTheme {
    static let cornerRadius: CGFloat = 4
    static let cardCornerRadius: CGFloat = cornerRadius
    static let controlCornerRadius: CGFloat = cornerRadius
    #if os(iOS)
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    #else
    static let pageBackground = Color.black
    #endif
    static let cardBackground = Color.white
    static let accent = Color(red: 0.62, green: 0.07, blue: 0.15)
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
    #if os(watchOS)
    static let watchControlDiameter: CGFloat = 42
    static let watchContentPadding: CGFloat = 8
    static let watchVerticalSpacing: CGFloat = 4
    static let watchTimerFontSize: CGFloat = 38
    #endif
}
