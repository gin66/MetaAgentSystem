import AsyncHTTPClient
import Foundation
import OpenAPIKit

let bootstrap_model = "devstral:24b-small-2505-fp16"
//let bootstrap_model = "devstral"
@MainActor let fm = FileManager.default

// MARK: - File Operations
@MainActor
func listProjectFiles(in directory: String) -> String {
    var result = [String]()
    if let enumerator = fm.enumerator(atPath: directory) {
        for case let path as String in enumerator {
            if path.contains("/.build/") || path.contains("/.git/") || path.hasPrefix(".build/") || path.hasPrefix(".git/") {
                continue
            }
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

func saveProgress(features: [[String: Any]], featuresPath: String, commitMessage: String, projectPath: String) throws {
    let data = try JSONSerialization.data(withJSONObject: features, options: .prettyPrinted)
    try data.write(to: URL(fileURLWithPath: featuresPath))
    gitCommit(message: commitMessage, in: projectPath)
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
final class PromptManager: Sendable {
    private let prompts: [String: String]

    init(filePath: String) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                self.prompts = json
            }
            else {
		self.prompts = [:]
            }
        } catch {
	    self.prompts = [:]
            print("Error loading prompts: \(error)")
        }
    }

    func getPrompt(byName name: String, substitutions: [String: String] = [:]) -> String? {
        guard var promptTemplate = prompts[name] else {
            return nil
        }

        for (key, value) in substitutions {
            promptTemplate = promptTemplate.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        return promptTemplate
    }
}

let promptManager = PromptManager(filePath: "docs/prompts.json")

func getPrompt(byName name: String, substitutions: [String: String] = [:]) throws -> String {
    guard let prompt = promptManager.getPrompt(byName: name, substitutions: substitutions) else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Prompt not found: \(name)"])
    }
    return prompt
}


// MARK: - AI Agent Interaction
func logOllamaCall(model: String, prompt: String, response: String? = nil) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    var logEntry = """
    ---
    Timestamp: \(timestamp)
    Model: \(model)
    Prompt:
    \(prompt)
    
    """

    if let response = response {
        logEntry += """
        Response:
        \(response)
        ---
        
        """
    } else {
        logEntry += """
        ---
        
        """
    }
    
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

  print("Sending request to Ollama with model: \(model)...")
  logOllamaCall(model: model, prompt: prompt)

  let response = try await client.execute(request, timeout: .seconds(120))

  guard response.status == .ok else {
    let errorDescription = "HTTP error: \(response.status)"
    print(errorDescription)
    logOllamaCall(model: model, prompt: prompt, response: errorDescription)
    throw NSError(
      domain: "", code: Int(response.status.code),
      userInfo: [NSLocalizedDescriptionKey: errorDescription])
  }

  let body = try await response.body.collect(upTo: 1024 * 1024 * 10)
  let data = Data(buffer: body)
  let rawString = String(data: data, encoding: .utf8) ?? "No data"
  
  print("Received response from Ollama.")
  logOllamaCall(model: model, prompt: prompt, response: rawString)
  
  guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    let errorDescription = "Failed to parse JSON: \(rawString)"
    print(errorDescription)
    logOllamaCall(model: model, prompt: prompt, response: errorDescription)
    throw NSError(
      domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorDescription])
  }

  if let error = json["error"] as? String {
    print("Ollama API error: \(error)")
    logOllamaCall(model: model, prompt: prompt, response: "Ollama API error: \(error)")
    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
  }

  guard let responseString = json["response"] as? String,
    let responseData = responseString.data(using: .utf8),
    var result = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
  else {
    let errorDescription = "Failed to parse LLM response: \(rawString)"
    print(errorDescription)
    logOllamaCall(model: model, prompt: prompt, response: errorDescription)
    throw NSError(
      domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorDescription])
  }
  result["status"] = "success"

  print("Successfully parsed Ollama response.")
  return result
}

struct Agent {
  let name: String
  let role: String
  let model: String = bootstrap_model
}

func runAgent(
  _ agent: Agent, _ originalPrompt: String, client: HTTPClient, projectDirectory: String, task: String
) async throws -> [String: Any] {
  let systemPrompt = "Output ONLY the precise JSON as specified in the prompt. No explanations, wrappers, or additional content. Adhere to format exactly."
  
  let configManagerAgent = Agent(name: "ConfigurationManager", role: "an expert at identifying relevant files for a task")
  let allFiles = await listProjectFiles(in: projectDirectory)
  
  let configPrompt = try getPrompt(byName: "configmanager", substitutions: [
      "task": task,
      "files": allFiles
  ])
  
  let configResponse = try await callOllama(client: client, prompt: configPrompt, system: systemPrompt, model: configManagerAgent.model)
  
  guard let status = configResponse["status"] as? String, status == "success", let relevantFiles = configResponse["files"] as? [String] else {
      throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "ConfigurationManager failed to produce a file list."])
  }
  
  var allFilesContent = ""
  for file in relevantFiles {
      if file.isEmpty { continue }
      let content = readFile(in: projectDirectory, relativePath: file)
      allFilesContent += "\nFile: \(file)\n\(content)\n---\n"
  }

  if agent.name == "RequirementsManager" {
      let visionPath = "docs/Vision.md"
      if !relevantFiles.contains(visionPath) {
          let visionContent = readFile(in: projectDirectory, relativePath: visionPath)
          allFilesContent += "\nFile: \(visionPath)\n\(visionContent)\n---\n"
      }
      let stakeholderPath = "docs/StakeholderRequirements.md"
      if !relevantFiles.contains(stakeholderPath) {
          let stakeholderContent = readFile(in: projectDirectory, relativePath: stakeholderPath)
          allFilesContent += "\nFile: \(stakeholderPath)\n\(stakeholderContent)\n---\n"
      }
  }

  let prompt = """
Relevant project files content:
\(allFilesContent)

\(originalPrompt)
"""
  
  print("running agent \(agent.name)")
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
    let featureInitializerAgent = Agent(name: "FeatureInitializer", role: "extract and create initial features or meta-feature")
    let requirementsManagerAgent = Agent(name: "RequirementsManager", role: "manage the database of features and use cases")
    let prioritizerAgent = Agent(name: "Prioritizer", role: "prioritize features/use cases")
    let clarityJudgeAgent = Agent(name: "ClarityJudge", role: "judge if a feature is clear enough for implementation")
    let decompositionAgent = Agent(name: "Decomposition", role: "decompose complex features")
    let refactorAgent = Agent(name: "Refactor", role: "refactor system architecture when needed")
    let docWriterAgent = Agent(name: "DocWriter", role: "a senior software architect for creating detailed design documents")
    let verifierAgent = Agent(name: "Verifier", role: "an expert software engineering verifier for designs and implementations")
    let codeGenAgent = Agent(name: "CodeGenerator", role: "a senior Swift developer for generating high-quality, functional code")
    let refinerAgent = Agent(name: "CodeRefiner", role: "an expert code reviewer and fixer for refining Swift code based on errors")
    let errorAnalyzerAgent = Agent(name: "ErrorAnalyzer", role: "an expert Swift build error analyst")

    // Prepare base description for prompts
    var filesDescription = ""
    let metadataFiles: [String: String] = [
        "README.md": "Project overview, setup, and usage instructions.",
        "docs/StakeholderRequirements.md": "List of all stakeholder requirements.",
        "docs/Vision.md": "High-level vision for the system.",
        "Package.swift": "Swift Package Manager manifest.",
        "design/SystemArchitecture.md": "Overview of the entire system architecture.",
        "design/BootstrapProcess.md": "Description of the bootstrapping process.",
        "design/AgentCommunication.md": "Description of agent communication.",
        "design/ConfigurationManager.md": "Description of the Configuration Manager agent.",
        "design/Workflow.md": "Description of the main workflow.",
        "design/RequirementsManagement.md": "Description of requirements management and feature database.",
        "design/Prioritization.md": "Description of use case prioritization.",
        "design/Decomposition.md": "Description of feature decomposition and hierarchical design.",
        "design/Refactoring.md": "Description of architecture refactoring.",
    ]
    for (file, desc) in metadataFiles {
        filesDescription += "- \(file): \(desc)\n"
    }
    let baseDescription = """
The project directory structure:
\(filesDescription)
Strictly align all work with docs/StakeholderRequirements.md and docs/Vision.md.
Follow Swift best practices. Ensure code is testable, efficient, and implements real functionality.
Do not modify bootstrap.swift.
All file paths are relative to the project root: \(projectPath).
"""

    // Feature database path
    let featuresPath = "\(projectPath)/db/features.json"
    try? fileManager.createDirectory(atPath: "\(projectPath)/db", withIntermediateDirectories: true)

    // Load features using RequirementsManager
    var features: [[String: Any]] = []
    let readPrompt = try getPrompt(byName: "RequirementsManager", substitutions: ["operation": "read", "feature_details": ""])
    let readResponse = try await runAgent(requirementsManagerAgent, readPrompt, client: client, projectDirectory: projectPath, task: "Read feature database")
    if let status = readResponse["status"] as? String, status == "success", let readFeatures = readResponse["features"] as? [[String: Any]] {
        features = readFeatures
    } else {
        // Silently fail, features will be empty, and initialization will run.
    }

    // Check for inconsistent state: features exist, but none are pending.
    let hasPending = features.contains {
        let status = ($0["status"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return status == "pending" || status.isEmpty
    }
    if !features.isEmpty && !hasPending {
        print("Warning: Feature database contains features, but none are in 'pending' state. Re-initializing feature database.")
        features = []
    }

// Initialize features if empty using FeatureInitializer
if features.isEmpty {
    print("\n--- Initializing Feature Database with FeatureInitializer ---")
    let visionContent = readFile(in: projectPath, relativePath: "docs/Vision.md")
    let stakeholderContent = readFile(in: projectPath, relativePath: "docs/StakeholderRequirements.md")
    let documentsContent = """
Vision.md:
\(visionContent)

StakeholderRequirements.md:
\(stakeholderContent)
"""
    let initPrompt = try getPrompt(byName: "FeatureInitializer", substitutions: ["documents_content": documentsContent])
    let initResponse = try await runAgent(featureInitializerAgent, initPrompt, client: client, projectDirectory: projectPath, task: "Initialize features or meta-feature")
    
    if let status = initResponse["status"] as? String, status == "success", let initFeatures = initResponse["features"] as? [[String: Any]], !initFeatures.isEmpty {
        let featureDetails = String(data: try JSONSerialization.data(withJSONObject: initFeatures, options: .prettyPrinted), encoding: .utf8) ?? ""
        let createPrompt = try getPrompt(byName: "RequirementsManager", substitutions: ["operation": "create", "feature_details": featureDetails])
        let createResponse = try await runAgent(requirementsManagerAgent, createPrompt, client: client, projectDirectory: projectPath, task: "Create initial features")
        if let status = createResponse["status"] as? String, status == "success", let newFeatures = createResponse["features"] as? [[String: Any]] {
            features = newFeatures
            try saveProgress(features: features, featuresPath: featuresPath, commitMessage: "bootstrap: chore: Initialize feature database", projectPath: projectPath)
            print("Feature database initialized with \(features.count) features.")
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create initial features."])
        }
    } else {
        print("FeatureInitializer failed to produce valid features. Creating fallback meta-feature.")
        let metaFeature = [
            "id": "meta-1",
            "description": "Implement MetaAgentSystem per Vision and StakeholderRequirements",
            "test_plan": "Verify system initializes, agents communicate, and tasks are assigned per Vision.md and StakeholderRequirements.md",
            "status": "pending",
            "priority": 0
        ] as [String: Any]
        let featureDetails = String(data: try JSONSerialization.data(withJSONObject: [metaFeature], options: .prettyPrinted), encoding: .utf8) ?? ""
        let createPrompt = try getPrompt(byName: "RequirementsManager", substitutions: ["operation": "create", "feature_details": featureDetails])
        let createResponse = try await runAgent(requirementsManagerAgent, createPrompt, client: client, projectDirectory: projectPath, task: "Create fallback meta-feature")
        if let status = createResponse["status"] as? String, status == "success", let newFeatures = createResponse["features"] as? [[String: Any]] {
            features = newFeatures
            try saveProgress(features: features, featuresPath: featuresPath, commitMessage: "bootstrap: chore: Initialize feature database with meta-feature", projectPath: projectPath)
            print("Feature database initialized with meta-feature.")
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create fallback meta-feature."])
        }
    }
}

    // Prioritize features
    print("\n--- Prioritizing Features ---")
    let featuresListJSON = try JSONSerialization.data(withJSONObject: features.map { ["id": $0["id"] ?? "", "description": $0["description"] ?? ""] }, options: [])
    let featuresList = String(data: featuresListJSON, encoding: .utf8) ?? ""
    let criteria = "urgency, impact, dependencies"
    let prioritizerPrompt = try getPrompt(byName: "Prioritizer", substitutions: ["features_list": featuresList, "criteria": criteria])
    let prioritizerResponse = try await runAgent(prioritizerAgent, prioritizerPrompt, client: client, projectDirectory: projectPath, task: "Prioritize features")
    if let status = prioritizerResponse["status"] as? String, status == "success", let prioritized = prioritizerResponse["prioritized_features"] as? [[String: Any]] {
        let priorityUpdates = String(data: try JSONSerialization.data(withJSONObject: prioritized, options: .prettyPrinted), encoding: .utf8) ?? ""
        let updatePriorityPrompt = try getPrompt(byName: "RequirementsManager", substitutions: ["operation": "update", "feature_details": priorityUpdates])
        let updatePriorityResponse = try await runAgent(requirementsManagerAgent, updatePriorityPrompt, client: client, projectDirectory: projectPath, task: "Update feature priorities")
        if let status = updatePriorityResponse["status"] as? String, status == "success", let updatedFeatures = updatePriorityResponse["features"] as? [[String: Any]] {
            features = updatedFeatures
            try saveProgress(features: features, featuresPath: featuresPath, commitMessage: "bootstrap: chore: Update feature priorities", projectPath: projectPath)
        }
    }

    // Process all pending features in a loop
    while true {
        // Reload features from the database at the beginning of each iteration to ensure consistency
        let readPrompt = try getPrompt(byName: "RequirementsManager", substitutions: ["operation": "read", "feature_details": ""])
        let readResponse = try await runAgent(requirementsManagerAgent, readPrompt, client: client, projectDirectory: projectPath, task: "Read feature database")
        if let status = readResponse["status"] as? String, status == "success", let readFeatures = readResponse["features"] as? [[String: Any]] {
            features = readFeatures
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read features at the start of the processing loop."])
        }

        // Sort features by priority (lower number = higher priority)
        features.sort { ($0["priority"] as? Int ?? Int.max) < ($1["priority"] as? Int ?? Int.max) }

        // Process the highest priority pending feature
        guard let featureIndex = features.firstIndex(where: {
            let status = ($0["status"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return status == "pending" || status.isEmpty
        }) else {
            print("No more pending features to process. Exiting.")
            break // Exit the loop
        }

        let feature = features[featureIndex]
        let featureId = feature["id"] as? String ?? "unknown"
        let description = feature["description"] as? String ?? ""
        let testPlan = feature["test_plan"] as? String ?? ""
        print("\n--- Processing Feature \(featureId): \(description) ---")

        // Judge clarity and atomicity
        let clarityPrompt = try getPrompt(byName: "ClarityJudge", substitutions: ["feature_description": description])
        let clarityResponse = try await runAgent(clarityJudgeAgent, clarityPrompt, client: client, projectDirectory: projectPath, task: "Judge clarity for feature \(featureId): \(description)")
        let clear = clarityResponse["clear"] as? Bool ?? false
        let atomic = clarityResponse["atomic"] as? Bool ?? false
        let feedback = clarityResponse["feedback"] as? String ?? ""

        if !clear || !atomic {
            // Decompose
            print("\n--- Decomposing Feature \(featureId) ---")
            var decompPrompt = try getPrompt(byName: "Decomposition", substitutions: ["feature_description": description])
            decompPrompt += "\nFor each sub-feature, output an array of objects with 'description' and 'test_plan' keys. Ensure max 5 sub-features."
            let decompResponse = try await runAgent(decompositionAgent, decompPrompt, client: client, projectDirectory: projectPath, task: "Decompose feature \(featureId): \(description)")
            if let status = decompResponse["status"] as? String, status == "success", let subFeatures = decompResponse["sub_features"] as? [[String: String]] {
                let subFeaturesJSON = String(data: try JSONSerialization.data(withJSONObject: subFeatures, options: .prettyPrinted), encoding: .utf8) ?? ""
                let decomposeDetails = """
    Update id \(featureId) status to 'decomposed'. Add sub-features: \(subFeaturesJSON) with ids like \(featureId).1, priority 0, status 'pending'.
    """
                let decomposePrompt = try getPrompt(byName: "RequirementsManager", substitutions: ["operation": "update", "feature_details": decomposeDetails])
                let decomposeResponse = try await runAgent(requirementsManagerAgent, decomposePrompt, client: client, projectDirectory: projectPath, task: "Decompose and update features for \(featureId)")
                if let status = decomposeResponse["status"] as? String, status == "success", let updatedFeatures = decomposeResponse["features"] as? [[String: Any]] {
                    features = updatedFeatures
                    try saveProgress(features: features, featuresPath: featuresPath, commitMessage: "bootstrap: chore: Decompose feature \(featureId)", projectPath: projectPath)
                }
            }

            // Check for refactoring need
            if feedback.lowercased().contains("architecture") || feedback.lowercased().contains("refactor") {
                print("\n--- Refactoring Architecture for Feature \(featureId) ---")
                let archContent = readFile(in: projectPath, relativePath: "design/SystemArchitecture.md")
                let refactorPrompt = try getPrompt(byName: "Refactor", substitutions: ["feature_description": description, "architecture_content": archContent])
                let refactorResponse = try await runAgent(refactorAgent, refactorPrompt, client: client, projectDirectory: projectPath, task: "Refactor for feature \(featureId): \(description)")
                if let status = refactorResponse["status"] as? String, status == "success", let updatedDesign = refactorResponse["updated_design"] as? [String: String],
                   let path = updatedDesign["path"],
                   let content = updatedDesign["content"] {
                    let url = URL(fileURLWithPath: "\(projectPath)/\(path)")
                    try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try content.data(using: .utf8)?.write(to: url)
                    gitCommit(message: "bootstrap: refactor: Update \(path) for feature \(featureId)", in: projectPath)
                }
            }
            continue
        }
        // Implement the feature
        print("\n--- Implementing Feature \(featureId): \(description) ---")
        let goal = "Implement feature: \(description)"
        let step = description
        var designDocPath = ""
        var designDocContent = ""
        var generatedFiles: [[String: String]] = []
        var failureReason = ""
        var additionalContext = ""

        for attempt in 1...5 {
            print("\n--- Attempt \(attempt)/5 for Feature \(featureId) ---")
            
            // 1. Design Phase
            var designVerified = false
            if attempt == 1 {
                for designAttempt in 1...3 {
                    print("\n--- Design Attempt \(designAttempt)/3 ---")
                    
                    var docPromptText: String
                    if designAttempt == 1 {
                        docPromptText = try getPrompt(byName: "docwriter", substitutions: [
                            "role": docWriterAgent.role, "goal": goal, "step": step, "step_sanitized": String(step.hash)
                        ])
                    } else {
                        print("--- Refining Design ---")
                        docPromptText = try getPrompt(byName: "docwriter", substitutions: [
                            "role": docWriterAgent.role, "goal": goal, "step": "\(step) (Refinement attempt after failure: \(failureReason))", "step_sanitized": String(step.hash)
                        ])
                    }
                    docPromptText += "\nInclude a Test Plan section with strategy, execution steps, and criteria based on: \(testPlan)"

                    let docResponse = try await runAgent(docWriterAgent, docPromptText, client: client, projectDirectory: projectPath, task: step)
                    guard let status = docResponse["status"] as? String, status == "success", let designDoc = docResponse["design_document"] as? [String: String],
                          let path = designDoc["path"], let content = designDoc["content"] else {
                        print("Warning: DocWriter failed to produce a design document. Retrying...")
                        failureReason = "DocWriter failed to produce a design document."
                        continue
                    }
                    designDocPath = path
                    designDocContent = content

                    // Verify Design
                    let verifyDesignPrompt = try getPrompt(byName: "verifier_design", substitutions: [
                        "role": verifierAgent.role, "goal": goal, "step": step, "design_document_content": designDocContent
                    ])
                    let verifyDesignResponse = try await runAgent(verifierAgent, verifyDesignPrompt, client: client, projectDirectory: projectPath, task: "Verify the design for feature \(featureId): \(description)")
                    if let verified = verifyDesignResponse["verified"] as? Bool, verified {
                        print("Design for feature '\(featureId)' has been verified.")
                        designVerified = true
                        failureReason = ""
                        break
                    } else {
                        failureReason = "Design verification failed: \(verifyDesignResponse["feedback"] as? String ?? "No feedback")"
                        print(failureReason)
                    }
                }

                if !designVerified {
                    print("Design phase failed after 3 attempts for feature: \(featureId). Discarding all changes and stopping.")
                    gitForceCheckout(in: projectPath)
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Design phase failed after 3 attempts. Changes were discarded."])
                }
            }

            // 2. Implementation or Refinement
            var codeFilesContent = generatedFiles.map { "Path: \($0["path"] ?? "")\n\($0["content"] ?? "")" }.joined(separator: "\n---\n")
            let activeAgent: Agent
            let agentPrompt: String

            if failureReason.isEmpty {
                activeAgent = codeGenAgent
                agentPrompt = try getPrompt(byName: "codegen", substitutions: [
                    "role": codeGenAgent.role, "baseDescription": baseDescription, "design_document_content": designDocContent
                ])
            } else {
                print("--- Refining Implementation ---")
                activeAgent = refinerAgent
                
                if !additionalContext.isEmpty {
                    codeFilesContent += "\n\n--- Additional Context: Original Definitions ---\n" + additionalContext
                }

                agentPrompt = try getPrompt(byName: "refiner", substitutions: [
                    "role": refinerAgent.role,
                    "baseDescription": baseDescription,
                    "design_document_content": designDocContent,
                    "failure_reason": failureReason,
                    "code_files_content": codeFilesContent
                ])
            }
            
            let implResponse = try await runAgent(activeAgent, agentPrompt, client: client, projectDirectory: projectPath, task: goal)
            
            if let status = implResponse["status"] as? String, status == "success", let filesArray = implResponse["files"] as? [[String: String]] {
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
            var implementationVerified = false
            for implAttempt in 1...3 {
                print("--- Implementation Verification Attempt \(implAttempt)/3 ---")
                let updatedCodeFilesContent = generatedFiles.map { "Path: \($0["path"] ?? "")\n\($0["content"] ?? "")" }.joined(separator: "\n---\n")
                let verifyImplPrompt = try getPrompt(byName: "verifier_impl", substitutions: [
                    "design_document_content": designDocContent, "code_files_content": updatedCodeFilesContent
                ])
                let verifyImplResponse = try await runAgent(verifierAgent, verifyImplPrompt, client: client, projectDirectory: projectPath, task: "Verify the implementation for feature \(featureId): \(description)")
                if let verified = verifyImplResponse["verified"] as? Bool, verified {
                    print("Implementation for feature '\(featureId)' has been verified.")
                    failureReason = ""
                    implementationVerified = true
                    break
                } else {
                    failureReason = "Implementation verification failed: \(verifyImplResponse["feedback"] as? String ?? "No feedback")"
                    print(failureReason)
                    // Refine based on feedback
                    print("--- Refining Implementation based on verification feedback ---")
                    let activeAgent = refinerAgent
                    let agentPrompt = try getPrompt(byName: "refiner", substitutions: [
                        "role": refinerAgent.role,
                        "baseDescription": baseDescription,
                        "design_document_content": designDocContent,
                        "failure_reason": failureReason,
                        "code_files_content": updatedCodeFilesContent
                    ])
                    let implResponse = try await runAgent(activeAgent, agentPrompt, client: client, projectDirectory: projectPath, task: "Refine the implementation for feature \(featureId)")
                    if let status = implResponse["status"] as? String, status == "success", let filesArray = implResponse["files"] as? [[String: String]] {
                        generatedFiles = filesArray
                        for file in filesArray {
                            if let path = file["path"], let content = file["content"] {
                                let url = URL(fileURLWithPath: "\(projectPath)/\(path)")
                                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                                try content.data(using: .utf8)?.write(to: url)
                                print("Refined: \(path)")
                            }
                        }
                    } else {
                        print("Warning: \(activeAgent.name) provided no files in the response during refinement.")
                    }
                }
            }

            if !implementationVerified {
                print("Implementation verification failed after 3 attempts for feature: \(featureId). Discarding changes for this feature and retrying from scratch.")
                gitForceCheckout(in: projectPath)
                continue
            }

            // 4. Build and Test (includes regression)
            let (success, validationOutput) = validateSwiftPackage(in: projectPath)
            if success {
                print("Build and tests passed.")
                let designURL = URL(fileURLWithPath: "\(projectPath)/\(designDocPath)")
                try fileManager.createDirectory(at: designURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try designDocContent.data(using: .utf8)?.write(to: designURL)
                print("Saved design document: \(designDocPath)")

                let commitMessage = "bootstrap: feat: Implement feature \(featureId): \(step)"
                gitCommit(message: commitMessage, in: projectPath)
                print("Workflow completed successfully for feature: \(featureId).")
                
                // Update feature status using RequirementsManager
                let completeDetails = "Set status of id \(featureId) to completed"
                let completePrompt = try getPrompt(byName: "RequirementsManager", substitutions: ["operation": "update", "feature_details": completeDetails])
                let completeResponse = try await runAgent(requirementsManagerAgent, completePrompt, client: client, projectDirectory: projectPath, task: "Mark feature \(featureId) as completed")
                if let status = completeResponse["status"] as? String, status == "success", let updatedFeatures = completeResponse["features"] as? [[String: Any]] {
                    features = updatedFeatures
                    try saveProgress(features: features, featuresPath: featuresPath, commitMessage: "bootstrap: chore: Mark feature \(featureId) as completed", projectPath: projectPath)
                }
                
                break 
            } else {
                failureReason = validationOutput
                print("Validation failed. Running ErrorAnalyzerAgent...")

                let errorAnalysisPrompt = try getPrompt(byName: "erroranalyzer", substitutions: [
                    "failure_reason": failureReason
                ])
                
                do {
                    let errorResponse = try await runAgent(errorAnalyzerAgent, errorAnalysisPrompt, client: client, projectDirectory: projectPath, task: "Analyze build failure for feature \(featureId): \(description)")
                    if let status = errorResponse["status"] as? String, status == "success", let analysis = errorResponse["analysis"] as? String {
                        print("Error analysis received: \(analysis)")
                        failureReason = "\(analysis)\n\nFull build output:\n\(failureReason)"
                    } else {
                        print("Warning: ErrorAnalyzerAgent did not provide a valid analysis.")
                    }

                    if let relevantFiles = errorResponse["relevant_files"] as? [String] {
                        print("Error analyzer identified relevant files: \(relevantFiles.joined(separator: ", "))")
                        additionalContext = ""
                        for file in relevantFiles {
                            let content = readFile(in: projectPath, relativePath: file)
                            additionalContext += "\n\n--- Original Definition File: \(file) ---\n\(content)"
                        }
                    }

                } catch {
                    print("ErrorAnalyzerAgent failed: \(error.localizedDescription). Proceeding with original failure reason.")
                }
            }
            
            if attempt == 5 {
                print("All 5 attempts failed for feature: \(featureId).")
                gitForceCheckout(in: projectPath)
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Workflow failed after 5 attempts. Changes were discarded."])
            }
        }
    }
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
