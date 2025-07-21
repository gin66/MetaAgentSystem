# Design Document for Basic Ollama API Integration

## 1. Purpose
The purpose of this design is to outline the necessary components and interactions required to send a sample prompt to the Ollama API, capture the JSON response, and verify its correctness.

## 2. Components
### 2.1 Main Entry Point
- `main.swift`: The main entry point for the application where we will trigger the function to interact with the Ollama API.

### 2.2 Network Client
- **Class**: `OllamaClient`
- **Purpose**: A client to handle network communication with the Ollama API.
- **Functions**:
  - `sendRequest(prompt: String) async throws -> String`: Sends a prompt to the Ollama API and returns the JSON response as a string.

### 2.3 Response Handling
- **Struct**: `OllamaResponse`
- **Purpose**: A struct to parse the JSON response from the Ollama API.
- **Properties**:
  - `message: String`: The message received in the response.

## 3. Interactions
### 3.1 Main Entry Point
In `main.swift`, call the function `sendRequest(prompt:)` with a sample prompt and capture the JSON response.
```swift
@main
struct MetaAgentSystem {
    static func main() async throws {
        let client = OllamaClient()
        let samplePrompt = "Hello, Ollama!"
        let responseJson = try await client.sendRequest(prompt: samplePrompt)
        print("Response from Ollama API: \(responseJson)")
    }
}
```

### 3.2 Network Client
The `OllamaClient` class will handle the network request to the Ollama API.
```swift
import Foundation
struct OllamaClient {
    func sendRequest(prompt: String) async throws -> String {
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
            return String(data: data, encoding: .utf8) ?? ""
        } else {
            throw URLError(.badServerResponse)
        }
    }
}
```

### 3.3 Response Handling
The `OllamaResponse` struct will parse the JSON response.
```swift
import Foundation
struct OllamaResponse: Codable {
    let message: String
}
```