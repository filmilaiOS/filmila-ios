import SwiftUI

enum FilmilaTypography {
    static func screenTitle() -> Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }

    static func sectionTitle() -> Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }

    static func bodyPrimary() -> Font {
        .system(.body, design: .default)
    }

    static func caption() -> Font {
        .system(.caption, design: .default)
    }
}
