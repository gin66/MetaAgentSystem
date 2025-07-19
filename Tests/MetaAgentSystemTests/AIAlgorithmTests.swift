// Unit Tests for Basic AI Algorithms
import XCTest
@testable import MetaAgentSystem
class AIAlgorithmTests: XCTestCase {
    func testBasicAlgorithm() {
        let agent = MetaAgent()
        XCTAssertEqual(agent.basicAlgorithm(), "Basic AI algorithm functioning")
    }
}
