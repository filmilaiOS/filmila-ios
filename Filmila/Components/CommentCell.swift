import SwiftUI

struct CommentCell: View {
    let comment: CommentDisplay

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private var initials: String {
        let name = comment.authorDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty {
            let fallback = String(localized: "detail_comment_anonymous")
            return String(fallback.prefix(1)).uppercased()
        }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var displayName: String {
        if let name = comment.authorDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return String(localized: "detail_comment_anonymous")
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(initials)
                .font(.filmilaCaptionMd)
                .foregroundStyle(FilmilaColors.textInverse)
                .frame(width: 40, height: 40)
                .background(FilmilaColors.surfaceBright)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Spacing.sm) {
                    Text(displayName)
                        .font(.filmilaBodyMedium)
                        .foregroundStyle(FilmilaColors.textPrimary)
                    Text(Self.relativeFormatter.localizedString(for: comment.createdAt, relativeTo: Date()))
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textMuted)
                }
                Text(comment.content)
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.sm)
    }
}

#if DEBUG
#Preview {
    CommentCell(
        comment: CommentDisplay(
            id: UUID(),
            filmId: 1,
            userId: UUID(),
            content: "Beautiful cinematography and pacing.",
            createdAt: Date().addingTimeInterval(-7200),
            authorDisplayName: "Jamal H"
        )
    )
    .padding()
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
