// Unit tests for the basic agent architecture
import XCTest
@testable import MetaAgentSystem

class AgentTests: XCTestCase {
    func testPerformTask() {
        let agent = Agent()
        XCTAssertNotNil(agent)
    }
}