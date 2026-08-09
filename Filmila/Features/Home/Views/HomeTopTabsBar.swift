import SwiftUI

enum HomeBrowseTab: String, CaseIterable, Identifiable {
    case films
    case collections
    case genres
    case moods

    var id: String { rawValue }

    var title: String {
        switch self {
        case .films: return String(localized: "shell_browse_films")
        case .collections: return String(localized: "shell_browse_collections")
        case .genres: return String(localized: "shell_browse_genres")
        case .moods: return String(localized: "shell_browse_moods")
        }
    }
}

struct HomeTopTabsBar: View {
    @Binding var selected: HomeBrowseTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(HomeBrowseTab.allCases) { tab in
                    let isSelected = selected == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = tab
                        }
                    } label: {
                        Text(tab.title)
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
        .padding(.vertical, Spacing.sm)
    }
}

#if DEBUG
#Preview {
    HomeTopTabsBar(selected: .constant(.films))
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
