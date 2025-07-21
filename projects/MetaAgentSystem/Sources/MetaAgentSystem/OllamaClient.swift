import Foundation

struct OllamaClient {
    func sendRequest(prompt: String) async throws -> String {
        // Prepare URL and Request
        guard let url = URL(string: "http://localhost:11434/api/generate") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare JSON body
        let jsonBody: [String: Any] = ["prompt": prompt]
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

        // Send Request and Handle Response
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return String(data: data, encoding: .utf8) ?? ""
        } else {
            throw URLError(.badServerResponse)
        }
    }
}
