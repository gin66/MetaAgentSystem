import Foundation

protocol AgentCommunication {
    func sendMessage(_ message: String, to agentId: Int)
    func receiveMessage() -> String?
}