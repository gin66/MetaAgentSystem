import AsyncHTTPClient
import Foundation
import OpenAPIKit

// Enhanced callOllama with better error handling and logging
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
      userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(response.status)"])
  }

  let body = try await response.body.collect(upTo: 1024 * 1024 * 10)  // Larger buffer
  let data = Data(buffer: body)
  let rawString = String(data: data, encoding: .utf8) ?? "No data"
  print("Raw Ollama response: \(rawString)")

  guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw NSError(
      domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON: \(rawString)"])
  }

  if let error = json["error"] as? String {
    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
  }

  guard let responseString = json["response"] as? String,
    let responseData = responseString.data(using: .utf8),
    let result = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
  else {
    throw NSError(
      domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response: \(rawString)"])
  }

  print("Parsed LLM result: \(result)")
  return result
}

// New function to validate the entire package
func validatePackage() throws -> Bool {
  // Run swift build
  let buildProcess = Process()
  buildProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
  buildProcess.arguments = ["build"]
  try buildProcess.run()
  buildProcess.waitUntilExit()
  
  if buildProcess.terminationStatus != 0 {
    print("Package build failed")
    return false
  }
  
  // Run swift test
  let testProcess = Process()
  testProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
  testProcess.arguments = ["test"]
  try testProcess.run()
  testProcess.waitUntilExit()
  
  if testProcess.terminationStatus != 0 {
    print("Package tests failed")
    return false
  }
  
  return true
}

// Improved bootstrap with package-level validation, iteration, enhanced prompts
func bootstrapNextSteps(client: HTTPClient) async throws {
  let fileManager = FileManager.default
  let nextStepsPath = "NextSteps.json"
  var currentNextSteps: [String: Any]? = nil

  // Enhanced filesDescription with more details
  var filesDescription = ""
  let metadataFiles: [String: String] = [
    "AgilePlan.md": "Detailed Agile implementation plan including sprints and backlogs.",
    "LogBook.md": "Chronological log of all project activities and decisions.",
    "README.md": "Comprehensive project overview, setup, and usage instructions.",
    "StakeholderRequirements.md": "List of all stakeholder requirements and priorities.",
    "Vision.md": "High-level vision statement for the Meta Agentic AI System.",
    "Package.swift": "Swift Package Manager manifest defining dependencies and targets.",
    "bootstrap.swift": "Script for bootstrapping and automating project development.",
  ]

  for (file, desc) in metadataFiles {
    filesDescription += "- \(file): \(desc)\n"
  }

  // Scan Sources and Tests, include brief content summary if possible
  let pathsToScan = ["Sources", "Tests"]
  for basePath in pathsToScan {
    let baseURL = URL(fileURLWithPath: basePath)
    let optionalEnumerator = fileManager.enumerator(at: baseURL, includingPropertiesForKeys: nil)

    while let file = optionalEnumerator?.nextObject() as? URL {
      guard file.pathExtension == "swift" else { continue }
      let relativePath = file.path
      filesDescription += "- \(relativePath): Swift code file for \(basePath == "Sources" ? "implementation" : "unit tests").\n"
    }
  }

  if fileManager.fileExists(atPath: nextStepsPath) {
    let data = try Data(contentsOf: URL(fileURLWithPath: nextStepsPath))
    currentNextSteps = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    filesDescription += "- NextSteps.json: JSON file outlining the current sprint plan.\n"
  }

  let basePrompt = """
    You are an expert project manager and senior Swift developer for a Meta Agentic AI System built in Swift. The system uses Ollama for structured output and runs individual agents in isolated Swift containers. Project directory structure:
    \(filesDescription)

    Strictly align all work with AgilePlan.md, StakeholderRequirements.md, README.md, and Vision.md.
    Follow Swift best practices: clean, modular code; proper error handling; concurrency safety; comprehensive comments.
    Ensure code is testable, efficient, secure, and performs actual functionality (no placeholders; implement real logic that executes and produces results).
    Use Swift conventions for naming, formatting.
    Output only the exact JSON structure requested, no extra text.
    """

  let systemPrompt = 
    "Output ONLY the precise JSON as specified in the prompt. No explanations, wrappers, or additional content. Adhere to format exactly."

  if let current = currentNextSteps {
    // Enhanced implPrompt with quality guidelines, emphasizing functional code
    let implPrompt = """
      \(basePrompt)

      Current NextSteps.json:
      \(String(data: try JSONSerialization.data(withJSONObject: current, options: .prettyPrinted), encoding: .utf8)!)

      Implement tasks for sprint \(current["sprint_number"] ?? "unknown"). Generate high-quality Swift code for Sources/MetaAgentSystem and corresponding unit tests in Tests/MetaAgentSystemTests.
      Code must: compile without errors, include error handling, be modular, follow SOLID principles, and implement real, executable functionality that does something useful (e.g., processes data, calls APIs, runs agents).
      Tests must cover edge cases, use XCTest, and verify that the code performs its intended actions.

      Output JSON: {"files": [{"path": "Sources/MetaAgentSystem/File.swift", "content": "full code here"}, ...]}
      """

    var implResponse = try await callOllama(client: client, prompt: implPrompt, system: systemPrompt)
    
    // Iteration loop for refinement
    var attempts = 0
    let maxAttempts = 3
    while attempts < maxAttempts {
      if let filesArray = implResponse["files"] as? [[String: String]] {
        var allValid = true
        for file in filesArray {
          if let path = file["path"], let content = file["content"] {
            let url = URL(fileURLWithPath: path)
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.data(using: .utf8)?.write(to: url)
            print("Generated: \(path)")
          }
        }
        
        // Validate the entire package after writing all files
        if try !validatePackage() {
          allValid = false
          print("Package validation failed. Refining...")
        }
        
        if allValid {
          print("All files validated successfully.")
          break
        } else {
          // Refine prompt
          let refinePrompt = """
            \(basePrompt)
            
            Previous generation had validation issues (build or test failures). Refine the code to fix them, ensuring it implements real, functional logic that executes and produces verifiable results.
            Current NextSteps.json: \(String(data: try JSONSerialization.data(withJSONObject: current, options: .prettyPrinted), encoding: .utf8)!)
            
            Output JSON: {"files": [{"path": "...", "content": "..."}, ...]}
            """
          implResponse = try await callOllama(client: client, prompt: refinePrompt, system: systemPrompt)
          attempts += 1
        }
      } else {
        print("No files in response. Retrying...")
        attempts += 1
        implResponse = try await callOllama(client: client, prompt: implPrompt, system: systemPrompt)
      }
    }
    
    if attempts == maxAttempts {
      print("Max refinement attempts reached. Proceeding with best effort.")
    }
  }

  // Enhanced nextPrompt for better sprint planning
  let nextPrompt = """
    \(basePrompt)

    \(currentNextSteps != nil ? "Current sprint implemented and validated. Plan the next sprint." : "Generate initial sprint plan.")

    Output JSON: {
      "sprint_number": integer,
      "goal": "concise goal string",
      "tasks": ["task1", "task2", ...] (testable, artifact-producing tasks),
      "deliverable": "key deliverable description",
      "acceptance_criteria": ["criterion1", "criterion2", ...] (measurable criteria)
    }
    Tasks must advance the project, be specific, create code artifacts in Sources/Tests that implement real functionality, align with vision.
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
      print("Error: \(e.localizedDescription)")
    }
    try await client.shutdown()
    if let error {
      throw error
    }
  }
}
