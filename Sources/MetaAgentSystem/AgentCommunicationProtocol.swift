// Agent Communication Protocol
import Foundation
protocol AgentCommunicationProtocol {
    func sendMessage(_ message: String, to agentID: Int)
    func receiveMessage(from agentID: Int) -> String?
}
