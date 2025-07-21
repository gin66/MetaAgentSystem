@main
struct MetaAgentSystem {
    static func main() async throws {
        let client = OllamaClient()
        let samplePrompt = "Hello, Ollama!"
        do {
            let response = try await client.sendRequest(prompt: samplePrompt)
            print("Response from Ollama API: \(response)")
        } catch {
            print("Error occurred: \(error.localizedDescription)")
        }
    }
}