// Unit tests for DataCollectorAgent
import XCTest
test class DataCollectorAgentTests: XCTestCase {
    func testCollectData() {
        let agent = DataCollectorAgent()
        XCTAssertEqual(agent.collectData(), "Collected data")
    }
}
