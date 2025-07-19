// Unit tests for agent communication
import XCTest
@testable import MetaAgentSystem
class AgentCommunicationProtocolTests: XCTestCase {
    func testSendReceive() {
        let agent = SimpleAgentCommunication()
        XCTAssertNoThrow(try agent.send(message: "Hello, World!"))
        let receivedMessage = try? agent.receive()
        XCTAssertEqual(receivedMessage, "Hello, World!")
    }
}