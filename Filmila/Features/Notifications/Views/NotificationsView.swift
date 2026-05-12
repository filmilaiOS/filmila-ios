import SwiftUI

struct NotificationsView: View {
    @StateObject private var vm: NotificationsViewModel

    init(container: AppContainer) {
        _vm = StateObject(wrappedValue: NotificationsViewModel(container: container))
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        Group {
            if vm.isLoading && vm.items.isEmpty {
                ProgressView()
                    .tint(FilmilaColors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(vm.items) { item in
                        Button {
                            Task { await vm.markRead(item) }
                        } label: {
                            notificationRow(item)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(FilmilaColors.surface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(String(localized: "notifications_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load()
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bell")
                .font(.filmilaIconEmptyState)
                .foregroundStyle(FilmilaColors.textMuted)
            Text(String(localized: "notifications_empty"))
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func notificationRow(_ item: InboxNotification) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: item.iconName ?? "bell.fill")
                .font(.filmilaIconNotification)
                .foregroundStyle(FilmilaColors.accent)
                .frame(width: 36, alignment: .center)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.title)
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .multilineTextAlignment(.leading)

                if let body = item.body, !body.isEmpty {
                    Text(body)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .lineLimit(3)
                }

                Text(Self.relativeFormatter.localizedString(for: item.createdAt, relativeTo: Date()))
                    .font(.filmilaLabel)
                    .foregroundStyle(FilmilaColors.textMuted)
            }

            Spacer(minLength: 0)

            if !item.isRead {
                Circle()
                    .fill(FilmilaColors.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        NotificationsView(container: PreviewContainer())
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
