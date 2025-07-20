// Models.swift
import Foundation
protocol AgentMessage {
    var sender: String { get }
    var recipient: String { get }
    var timestamp: Date { get }
    var content: String { get }
}
struct SimpleAgentMessage: AgentMessage {
    let sender: String
    let recipient: String
    let timestamp: Date
    let content: String
}
