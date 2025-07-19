// Define basic messaging protocol for agents
protocol AgentCommunicationProtocol {
    func sendMessage(to agent: String, message: String)
    func receiveMessage(from agent: String) -> String?
}