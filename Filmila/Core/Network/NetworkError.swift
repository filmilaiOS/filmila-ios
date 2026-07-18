import Foundation

enum NetworkError: Error {
    case httpError(Int)
    case decodingError(Error)
    case unexpectedResponse(String)
    case unauthorized
    case notFound
    case serverError(String)
    case timeout
    case unknown
}
