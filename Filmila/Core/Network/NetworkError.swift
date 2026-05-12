import Foundation

enum NetworkError: Error {
    case httpError(Int)
    case decodingError(Error)
    case unauthorized
    case notFound
    case serverError(String)
    case unknown
}
