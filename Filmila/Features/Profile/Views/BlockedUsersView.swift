import SwiftUI

struct BlockedUsersView: View {
    @State private var users: [ForumBlockedUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(FilmilaColors.accent)
            } else if errorMessage != nil && users.isEmpty {
                VStack(spacing: Spacing.md) {
                    Text(String(localized: "safety_title"))
                        .foregroundStyle(FilmilaColors.textSecondary)
                    Button {
                        Task { await loadUsers() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(FilmilaColors.accent)
                }
            } else if users.isEmpty {
                Text(String(localized: "safety_no_blocked"))
                    .foregroundStyle(FilmilaColors.textSecondary)
            } else {
                List {
                    ForEach(users) { user in
                        HStack {
                            Text(user.displayName)
                            Spacer()
                            Button(String(localized: "safety_unblock")) {
                                Task {
                                    do {
                                        try await ForumSafetyService.shared.unblock(user.id)
                                        users.removeAll { $0.id == user.id }
                                    } catch { errorMessage = error.localizedDescription }
                                }
                            }
                            .foregroundStyle(FilmilaColors.accent)
                            .buttonStyle(.borderless)
                        }
                        .listRowBackground(FilmilaColors.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(String(localized: "safety_blocked_users"))
        .task { await loadUsers() }
        .alert(String(localized: "safety_title"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "profile_ok"), role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    @MainActor
    private func loadUsers() async {
        isLoading = true
        errorMessage = nil
        do { users = try await ForumSafetyService.shared.blockedUsers() }
        catch { users = []; errorMessage = error.localizedDescription }
        isLoading = false
    }
}
