# Design Document for Parsing Structured JSON Output Using Ollama's Structured Output Mode

## 1. Purpose
The purpose of this design is to outline the necessary components and interactions required to parse structured JSON output from the Ollama API, ensuring it adheres to Ollama's structured output mode.

## 2. Components
### 2.1 Response Handling
- **Struct**: `OllamaResponse`
- **Purpose**: A struct to parse the JSON response from the Ollama API using its structured output mode.
- **Properties**:
  - `message: String`: The message received in the response, formatted as per Ollama's structured output mode.

### 2.2 Network Client
- **Class**: `OllamaClient`
- **Purpose**: A client to handle network communication with the Ollama API and return JSON responses.
- **Functions**:
  - `sendRequest(prompt: String) async throws -> OllamaResponse`: Sends a prompt to the Ollama API, captures the JSON response, parses it using the `OllamaResponse` struct, and returns the parsed response.

## 3. Interactions
### 3.1 Main Entry Point
In `main.swift`, call the function `sendRequest(prompt:)` with a sample prompt to get the structured JSON response.
```swift
@main
struct MetaAgentSystem {
    static func main() async throws {
        let client = OllamaClient()
        let samplePrompt = "Hello, Ollama!"
        let response = try await client.sendRequest(prompt: samplePrompt)
        print("Response from Ollama API: \(response.message)")
    }
}
```

### 3.2 Network Client
The `OllamaClient` class will handle the network request to the Ollama API and parse the response.
```swift
import Foundation
struct OllamaClient {
    func sendRequest(prompt: String) async throws -> OllamaResponse {
        // Prepare URL and Request
        guard let url = URL(string: "https://api.ollama.com/v1/generate") else {
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
            let decodedResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
            return decodedResponse
        } else {
            throw URLError(.badServerResponse)
        }
    }
}
```

### 3.3 Response Handling
The `OllamaResponse` struct will parse the JSON response using Ollama's structured output mode.
```swift
import Foundation
struct OllamaResponse: Codable {
    let message: String
}
```