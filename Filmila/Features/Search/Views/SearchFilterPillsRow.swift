import SwiftUI

struct SearchFilterPillsRow: View {
    @Binding var showsGenreFilters: Bool
    var onPlaceholderTap: (String) -> Void

    private let pills: [(id: String, title: String)] = [
        ("filters", String(localized: "search_filter_filters")),
        ("genre", String(localized: "search_filter_genre")),
        ("mood", String(localized: "search_filter_mood")),
        ("theme", String(localized: "search_filter_theme")),
        ("country", String(localized: "search_filter_country"))
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(pills, id: \.id) { pill in
                    let isSelected = pill.id == "filters" && showsGenreFilters
                    Button {
                        if pill.id == "filters" {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showsGenreFilters.toggle()
                            }
                        } else if pill.id == "genre" {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showsGenreFilters = true
                            }
                        } else {
                            onPlaceholderTap(pill.title)
                        }
                    } label: {
                        Text(pill.title)
                            .font(.filmilaCaptionMd)
                            .foregroundStyle(isSelected ? FilmilaColors.background : FilmilaColors.textSecondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(isSelected ? Color.white : FilmilaColors.surfaceElevated)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}

#if DEBUG
#Preview {
    SearchFilterPillsRow(showsGenreFilters: .constant(false), onPlaceholderTap: { _ in })
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
