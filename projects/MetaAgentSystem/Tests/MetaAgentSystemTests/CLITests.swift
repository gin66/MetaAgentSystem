// Unit tests for CLI command to create a new agent.
import XCTest
@testable import MetaAgentSystem
class CLITests: XCTestCase {
    func testCreateAgentCommand() async throws {
        let arguments = ["create-agent", "--id=agent_003", "--role=user", "--performanceScore=0.85"]
        await MetaAgentCLI.main(args: Array(arguments.dropFirst()))
        // Additional verifications like checking console output
    }
}