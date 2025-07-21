# Design Document for Creating an Agent Struct

## 1. Purpose
The purpose of this design is to outline the necessary components and interactions required to create an `Agent` struct with fields for ID, role, and performance score.

## 2. Components
### 2.1 Agent Struct
- **Struct**: `Agent`
- **Purpose**: To represent agents in the system.
- **Fields**: 
  - `id: String`: Unique identifier for the agent.
  - `role: String`: Role of the agent (e.g., admin, user).
  - `performanceScore: Double`: Performance score of the agent. This could be a value between 0 and 1 representing performance metrics.

## 3. Interactions
### 3.1 Main Entry Point
The main entry point for using this struct will typically involve creating instances of the `Agent` struct with appropriate values for their fields.
```swift
let agent = Agent(id: "agent_001", role: "admin", performanceScore: 0.95)
print(agent)
```
### 3.2 Example Usage in Main Program
In a main program or test file, you would instantiate the `Agent` struct and use it as needed.
```swift
import Foundation

struct Agent {
    let id: String
    let role: String
    let performanceScore: Double
}

let agent1 = Agent(id: "agent_001", role: "admin", performanceScore: 0.95)
print(agent1.id)          // Output: agent_001
print(agent1.role)        // Output: admin
print(agent1.performanceScore)   // Output: 0.95
```
### 3.3 Unit Tests
Unit tests could involve verifying the correctness of initializing and accessing fields in the `Agent` struct.
```swift
import XCTest
@testable import YourModuleName

class AgentTests: XCTestCase {
    func testAgentInitialization() throws {
        let agent = Agent(id: "agent_001", role: "admin", performanceScore: 0.95)
        XCTAssertEqual(agent.id, "agent_001")
        XCTAssertEqual(agent.role, "admin")
        XCTAssertEqual(agent.performanceScore, 0.95, accuracy: 0.0001)
    }
}
```
