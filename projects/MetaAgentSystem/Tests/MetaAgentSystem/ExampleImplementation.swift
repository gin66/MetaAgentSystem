#if canImport(MetaAgentSystem)
import MetaAgentSystem
import XCTest

struct ExampleMessage: AgentMessage {
    var id: String
    var content: String
    var timestamp: Date
}
#endif