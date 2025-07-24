// swift-tools-version:6.0
import Foundation

enum Status: String {
    case active, inactive, deleted
}

struct AgentProfile {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let status: Status
    var createdAt: Date
    var updatedAt: Date
}