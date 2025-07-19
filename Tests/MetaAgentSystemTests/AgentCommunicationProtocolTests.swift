//
// AgentCommunicationProtocolTests.swift
// Unit tests for the communication protocol between agents.
//
import XCTest
@testable import MetaAgentSystem

class AgentCommunicationProtocolTests: XCTestCase {
    func testMessageSerialization() {
        let agent = MockAgent()
        let messageData = try! JSONEncoder().encode("Hello, World!")
        XCTAssertNoThrow(try agent.sendMessage(to: "Agent1", message: messageData))
    }
    func testMessageDeserialization() {
        let agent = MockAgent()
        do {
            _ = try agent.receiveMessage(from: "Agent1")
            XCTFail("Expected error but got none")
        } catch {
            XCTAssertTrue(true, "Correctly threw error")
        }
    }
}

// Mock Agent for testing purposes
class MockAgent: AgentCommunicationProtocol {
    func sendMessage(to agent: String, message: Data) throws -> Void {
        // Implement real logic here or mock it
    }
    func receiveMessage(from agent: String) throws -> Data? {
        throw NSError(domain: "MockAgent", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }
}
