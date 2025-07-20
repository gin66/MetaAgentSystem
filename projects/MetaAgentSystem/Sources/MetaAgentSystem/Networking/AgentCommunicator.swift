// Sources/MetaAgentSystem/Networking/AgentCommunicator.swift
import Foundation

class AgentCommunicator {
    private var connectedAgents: Set<String> = []
    private var messages: [String: [Message]] = [:]

    init() {}

    func connect(agentId: String) {
        connectedAgents.insert(agentId)
        messages[agentId] = []
    }

    func disconnect(agentId: String) {
        connectedAgents.remove(agentId)
        messages.removeValue(forKey: agentId)
    }

    func sendMessage(to agentId: String, message: Message) {
        guard connectedAgents.contains(agentId) else { return }
        var agentMessages = messages[agentId] ?? []
        agentMessages.append(message)
        messages[agentId] = agentMessages
    }

    func receiveMessages() -> [String: [Message]] {
        return messages
    }

    // Reconnection Handling
    func reconnect(agentId: String) {
        disconnect(agentId: agentId)
        connect(agentId: agentId)
    }
}

struct Message {
    let sender: String
    let receiver: String
    let timestamp: Date
    let content: String
}