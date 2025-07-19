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

struct Agent {
  let name: String
  let role: String
  let model: String = "devstral"
}

func runAgent(
  _ agent: Agent, prompt: String, client: HTTPClient
) async throws -> [String: Any] {
  let systemPrompt = "Output ONLY the precise JSON as specified in the prompt. No explanations, wrappers, or additional content. Adhere to format exactly."
  return try await callOllama(client: client, prompt: prompt, system: systemPrompt, model: agent.model)
}

// New function to validate the entire package and capture output
func validatePackage() throws -> (Bool, String?) {
  func runCommand(args: [String]) -> (Int32, String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = args
    
    let outPipe = Pipe()
    process.standardOutput = outPipe
    let errPipe = Pipe()
    process.standardError = errPipe
    
    try? process.run()
    process.waitUntilExit()
    
    let outputOptional = try? outPipe.fileHandleForReading.readToEnd()
    let outputData = outputOptional.flatMap { $0 } ?? Data()
    
    let errorOptional = try? errPipe.fileHandleForReading.readToEnd()
    let errorData = errorOptional.flatMap { $0 } ?? Data()
    
    let output = String(data: outputData, encoding: .utf8) ?? ""
    let error = String(data: errorData, encoding: .utf8) ?? ""
    
    return (process.terminationStatus, output + error)
  }
  
  let (buildStatus, buildOutput) = runCommand(args: ["build"])
  if buildStatus != 0 {
    return (false, "Build failed: \(buildOutput)")
  }
  
  let (testStatus, testOutput) = runCommand(args: ["test"])
  if testStatus != 0 {
    return (false, "Tests failed: \(testOutput)")
  }
  
  return (true, nil)
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
    let enumerator = fileManager.enumerator(at: baseURL, includingPropertiesForKeys: nil)

    while let file = enumerator?.nextObject() as? URL {
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

  let baseDescription = """
  The project directory structure:
  \(filesDescription)

  Strictly align all work with AgilePlan.md, StakeholderRequirements.md, README.md, and Vision.md.
  Follow Swift best practices: clean, modular code; proper error handling; concurrency safety; comprehensive comments.
  Ensure code is testable, efficient, secure, and performs actual functionality (no placeholders; implement real logic that executes and produces results).
  Use Swift conventions for naming, formatting.
  """

  let codeGenAgent = Agent(name: "CodeGenerator", role: "a senior Swift developer for generating high-quality, functional code")
  let refinerAgent = Agent(name: "CodeRefiner", role: "an expert code reviewer and fixer for refining Swift code based on errors")
  let plannerAgent = Agent(name: "SprintPlanner", role: "an expert project manager for planning Agile sprints")

  if let current = currentNextSteps {
    let currentJson = String(data: try JSONSerialization.data(withJSONObject: current, options: .prettyPrinted), encoding: .utf8)!

    let implPrompt = """
      You are \(codeGenAgent.role).
      \(baseDescription)

      Current NextSteps.json:
      \(currentJson)

      Implement tasks for sprint \(current["sprint_number"] ?? "unknown"). Generate high-quality Swift code for Sources/MetaAgentSystem and corresponding unit tests in Tests/MetaAgentSystemTests.
      Code must: compile without errors, include error handling, be modular, follow SOLID principles, and implement real, executable functionality that does something useful (e.g., processes data, calls APIs, runs agents).
      Tests must cover edge cases, use XCTest, and verify that the code performs its intended actions.

      Output JSON: {"files": [{"path": "Sources/MetaAgentSystem/File.swift", "content": "full code here"}, ...]}
      """

    var implResponse = try await runAgent(codeGenAgent, prompt: implPrompt, client: client)
    
    // Iteration loop for refinement
    var attempts = 0
    let maxAttempts = 3
    while attempts < maxAttempts {
      if let filesArray = implResponse["files"] as? [[String: String]] {
        for file in filesArray {
          if let path = file["path"], let content = file["content"] {
            let url = URL(fileURLWithPath: path)
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.data(using: .utf8)?.write(to: url)
            print("Generated: \(path)")
          }
        }
        
        // Validate the entire package after writing all files
        let (valid, errorMsg) = try validatePackage()
        if valid {
          print("All files validated successfully.")
          break
        } else {
          print("Package validation failed. Refining...")
          let refinePrompt = """
            You are \(refinerAgent.role).
            \(baseDescription)
            
            Previous generation had validation issues: \(errorMsg ?? "Unknown error").
            Refine the code to fix them, ensuring it implements real, functional logic that executes and produces verifiable results.
            Current NextSteps.json: \(currentJson)
            
            Output JSON: {"files": [{"path": "...", "content": "..."}, ...]}
            """
          implResponse = try await runAgent(refinerAgent, prompt: refinePrompt, client: client)
          attempts += 1
        }
      } else {
        print("No files in response. Retrying...")
        attempts += 1
        implResponse = try await runAgent(codeGenAgent, prompt: implPrompt, client: client)
      }
    }
    
    if attempts == maxAttempts {
      print("Max refinement attempts reached. Proceeding with best effort.")
    }
  }

  // Enhanced nextPrompt for better sprint planning
  let nextPrompt = """
    You are \(plannerAgent.role).
    \(baseDescription)

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

  let nextResponse = try await runAgent(plannerAgent, prompt: nextPrompt, client: client)

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
