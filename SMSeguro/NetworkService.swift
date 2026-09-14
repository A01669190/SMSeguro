import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
}

final class NetworkService {
    static let shared = NetworkService()
    private init() {}
}
