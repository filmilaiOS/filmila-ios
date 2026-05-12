import Foundation

enum DeepLinkRoute: Equatable {
    case filmDetail(filmId: Int)
    case paymentCallback(orderId: String)
    case profile
    case search(query: String?)
}
