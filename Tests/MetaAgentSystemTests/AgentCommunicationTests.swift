// Write unit tests for agent communication in Tests
import XCTest
@testable import MetaAgentSystem
class AgentCommunicationTests: XCTestCase {
    func testSendMessage() {
        let message = AgentMessage(sender: "agent1", receiver: "agent2", content: "Hello")
        let communicationModule = AgentCommunicationModule()
        XCTAssertTrue(communicationModule.sendMessage(message: message))
    }
}