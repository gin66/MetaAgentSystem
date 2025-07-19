// Define the communication protocol for agents
protocol CommunicationProtocol {
    func send(message: String)
    func receive() -> String?
}