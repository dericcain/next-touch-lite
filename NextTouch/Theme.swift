import SwiftUI

/// Shared visual tokens for the iPhone and watch companion UI.
enum NextTouchTheme {
    static let cornerRadius: CGFloat = 4
    static let cardCornerRadius: CGFloat = cornerRadius
    static let controlCornerRadius: CGFloat = cornerRadius
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color.white
    static let accent = Color(red: 0.62, green: 0.07, blue: 0.15)
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
}
