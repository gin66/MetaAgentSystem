// Unit Tests for Agent Communication
import XCTest
@testable import MetaAgentSystem
class AgentCommunicationTests: XCTestCase {
    var agent1: Agent!
    var agent2: Agent!
    override func setUp() {
        super.setUp()
        agent1 = Agent()
        agent2 = Agent()
    }
    func testSendMessage() {
        agent1.sendMessage("Hello", to: 2)
        XCTAssertEqual(agent2.receiveMessage(from: 1), "Hello")
    }
    func testReceiveMessage() {
        agent1.sendMessage("Hello", to: 2)
        let message = agent2.receiveMessage(from: 1)
        XCTAssertNotNil(message)
    }
}
