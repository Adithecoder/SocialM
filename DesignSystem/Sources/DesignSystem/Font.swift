import SwiftUI

public extension Font {
    /// Namespace to prevent naming collisions with static accessors on
    /// SwiftUI's Font.
    ///
    /// Xcode's autocomplete allows for easy discovery of design system fonts.
    /// At any call site that requires a font, type `Font.DesignSystem.<esc>`
    struct DesignSystem {
        public static let munkacime = Font.custom("NicoMoji-Regular", size: 16)
        public static let szovegstilus = Font.custom("OrelegaOne-Regular", size: 11)
        public static let munkacime2 = Font.custom("OrelegaOne-Regular", size: 18)
    }
}
