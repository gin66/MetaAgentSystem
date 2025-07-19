// Unit tests for inter-agent communication
import XCTest
export MetaAgentSystem
class CommunicationTests: XCTestCase {
    func testSendData() {
        let comm = Communication()
        let json = JSON([