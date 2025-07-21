@main
struct MetaAgentSystem {
    static func main() async throws {
        let client = OllamaClient()
        let samplePrompt = "Hello, Ollama!"
        let response = try await client.sendRequest(prompt: samplePrompt)
        print("Response from Ollama API: \(response.message)")
    }
}