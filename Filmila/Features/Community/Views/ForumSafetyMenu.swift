import SwiftUI

struct ForumSafetyMenu: View {
    let postId: Int?
    let commentId: Int?
    let authorId: UUID?
    var onBlockChanged: (() -> Void)? = nil

    @State private var showReasons = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Menu {
            Button(String(localized: "safety_report")) { showReasons = true }
            if let authorId {
                Button(String(localized: "safety_block")) {
                    Task {
                        do {
                            try await ForumSafetyService.shared.block(authorId)
                            onBlockChanged?()
                            alertMessage = String(localized: "safety_block_success")
                        } catch { alertMessage = error.localizedDescription }
                        showAlert = true
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 44, height: 44)
                .foregroundStyle(FilmilaColors.textSecondary)
        }
        .confirmationDialog(String(localized: "safety_report_reason"), isPresented: $showReasons) {
            Button(String(localized: "safety_reason_harassment")) { submit("harassment") }
            Button(String(localized: "safety_reason_hate")) { submit("hate") }
            Button(String(localized: "safety_reason_spam")) { submit("spam") }
            Button(String(localized: "safety_reason_violence")) { submit("violence") }
            Button(String(localized: "safety_reason_other")) { submit("other") }
        }
        .alert(String(localized: "safety_title"), isPresented: $showAlert) {
            Button(String(localized: "profile_ok"), role: .cancel) {}
        } message: { Text(alertMessage) }
    }

    private func submit(_ reason: String) {
        Task {
            do {
                try await ForumSafetyService.shared.report(postId: postId, commentId: commentId, reason: reason)
                alertMessage = String(localized: "safety_report_success")
            } catch { alertMessage = error.localizedDescription }
            showAlert = true
        }
    }
}
