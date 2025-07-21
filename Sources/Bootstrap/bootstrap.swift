import AsyncHTTPClient
import Foundation
import OpenAPIKit

//let bootstrap_model = "devstral:24b-small-2505-fp16"
let bootstrap_model = "devstral"
@MainActor let fm = FileManager.default

// MARK: - File Operations
@MainActor
func listProjectFiles(in directory: String) -> String {
    var result = [String]()
    if let enumerator = fm.enumerator(atPath: directory) {
        for case let path as String in enumerator {
            if path.hasSuffix(".swift") || path.hasSuffix(".md") || path.hasSuffix(".txt") || path.hasSuffix(".json") {
                result.append(path)
            }
        }
    }
    return result.sorted().joined(separator: "\n")
}

func readFile(in directory: String, relativePath: String) -> String {
    let fullPath = "\(directory)/\(relativePath)"
    do {
        return try String(contentsOfFile: fullPath, encoding: .utf8)
    } catch {
        return "Error reading \(relativePath): \(error.localizedDescription)"
    }
}

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

// MARK: - Prompt Management
func getPrompt(from file: String, substitutions: [String: String] = [:]) throws -> String {
    let path = "Sources/Bootstrap/prompts/\(file)"
    var promptTemplate = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
    
    for (key, value) in substitutions {
        promptTemplate = promptTemplate.replacingOccurrences(of: "{{\((key))}}", with: value)
    }
    
    return promptTemplate
}


// MARK: - AI Agent Interaction
func logOllamaCall(model: String, prompt: String, response: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let logEntry = """
    ---
    Timestamp: \(timestamp)
    Model: \(model)
    Prompt:
    \(prompt)
    Response:
    \(response)
    ---
    
    """
    
    if let logFileURL = URL(string: "file:///Users/jochen/src/MetaAgentSystem/ollama.log") {
        do {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(logEntry.data(using: .utf8)!)
            fileHandle.closeFile()
        } catch {
            do {
                try logEntry.data(using: .utf8)?.write(to: logFileURL)
            } catch {
                print("Could not write to ollama.log: \(error)")
            }
        }
    }
}

func callOllama(
  client: HTTPClient, prompt: String, system: String? = nil, model: String = bootstrap_model
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
  
  logOllamaCall(model: model, prompt: prompt, response: rawString)
  
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
  let model: String = bootstrap_model
}

func runAgent(
  _ agent: Agent, _ originalPrompt: String, client: HTTPClient, projectDirectory: String
) async throws -> [String: Any] {
  let systemPrompt = "Output ONLY the precise JSON as specified in the prompt. No explanations, wrappers, or additional content. Adhere to format exactly."
  
  let filesList = await listProjectFiles(in: projectDirectory)
  var allFilesContent = ""
  for file in filesList.components(separatedBy: "\n") {
      if file.isEmpty { continue }
      let content = readFile(in: projectDirectory, relativePath: file)
      allFilesContent += "\nFile: \(file)\n\(content)\n---\n"
  }

  let prompt = """
All project files content:
\(allFilesContent)

\(originalPrompt)
"""
  
  print("Call ollama \(agent.model)")
  let json = try await callOllama(client: client, prompt: prompt, system: systemPrompt, model: agent.model)
  
  return json
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

    // Prepare agents
    let plannerAgent = Agent(name: "SprintPlanner", role: "an expert project manager for planning Agile sprints")
    let docWriterAgent = Agent(name: "DocWriter", role: "a senior software architect for creating detailed design documents")
    let verifierAgent = Agent(name: "Verifier", role: "an expert software engineering verifier for designs and implementations")
    let codeGenAgent = Agent(name: "CodeGenerator", role: "a senior Swift developer for generating high-quality, functional code")
    let refinerAgent = Agent(name: "CodeRefiner", role: "an expert code reviewer and fixer for refining Swift code based on errors")

    // Prepare base description for prompts
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

    // Determine current sprint plan
    let currentNextSteps: [String: Any]?
    if fileManager.fileExists(atPath: nextStepsPath) {
        let data = try Data(contentsOf: URL(fileURLWithPath: nextStepsPath))
        currentNextSteps = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    } else {
        currentNextSteps = nil
    }

    // Main workflow loop
    if let current = currentNextSteps, let steps = current["steps"] as? [String], !steps.isEmpty {
        let sprintNumber = current["sprint_number"] as? Int ?? 0
        let goal = current["goal"] as? String ?? "N/A"
        
        for (index, step) in steps.enumerated() {
            print("\n--- Implementing Sprint \(sprintNumber), Step \(index + 1)/\(steps.count): \(step) ---")
            
            var designDocPath = ""
            var designDocContent = ""
            var generatedFiles: [[String: String]] = []
            var failureReason = ""

            for attempt in 1...5 {
                print("\n--- Attempt \(attempt)/5 ---")
                
                // 1. Design Phase (only on first attempt)
                if attempt == 1 {
                    let docPrompt = try getPrompt(from: "docwriter.prompt", substitutions: [
                        "role": docWriterAgent.role, "goal": goal, "step": step, "step_sanitized": step.filter { $0.isLetter || $0.isNumber }
                    ])
                    let docResponse = try await runAgent(docWriterAgent, docPrompt, client: client, projectDirectory: projectPath)
                    guard let designDoc = docResponse["design_document"] as? [String: String],
                          let path = designDoc["path"], let content = designDoc["content"] else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "DocWriter failed to produce a design document."])
                    }
                    designDocPath = path
                    designDocContent = content

                    // Verify Design
                    let verifyDesignPrompt = try getPrompt(from: "verifier_design.prompt", substitutions: [
                        "role": verifierAgent.role, "goal": goal, "step": step, "design_document_content": designDocContent
                    ])
                    let verifyDesignResponse = try await runAgent(verifierAgent, verifyDesignPrompt, client: client, projectDirectory: projectPath)
                    if let verified = verifyDesignResponse["verified"] as? Bool, verified {
                        print("Design for step '\(step)' has been verified.")
                    } else {
                        failureReason = "Design verification failed: \(verifyDesignResponse["feedback"] as? String ?? "No feedback")"
                        print(failureReason)
                        // For simplicity, we restart the whole step. A more advanced implementation could try to refine the design.
                        break 
                    }
                }

                // 2. Implementation or Refinement
                let codeFilesContent = generatedFiles.map { "Path: \($0["path"] ?? "")\n\($0["content"] ?? "")" }.joined(separator: "\n---\n")
                let activeAgent: Agent
                let agentPrompt: String

                if failureReason.isEmpty {
                    activeAgent = codeGenAgent
                    agentPrompt = try getPrompt(from: "codegen.prompt", substitutions: [
                        "role": codeGenAgent.role, "baseDescription": baseDescription, "design_document_content": designDocContent
                    ])
                } else {
                    print("--- Refining Implementation ---")
                    activeAgent = refinerAgent
                    agentPrompt = try getPrompt(from: "refiner.prompt", substitutions: [
                        "role": refinerAgent.role,
                        "baseDescription": baseDescription,
                        "design_document_content": designDocContent,
                        "failure_reason": failureReason,
                        "code_files_content": codeFilesContent
                    ])
                }
                
                let implResponse = try await runAgent(activeAgent, agentPrompt, client: client, projectDirectory: projectPath)
                
                if let filesArray = implResponse["files"] as? [[String: String]] {
                    generatedFiles = filesArray
                    for file in filesArray {
                        if let path = file["path"], let content = file["content"] {
                            let url = URL(fileURLWithPath: "\(projectPath)/\(path)")
                            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                            try content.data(using: .utf8)?.write(to: url)
                            print("Generated/Refined: \(path)")
                        }
                    }
                } else {
                    print("Warning: \(activeAgent.name) provided no files in the response.")
                }

                // 3. Verify Implementation
                let updatedCodeFilesContent = generatedFiles.map { "Path: \($0["path"] ?? "")\n\($0["content"] ?? "")" }.joined(separator: "\n---\n")
                let verifyImplPrompt = try getPrompt(from: "verifier_impl.prompt", substitutions: [
                    "design_document_content": designDocContent, "code_files_content": updatedCodeFilesContent
                ])
                let verifyImplResponse = try await runAgent(verifierAgent, verifyImplPrompt, client: client, projectDirectory: projectPath)
                if let verified = verifyImplResponse["verified"] as? Bool, verified {
                    print("Implementation for step '\(step)' has been verified.")
                    failureReason = "" // Clear failure reason
                } else {
                    failureReason = "Implementation verification failed: \(verifyImplResponse["feedback"] as? String ?? "No feedback")"
                    print(failureReason)
                    continue // Retry with refinement
                }

                // 4. Build and Test
                let (success, validationOutput) = validateSwiftPackage(in: projectPath)
                if success {
                    print("Build and tests passed.")
                    let designURL = URL(fileURLWithPath: "\(projectPath)/\(designDocPath)")
                    try fileManager.createDirectory(at: designURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try designDocContent.data(using: .utf8)?.write(to: designURL)
                    print("Saved design document: \(designDocPath)")

                    let commitMessage = "bootstrap: feat: Implement sprint \(sprintNumber) step: \(step)"
                    gitCommit(message: commitMessage, in: projectPath)
                    print("Workflow completed successfully for step: \(step).")
                    break 
                } else {
                    failureReason = validationOutput
                    print("Validation failed: \(failureReason)")
                }
                
                if attempt == 5 {
                    print("All 5 attempts failed for step: \(step).")
                    gitForceCheckout(in: projectPath)
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Workflow failed after 5 attempts. Changes were discarded."])
                }
            }
        }
    }

    // Plan the next sprint
    print("\n--- Planning Next Sprint ---")
    let sprintStatus = currentNextSteps != nil ? "Current sprint implemented. Plan the next sprint." : "Generate initial sprint plan for Sprint 1 as per AgilePlan.md."
    let agilePlanContent = readFile(in: projectPath, relativePath: "AgilePlan.md")
    let nextPrompt = try getPrompt(from: "planner.prompt", substitutions: [
        "role": plannerAgent.role,
        "baseDescription": baseDescription,
        "sprintStatus": sprintStatus,
        "agilePlanContent": agilePlanContent
    ])

    let nextResponse = try await runAgent(plannerAgent, nextPrompt, client: client, projectDirectory: projectPath)
    let outputData = try JSONSerialization.data(withJSONObject: nextResponse, options: .prettyPrinted)
    try outputData.write(to: URL(fileURLWithPath: nextStepsPath))
    print("NextSteps.json updated for the next sprint.")

    let commitMessage = "bootstrap: chore: Plan next sprint"
    gitCommit(message: commitMessage, in: projectPath)
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
