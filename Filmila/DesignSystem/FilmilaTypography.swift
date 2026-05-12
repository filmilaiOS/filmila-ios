import SwiftUI

extension Font {
    static let filmilaDisplay = Font.custom("Georgia-Bold", size: 32)
    static let filmilaDisplayMd = Font.custom("Georgia-Bold", size: 24)
    static let filmilaTitle = Font.custom("Georgia-BoldItalic", size: 20)
    static let filmilaTitleSm = Font.custom("Georgia", size: 17)
    static let filmilaBody = Font.system(size: 15, weight: .regular)
    static let filmilaBodyMedium = Font.system(size: 15, weight: .medium)
    static let filmilaCaption = Font.system(size: 12, weight: .regular)
    static let filmilaCaptionMd = Font.system(size: 12, weight: .medium)
    static let filmilaLabel = Font.system(size: 11, weight: .medium)
    static let filmilaPrice = Font.system(size: 17, weight: .semibold, design: .monospaced)

    static let filmilaIconEmptyState = Font.system(size: 44, weight: .regular)
    static let filmilaIconNotification = Font.system(size: 22, weight: .regular)
    static let filmilaIconHero = Font.system(size: 48, weight: .regular)
    static let filmilaIconDetail = Font.system(size: 32, weight: .regular)
    static let filmilaIconClose = Font.system(size: 28, weight: .medium)
    static let filmilaIconRating = Font.system(size: 18, weight: .medium)
    static let filmilaIconPlaceholder = Font.system(size: 28, weight: .medium)
    static let filmilaAvatarInitial = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let filmilaCapsBadge = Font.system(size: 12, weight: .semibold)
}
