// Define communication protocols for agents
protocol AgentCommunicationProtocol {
    func send(message: String)
    func receive() -> String?
}