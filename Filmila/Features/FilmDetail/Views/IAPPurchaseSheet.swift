#if DEBUG
import StoreKit
import SwiftUI

struct IAPPurchaseSheet: View {
    let film: Film
    let product: Any?
    let iapService: IAPServiceProtocol
    var onSuccess: () async -> Void

    @StateObject private var paymentVM: PaymentViewModel
    @Environment(\.dismiss) private var dismiss

    init(film: Film, product: Any?, iapService: IAPServiceProtocol, onSuccess: @escaping () async -> Void) {
        self.film = film
        self.product = product
        self.iapService = iapService
        self.onSuccess = onSuccess
        _paymentVM = StateObject(wrappedValue: PaymentViewModel(filmId: film.id, iapService: iapService))
    }

    private var displayProduct: Product? {
        paymentVM.storeProduct ?? (product as? Product)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                CachedAsyncImage(url: film.thumbnailUrl)
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(film.displayTitle)
                    .font(.filmilaTitleSm)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .multilineTextAlignment(.center)

                priceLine

                stateMessage

                if displayProduct != nil {
                    Button {
                        Task { await paymentVM.purchase(filmId: film.id) }
                    } label: {
                        Text("Purchase")
                            .font(.filmilaBodyMedium)
                    }
                    .buttonStyle(FilmilaPrimaryButtonStyle())
                    .disabled(paymentVM.state == .loading)
                } else if paymentVM.state != .loading {
                    Text("Unavailable")
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textMuted)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await paymentVM.restore() }
                } label: {
                    Text(String(localized: "common_cancel"))
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.accent)
                }
                .disabled(paymentVM.state == .loading)

                if paymentVM.state == .loading {
                    ProgressView()
                        .tint(FilmilaColors.accent)
                }

                if case .cancelled = paymentVM.state {
                    Button(String(localized: "common_cancel")) {
                        paymentVM.resetToIdle()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }

                if case .failed = paymentVM.state {
                    Button(String(localized: "home_retry")) {
                        paymentVM.resetToIdle()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) {
                        dismiss()
                    }
                }
            }
            .task {
                paymentVM.configure(initialStoreProduct: product)
                await paymentVM.loadStoreProductIfNeeded()
            }
            .onChange(of: paymentVM.state) { newState in
                if case .success = newState {
                    Task {
                        await onSuccess()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var priceLine: some View {
        if let displayProduct {
            Text(displayProduct.displayPrice)
                .font(.filmilaPrice)
                .foregroundStyle(FilmilaColors.accent)
        } else {
            Text(String(format: "%.2f", film.price))
                .font(.filmilaPrice)
                .foregroundStyle(FilmilaColors.accent)
        }
    }

    @ViewBuilder
    private var stateMessage: some View {
        switch paymentVM.state {
        case .idle, .loading, .success:
            EmptyView()
        case let .failed(message):
            Text(message)
                .font(.filmilaCaption)
                .foregroundStyle(FilmilaColors.destructive)
                .multilineTextAlignment(.center)
        case .cancelled:
            Text(String(localized: "common_cancel"))
                .font(.filmilaCaption)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    Text(String(localized: "common_preview_placeholder"))
        .sheet(isPresented: .constant(true)) {
            let container = PreviewContainer()
            IAPPurchaseSheet(
                film: Film(id: 2, title: "Paid", price: 9.99, status: .approved, viewCount: 0, createdAt: Date()),
                product: nil,
                iapService: container.iapService
            ) {}
            .environment(\.container, container)
        }
}
#endif
