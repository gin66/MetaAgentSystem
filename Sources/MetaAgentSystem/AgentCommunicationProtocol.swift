// Define the protocol for agent communication
protocol AgentCommunicationProtocol {
    func sendMessage(_ message: String)
    func receiveMessage() -> String?
}
