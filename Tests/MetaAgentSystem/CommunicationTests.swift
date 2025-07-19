// Tests for the Communication Protocol
import XCTest
@testable import MetaAgentSystem
class CommunicationProtocolTests: XCTestCase {
    var agent1: MockAgent!
    var agent2: MockAgent!
    override func setUp() {
        super.setUp()
        agent1 = MockAgent()
        agent2 = MockAgent()
    }
    func testCommunication() {
        agent1.send(message: "Hello")
        XCTAssertEqual(agent2.receive(), "Hello")
    }
}