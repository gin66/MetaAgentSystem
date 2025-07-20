// Tests/MetaAgentSystem/Networking/AgentCommunicatorTests.swift
import XCTest
@testable import MetaAgentSystem

class AgentCommunicatorTests: XCTestCase {
    var agentURL: URL!
    var communicator: AgentCommunicator!

    override func setUp() {
        super.setUp()
        agentURL = URL(string: "https://example.com/api/agent")!
        communicator = AgentCommunicator(url: agentURL)
    }

    func testSendMessageSuccess() {
        let expectation = self.expectation(description: "testSendMessageSuccess")

        communicator.sendMessage(message: "Hello, World!") { result in
            switch result {
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSendMessageFailure() {
        let expectation = self.expectation(description: "testSendMessageFailure")

        communicator.sendMessage(message: "Hello, World!") { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}