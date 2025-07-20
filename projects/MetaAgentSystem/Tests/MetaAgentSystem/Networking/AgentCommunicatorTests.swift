// Tests/MetaAgentSystem/Networking/AgentCommunicatorTests.swift
import XCTest
@testable import MetaAgentSystem

class AgentCommunicatorTests: XCTestCase {
    var agentCommunicator: AgentCommunicator!

    override func setUp() {
        super.setUp()
        agentCommunicator = AgentCommunicator()
    }

    override func tearDown() {
        agentCommunicator = nil
        super.tearDown()
    }

    func testConnect() {
        agentCommunicator.connect(agentId: "Agent1")
        XCTAssertTrue(agentCommunicator.connectedAgents.contains("Agent1"))
    }

    func testDisconnect() {
        agentCommunicator.connect(agentId: "Agent2")
        agentCommunicator.disconnect(agentId: "Agent2")
        XCTAssertFalse(agentCommunicator.connectedAgents.contains("Agent2"))
    }

    func testSendAndReceiveMessage() {
        let sender = Message(sender: "Agent1", receiver: "Agent3", timestamp: Date(), content: "Hello, Agent3!")
        agentCommunicator.connect(agentId: "Agent3")
        agentCommunicator.sendMessage(to: "Agent3", message: sender)

        let receivedMessages = agentCommunicator.receiveMessages()["Agent3"]
        XCTAssertEqual(receivedMessages?.count, 1)
        XCTAssertEqual(receivedMessages?[0].content, "Hello, Agent3!")
    }

    func testReconnect() {
        let agentId = "Agent4"
        agentCommunicator.connect(agentId: agentId)
        agentCommunicator.disconnect(agentId: agentId)
        agentCommunicator.reconnect(agentId: agentId)
        XCTAssertTrue(agentCommunicator.connectedAgents.contains(agentId))
    }
}