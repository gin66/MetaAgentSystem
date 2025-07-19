// Agent Implementation
import Foundation
class Agent: AgentCommunicationProtocol {
    private var messages = [Int:String]()
    func sendMessage(_ message: String, to agentID: Int) {
        messages[agentID] = message
    }
    func receiveMessage(from agentID: Int) -> String? {
        return messages[agentID]
    }
}
