import XCTest
@testable import MetaAgentSystem

class AgentCommunicationTests: XCTestCase {

    func testSendAndReceiveMessage() {
        let agent = Agent()
        agent.sendMessage("Hello", to: 1)
        XCTAssertEqual(agent.receiveMessage(), "Hello")
    }
}