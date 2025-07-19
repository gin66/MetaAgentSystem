// Basic communication protocol between agents
import Foundation
protocol AgentCommunicationProtocol {
	func sendMessage(_ message: String, toAgent agentId: String) -> Bool
	func receiveMessage() -> String?
}