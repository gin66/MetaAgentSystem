// Sources/MetaAgentSystem/Networking/AgentCommunicator.swift
import Foundation

class AgentCommunicator {
    private let url: URL
    private let session: URLSession

    init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }

    func sendMessage(message: String, completion: @escaping (Result<Data?, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(data))
        }.resume()
    }
}