import Foundation

protocol AgentMessage {
    var id: UUID { get }
    var from: String { get }
    var to: String { get }
    var timestamp: Date { get }
    var content: [String: Any] { get }
}

struct TextMessage: AgentMessage {
    var id: UUID = UUID()
    var from: String
    var to: String
    var timestamp: Date = Date()
    var content: [String : Any]
}