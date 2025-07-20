import Foundation

enum CodingKeys: String, CodingKey {
    case data
}
public struct JSON: Codable {
    let data: [String: Any]
}
extension JSON {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([String: Any].self, forKey: .data)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
    }
}
protocol AgentMessage: Decodable, Encodable {
    init(from json: JSON) throws
    func toJSON() throws -> JSON
}
extension AgentMessage where Self: Decodable, Self: Encodable {
    init(from json: JSON) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: JSONEncoder().encode(json))
    }

    func toJSON() throws -> JSON {
        return JSON(data: (try JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: []) as? [String: Any]) ?? [:])
    }
}