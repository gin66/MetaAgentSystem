import XCTest
@testable import MetaAgentSystem
class AgentTests: XCTestCase {
    func testInitialization() {
        let agent = Agent(id: UUID(), name: "Test Agent")
        XCTAssertEqual(agent.name, "Test Agent")
        XCTAssertTrue(agent.interactions.isEmpty)
    }
}

class InteractionTests: XCTestCase {
    func testInitialization() {
        let from = UUID()
        let to = UUID()
        let message = "Hello"
        let interaction = Interaction(from: from, to: to, message: message)
        XCTAssertEqual(interaction.from, from)
        XCTAssertEqual(interaction.to, to)
        XCTAssertEqual(interaction.message, message)
    }
}