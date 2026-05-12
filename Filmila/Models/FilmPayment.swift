import Foundation

enum PaymentStatus: String, Codable, Equatable, Sendable {
    case pending
    case completed
    case failed
    case cancelled
}

struct FilmPayment: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let filmId: Int
    let viewerId: UUID
    let status: PaymentStatus
    let paymentMethod: String
    let amount: Double
    let paymentId: String
    let createdAt: Date

    init(
        id: UUID,
        filmId: Int,
        viewerId: UUID,
        status: PaymentStatus,
        paymentMethod: String,
        amount: Double,
        paymentId: String,
        createdAt: Date
    ) {
        self.id = id
        self.filmId = filmId
        self.viewerId = viewerId
        self.status = status
        self.paymentMethod = paymentMethod
        self.amount = amount
        self.paymentId = paymentId
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case filmId = "film_id"
        case viewerId = "viewer_id"
        case status
        case paymentMethod = "payment_method"
        case amount
        case paymentId = "payment_id"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        filmId = try container.decode(Int.self, forKey: .filmId)
        viewerId = try container.decode(UUID.self, forKey: .viewerId)
        status = try container.decode(PaymentStatus.self, forKey: .status)
        paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        amount = try container.decodeLossyDouble(forKey: .amount)
        paymentId = try container.decode(String.self, forKey: .paymentId)
        createdAt = try container.decodeFilmilaTimestamp(forKey: .createdAt)
    }
}
