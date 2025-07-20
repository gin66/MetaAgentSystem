// Define AgentMessage protocol
import Foundation
protocol AgentMessage {
    var id: String { get }
    var content: String { get }
    var timestamp: Date { get }
}