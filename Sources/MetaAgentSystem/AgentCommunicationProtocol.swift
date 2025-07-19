// Implementation of basic agent communication protocol
import Foundation
protocol AgentCommunicationProtocol {
    func send(message: String) throws -> Bool
    func receive() throws -> String?
}
class SimpleAgentCommunication: AgentCommunicationProtocol {
    private var messages: [String] = []
    func send(message: String) throws -> Bool {
        messages.append(message)
        return true
    }
    func receive() throws -> String? {
        guard !messages.isEmpty else { return nil }
        return messages.removeFirst()
    }
}