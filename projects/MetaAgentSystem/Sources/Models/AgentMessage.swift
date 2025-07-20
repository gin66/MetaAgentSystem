// Sources/Models/AgentMessage.swift
import Foundation

protocol AgentMessage {
    init(from: JSON)
    func toJSON() -> JSON
}

// Helper extension for initializing with JSON
public struct JSON: Codable {}
extension AgentMessage where Self: Decodable, Self: Encodable {
    init(from json: JSON) {
        guard let data = try? JSONEncoder().encode(json) else { fatalError() }
        self = try! JSONDecoder().decode(Self.self, from: data)
    }

    func toJSON() -> JSON {
        return try! JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: []) as? JSON ?? [:]
    }
}