import Foundation
public struct Agent {
    let id: UUID
    let name: String
    var interactions: [Interaction] = []
}
public struct Interaction {
    let from: UUID
    let to: UUID
    let message: String
}