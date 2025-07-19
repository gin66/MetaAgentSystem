// Communication protocol for Meta Agentic AI System
protocol CommunicationProtocol {
    func sendMessage(_ message: String)
    func receiveMessage() -> String?
}