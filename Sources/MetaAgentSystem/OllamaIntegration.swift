// Ollama integration for structured output mode
import Foundation
struct OllamaResponse: Codable {
    let message: String?
}
class OllamaClient {
    func send(message: String) throws -> OllamaResponse? {
        // Placeholder for actual API call to Ollama
        guard !message.isEmpty else { return nil }
        return OllamaResponse(message: message)
    }
}