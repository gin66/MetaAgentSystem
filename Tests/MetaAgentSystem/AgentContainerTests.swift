import XCTest
@testable import MetaAgentSystem

class AgentContainerTests: XCTestCase {

    func testInitialization() {
        let agent = AgentContainer(identifier: "TestAgent")
        XCTAssertEqual(agent.identifier, "TestAgent")
    }

    func testStartAndTerminate() {
        var agent = AgentContainer(identifier: "TestAgent")
        XCTAssertNil(agent.process?.isRunning)

        do {
            try agent.start()
            // Add assertions for start process
        } catch {
            XCTFail("Failed to start the agent.")
        }
        agent.terminate()
    }
}