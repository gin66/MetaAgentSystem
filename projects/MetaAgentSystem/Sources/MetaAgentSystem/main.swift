import Foundation

@main
struct MetaAgentSystem {
    static func main() async throws {
        let client = OllamaClient()
        let samplePrompt = "Hello, Ollama!"
        let responseJson = try await client.sendRequest(prompt: samplePrompt)
        print("Response from Ollama API: \(responseJson)")
    }
}