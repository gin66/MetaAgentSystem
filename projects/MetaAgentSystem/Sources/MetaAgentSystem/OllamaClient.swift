import Foundation
import Foundation

struct OllamaClient {
    func sendRequest(prompt: String) async throws -> String {
        // Prepare URL and Request
        guard let url = URL(string: "http://localhost:11434/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare JSON body
        let jsonBody: [String: Any] = [
            "model": "devstral",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

        // Send Request and Handle Response
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            let decodedResponse = try JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data)
            return decodedResponse.choices.first?.message.content ?? ""
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("Response data: \(dataString)")
            }
            throw URLError(.badServerResponse)
        }
    }
}

