// Sources/Models/AgentMessage.swift
import Foundation

protocol AgentMessage {
    var id: UUID { get }
    var timestamp: Date { get }
    var senderId: String { get }
    var recipientId: String? { get set }
}

extension AgentMessage where Self: Encodable, Self: Decodable {
    func encode() -> Data {
        return try! JSONEncoder().encode(self)
    }

    static func decode(data: Data) -> Self? {
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}