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

    func sendReport(endpoint: String, payload: [String: Any], completion: @escaping (Result) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(.noData))
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil {
                completion(.failure(.noData))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(500)))
                return
            }
            completion(.success(true))
        }.resume()
    }

    func checkThreat(indicator: String, completion: @escaping (Result) -> Void) {
        guard let url = URL(string: "http://localhost:3000/threats?query=\(indicator)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { _, response, error in
            if error != nil {
                completion(.failure(.noData))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.serverError(404)))
                return
            }
            completion(.success(true))
        }.resume()
    }
}
