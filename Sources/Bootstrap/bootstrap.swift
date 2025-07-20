import AsyncHTTPClient
import Foundation
import OpenAPIKit

// MARK: - Shell Command Execution
func runShellCommand(_ command: String, in directory: String? = nil) -> (status: Int32, output: String) {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    
    if let directory = directory {
        task.currentDirectoryPath = directory
    }
    
    do {
        try task.run()
    } catch {
        return (-1, "Failed to run command: \(error.localizedDescription)")
    }
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    
    task.waitUntilExit()
    return (task.terminationStatus, output)
}

// MARK: - Git Operations
func isGitClean(in directory: String) -> Bool {
    let (status, output) = runShellCommand("git status --porcelain", in: directory)
    return status == 0 && output.isEmpty
}

func gitForceCheckout(in directory: String) {
    print("Persistent failure. Discarding all changes...")
    _ = runShellCommand("git checkout -- .", in: directory)
    print("Changes have been discarded.")
}

func gitCommit(message: String, in directory: String) {
    print("Committing changes to the repository...")
    _ = runShellCommand("git add .", in: directory)
    let (status, output) = runShellCommand("git commit -m \"\(message)\"", in: directory)
    if status == 0 {
        print("Successfully committed changes.")
    } else {
        print("Error: Git commit failed.\nOutput:\n\(output)")
    }
}

// MARK: - Swift Package Validation
func validateSwiftPackage(in directory: String) -> (Bool, String) {
    print("Validating Swift package: Building and running tests...")
    let (buildStatus, buildOutput) = runShellCommand("swift build", in: directory)
    if buildStatus != 0 {
        let error = "Swift build failed."
        print(error)
        return (false, "\(error)\n\(buildOutput)")
    }
    
    let (testStatus, testOutput) = runShellCommand("swift test", in: directory)
    if testStatus != 0 {
        let error = "Swift tests failed."
        print(error)
        return (false, "\(error)\n\(testOutput)")
    }
    
    print("Swift package validation successful.")
    return (true, "Build and tests passed.")
}


// MARK: - AI Agent Interaction
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

  let body = try await response.body.collect(upTo: 1024 * 1024 * 10)
  let data = Data(buffer: body)
  let rawString = String(data: data, encoding: .utf8) ?? "No data"
  
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

// MARK: - Core Workflow
func bootstrapNextSteps(client: HTTPClient) async throws {
    let fileManager = FileManager.default
    let projectPath = "projects/MetaAgentSystem"
    
    // 1. Verify Clean State
    guard isGitClean(in: projectPath) else {
        print("Error: Git working directory is not clean. Please commit or stash changes before starting.")
        return
    }

    // Prepare prompts and agents
    let nextStepsPath = "\(projectPath)/NextSteps.json"
    var filesDescription = ""
    let metadataFiles: [String: String] = [
        "AgilePlan.md": "Detailed Agile implementation plan.",
        "README.md": "Project overview, setup, and usage instructions.",
        "StakeholderRequirements.md": "List of all stakeholder requirements.",
        "Vision.md": "High-level vision for the system.",
        "Package.swift": "Swift Package Manager manifest.",
    ]

    for (file, desc) in metadataFiles {
        filesDescription += "- \(file): \(desc)\n"
    }
    
    let baseDescription = """
The project directory structure:
\(filesDescription)
Strictly align all work with AgilePlan.md, StakeholderRequirements.md, and Vision.md.
Follow Swift best practices. Ensure code is testable, efficient, and implements real functionality.
Do not modify bootstrap.swift.
All file paths are relative to the project root: \(projectPath).
"""
    
    let codeGenAgent = Agent(name: "CodeGenerator", role: "a senior Swift developer for generating high-quality, functional code")
    let refinerAgent = Agent(name: "CodeRefiner", role: "an expert code reviewer and fixer for refining Swift code based on errors")
    let plannerAgent = Agent(name: "SprintPlanner", role: "an expert project manager for planning Agile sprints")

    // Determine current sprint and plan
    let currentNextSteps: [String: Any]?
    if fileManager.fileExists(atPath: nextStepsPath) {
        let data = try Data(contentsOf: URL(fileURLWithPath: nextStepsPath))
        currentNextSteps = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    } else {
        currentNextSteps = nil
    }

    if let current = currentNextSteps {
        let currentJson = String(data: try JSONSerialization.data(withJSONObject: current, options: .prettyPrinted), encoding: .utf8)!
        let sprintNumber = current["sprint_number"] as? Int ?? 0
        
        let implPrompt = """
          You are \(codeGenAgent.role).
          \(baseDescription)
          Current NextSteps.json:
          \(currentJson)
          Implement tasks for sprint \(sprintNumber). Generate high-quality Swift code for Sources/MetaAgentSystem and corresponding unit tests in Tests/MetaAgentSystemTests.
          Output JSON: {"files": [{"path": "Sources/MetaAgentSystem/File.swift", "content": "full code here"}, ...]}
          """

        var lastError = ""
        for attempt in 1...5 {
            print("\n--- Attempt \(attempt)/5 ---")
            
            // 2. Perform Requested Change (Agent generates code)
            let agentPrompt = lastError.isEmpty ? implPrompt : """
                You are \(refinerAgent.role).
                \(baseDescription)
                The previous attempt failed. Refine the code to fix the issue.
                Validation Error: \(lastError)
                Current NextSteps.json: \(currentJson)
                Output JSON: {"files": [{"path": "...", "content": "..."}, ...]}
                """
            
            let activeAgent = lastError.isEmpty ? codeGenAgent : refinerAgent
            let implResponse = try await runAgent(activeAgent, prompt: agentPrompt, client: client)

            if let filesArray = implResponse["files"] as? [[String: String]] {
                for file in filesArray {
                    if let path = file["path"], let content = file["content"] {
                        if path.hasSuffix("bootstrap.swift") {
                            print("Skipping overwrite of bootstrap.swift")
                            continue
                        }
                        let url = URL(fileURLWithPath: "\(projectPath)/\(path)")
                        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                        try content.data(using: .utf8)?.write(to: url)
                        print("Generated/Modified: \(path)")
                    }
                }
            } else {
                print("Warning: Agent provided no files in the response.")
            }

            // 3. Build and Test
            let (success, validationOutput) = validateSwiftPackage(in: projectPath)
            lastError = validationOutput
            
            if success {
                // 6. Commit on Success
                let commitMessage = "feat: Implement sprint \(sprintNumber) - \(current["goal"] ?? "updates")"
                gitCommit(message: commitMessage, in: projectPath)
                print("Workflow completed successfully for sprint \(sprintNumber).")
                break // Exit loop
            }
            
            if attempt == 5 {
                // 5. Handle Persistent Failure
                print("All 5 attempts failed.")
                gitForceCheckout(in: projectPath)
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Workflow failed after 5 attempts. Changes were discarded."])
            }
        }
    }

    // Plan the next sprint
    let nextPrompt = """
    You are \(plannerAgent.role).
    \(baseDescription)
    \(currentNextSteps != nil ? "Current sprint implemented. Plan the next sprint." : "Generate initial sprint plan.")
    Output JSON: {
      "sprint_number": integer,
      "goal": "concise goal string",
      "tasks": ["task1", "task2", ...],
      "deliverable": "key deliverable description",
      "acceptance_criteria": ["criterion1", "criterion2", ...]
    }
    """

    let nextResponse = try await runAgent(plannerAgent, prompt: nextPrompt, client: client)
    let outputData = try JSONSerialization.data(withJSONObject: nextResponse, options: .prettyPrinted)
    try outputData.write(to: URL(fileURLWithPath: nextStepsPath))
    print("NextSteps.json updated for the next sprint.")
}

@main
struct Bootstrap {
  static func main() async throws {
    let client = HTTPClient(
      eventLoopGroupProvider: .singleton,
      configuration: HTTPClient.Configuration(
        timeout: HTTPClient.Configuration.Timeout(connect: .seconds(30), read: .seconds(300))))
    
    var workflowError: Error?
    do {
      try await bootstrapNextSteps(client: client)
    } catch {
      workflowError = error
      print("\nFATAL ERROR: \(error.localizedDescription)")
    }
    
    try await client.shutdown()
    
    if let workflowError {
      throw workflowError
    }
  }
}
