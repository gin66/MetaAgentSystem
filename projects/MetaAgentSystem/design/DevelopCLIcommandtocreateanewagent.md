# Design Document for Developing CLI Command to Create a New Agent

## 1. Purpose
The purpose of this design is to outline the necessary components and interactions required to develop a CLI command that allows users to create new agents in the system.

## 2. Components
### 2.1 Agent Struct
- **Struct**: `Agent`
- **Purpose**: To represent agents within the system.
- **Fields**:
  - `id: String`: Unique identifier for the agent.
  - `role: String`: Role of the agent (e.g., admin, user).
  - `performanceScore: Double`: Performance score of the agent. This could be a value between 0 and 1 representing performance metrics.

### 2.2 AgentManager Class
- **Class**: `AgentManager`
- **Purpose**: To manage creation and maintenance of agents in the system.
- **Methods**:
  - `createAgent(id: String, role: String, performanceScore: Double) -> Agent`: Creates a new agent with the specified properties.

### 2.3 CLI Command
- **Command Name**: `create-agent`
- **Purpose**: To provide an interface for creating agents through command line input.
- **Parameters**:
  - `--id`: The ID of the new agent (required).
  - `--role`: The role of the new agent (required).
  - `--performanceScore`: The performance score of the new agent (required).

## 3. Interactions
### 3.1 Main Entry Point
The main entry point for using this command will typically involve invoking the CLI tool with appropriate parameters to create a new agent.
```bash
MetaAgentCLI create-agent --id=agent_002 --role=user --performanceScore=0.85
```
### 3.2 Example Usage in Main Program
In the main program, the `create-agent` command will interact with `AgentManager` to instantiate a new agent.
```swift
import Foundation

struct Agent {
    let id: String
    let role: String
    let performanceScore: Double
}

class AgentManager {
    func createAgent(id: String, role: String, performanceScore: Double) -> Agent {
        return Agent(id: id, role: role, performanceScore: performanceScore)
    }
}

struct MetaAgentCLI {
    static let agentManager = AgentManager()
    static func main(args: [String]) {
        guard args.count > 3 else { print("Usage: create-agent --id=<ID> --role=<ROLE> --performanceScore=<SCORE>"); return }

        var id: String? = nil
        var role: String? = nil
        var performanceScore: Double? = nil

        for (index, element) in args.enumerated() {
            switch element {
                case "--id":
                    if index + 1 < args.count { id = args[index + 1] }
                case "--role":
                    if index + 1 < args.count { role = args[index + 1] }
                case "--performanceScore":
                    if index + 1 < args.count {
                        performanceScore = Double(args[index + 1])
                    }
                default:
                    break
            }
        }

        if let id = id, let role = role, let score = performanceScore {
            let newAgent = agentManager.createAgent(id: id, role: role, performanceScore: score)
            print("Created Agent: \nID: \(newAgent.id)\nRole: \(newAgent.role)\nPerformance Score: \(newAgent.performanceScore)")
        } else {
            print("Usage: create-agent --id=<ID> --role=<ROLE> --performanceScore=<SCORE>")
        }
    }
}

MetaAgentCLI.main(args: CommandLine.arguments.dropFirst())
```
### 3.3 Unit Tests
Unit tests could involve verifying the correctness of creating new agents through CLI command execution.
```swift
import XCTest
@testable import MetaAgentSystem
class CLITests: XCTestCase {
    func testCreateAgentCommand() throws {
        let arguments = ["create-agent", "--id=agent_003", "--role=user", "--performanceScore=0.85"]
        MetaAgentCLI.main(args: arguments)
        // Additional verifications like checking console output
    }
}
```