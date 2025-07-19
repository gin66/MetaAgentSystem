// Unit Tests for Bootstrap Script
import XCTest
class BootstrapTests: XCTestCase {
    func testBootstrapAgents() {
        let agents = bootstrapAgents()
        XCTAssertEqual(agents.count, 2)
    }
}