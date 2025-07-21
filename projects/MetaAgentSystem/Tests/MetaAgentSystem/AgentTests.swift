import XCTest
@testable import MetaAgentSystem

class AgentTests: XCTestCase {
    func testAgentInitialization() throws {
        let agent = Agent(id: "agent_001", role: "admin", performanceScore: 0.95)
        XCTAssertEqual(agent.id, "agent_001")
        XCTAssertEqual(agent.role, "admin")
        XCTAssertEqual(agent.performanceScore, 0.95, accuracy: 0.0001)
    }
}
