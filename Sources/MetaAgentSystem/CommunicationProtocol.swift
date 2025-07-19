// Communication protocol between agents
protocol AgentCommunication {
    func sendMessage(_ message: String, to agentId: String)
    func receiveMessage() -> String?
}
