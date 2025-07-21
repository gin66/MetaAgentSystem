// Unit tests for the AgentManager.
import XCTest
@testable import MetaAgentSystem
class AgentTests: XCTestCase {
    func testCreateAgent() throws {
        let agentManager = AgentManager()
        let newAgent = agentManager.createAgent(id: "agent_002", role: "user", performanceScore: 0.85)
        XCTAssertEqual(newAgent.id, "agent_002")
        XCTAssertEqual(newAgent.role, "user")
        XCTAssertEqual(newAgent.performanceScore, 0.85, accuracy: 0.0001)
    }
}