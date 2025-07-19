import AsyncHTTPClient
import Foundation
import OpenAPIKit

// Function to call Ollama API
func callOllama(
  client: HTTPClient, prompt: String, system: String? = nil, model: String = "devstral"
) async throws -> [String: Any] {
  var request = HTTPClientRequest(url: "http://localhost:11434/api/generate")
  request.method = .POST
  request.headers.add(name: "Content-Type", value: "application/json")

  var requestBody: [String: Any] = [
    "model": model,
    "prompt": prompt,
    "format": "json",
    "stream": false,
  ]

  if let system = system {
    requestBody["system"] = system
  }

  let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
  request.body = .bytes(jsonData)

  let response = try await client.execute(request, timeout: .seconds(120))

  guard response.status == .ok else {
    throw NSError(
      domain: "", code: Int(response.status.code),
      userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
  }

  let body = try await response.body.collect(upTo: 1024 * 1024 * 5)  // Increase buffer
  let data = Data(buffer: body)
  print("Raw Ollama response: \(String(data: data, encoding: .utf8) ?? "No data")")

  guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw NSError(
      domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])
  }

  if let error = json["error"] as? String {
    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
  }

  guard let responseString = json["response"] as? String,
    let responseData = responseString.data(using: .utf8),
    let result = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
  else {
    throw NSError(
      domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response"])
  }

  print("Parsed LLM result: \(result)")
  return result
}

// Bootstrap method
func bootstrapNextSteps(client: HTTPClient) async throws {

  let fileManager = FileManager.default
  let nextStepsPath = "NextSteps.json"
  var currentNextSteps: [String: Any]? = nil

  // Collect descriptive project metadata
  var filesDescription = ""

  let metadataFiles: [String: String] = [
    "AgilePlan.md": "Agile implementation plan.",
    "LogBook.md": "Log of project activities.",
    "README.md": "Project overview.",
    "StakeholderRequirements.md": "Requirements.",
    "Vision.md": "Vision statement.",
    "Package.swift": "Swift package manifest.",
    "bootstrap.swift": "Bootstrap script.",
  ]

  for (file, desc) in metadataFiles {
    filesDescription += "- \(file): \(desc)\n"
  }

  // Find all .swift files in Sources and Tests
  let pathsToScan = ["Sources", "Tests"]
  for basePath in pathsToScan {
    let baseURL = URL(fileURLWithPath: basePath)
    let optionalEnumerator = fileManager.enumerator(at: baseURL, includingPropertiesForKeys: nil)

    while let file = optionalEnumerator?.nextObject() as? URL {
      guard file.pathExtension == "swift" else { continue }
      let relativePath = file.path
      filesDescription += "- \(relativePath): Swift code file.\n"
    }
  }

  // Include NextSteps.json if it exists
  if fileManager.fileExists(atPath: nextStepsPath) {
    let data = try Data(contentsOf: URL(fileURLWithPath: nextStepsPath))
    currentNextSteps = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    filesDescription += "- NextSteps.json: Current sprint plan.\n"
  }

  let basePrompt = """
    You are a project manager and Swift developer for a Meta Agentic AI System built in Swift, using Ollama with structured output mode and individual agents running in isolated Swift containers. The project directory contains:
    \(filesDescription)

    Align with AgilePlan.md, StakeholderRequirements.md, README.md, and Vision.md.
    Use structured JSON output.
    """

  let systemPrompt =
    "You must output ONLY the exact JSON structure requested in the prompt, with no additional text, explanations, or wrappers. Follow the output format precisely."

  if let current = currentNextSteps {
    // Prompt to generate artifacts for current sprint
    let implPrompt = """
      \(basePrompt)

      Current NextSteps.json:
      \(String(data: try JSONSerialization.data(withJSONObject: current, options: .prettyPrinted), encoding: .utf8)!)

      Implement the tasks for sprint \(current["sprint_number"] ?? "unknown"). Generate Swift code artifacts for Sources/MetaAgentSystem and tests for Tests/MetaAgentSystemTests.

      Output JSON: {"files": [{"path": "Sources/MetaAgentSystem/File.swift", "content": "code here"}, ...]}
      """

    let implResponse = try await callOllama(
      client: client, prompt: implPrompt, system: systemPrompt)

    if let filesArray = implResponse["files"] as? [[String: String]] {
      for file in filesArray {
        if let path = file["path"], let content = file["content"] {
          let url = URL(fileURLWithPath: path)
          try fileManager.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
          try content.data(using: .utf8)?.write(to: url)
          print("Created/Updated: \(path)")
        }
      }
    } else {
      print("No files generated in response.")
    }
  }

  // Prompt for next steps
  let nextPrompt = """
    \(basePrompt)

    \(currentNextSteps != nil ? "The current sprint has been implemented. Generate the next sprint plan." : "Generate the initial sprint plan.")

    Output structured JSON with fields: "sprint_number", "goal", "tasks" (array of strings), "deliverable", "acceptance_criteria" (array of strings).
    Ensure tasks advance development, are testable, and create artifacts in Sources and Tests where applicable.
    """

  let nextResponse = try await callOllama(client: client, prompt: nextPrompt, system: systemPrompt)

  let outputData = try JSONSerialization.data(withJSONObject: nextResponse, options: .prettyPrinted)
  try outputData.write(to: URL(fileURLWithPath: nextStepsPath))
  print("NextSteps.json updated")
}

@main
struct Bootstrap {
  static func main() async throws {
    let client = HTTPClient(
      eventLoopGroupProvider: .singleton,
      configuration: HTTPClient.Configuration(
        timeout: HTTPClient.Configuration.Timeout(connect: .seconds(30), read: .seconds(300))))
    var error: Error? = nil
    do {
      try await bootstrapNextSteps(client: client)
    } catch let e {
      error = e
    }
    try await client.shutdown()
    if let error {
      throw error
    }
  }
}
