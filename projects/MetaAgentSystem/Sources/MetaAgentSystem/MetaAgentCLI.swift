// CLI command to create a new agent.
import Foundation
struct MetaAgentCLI {
    static let agentManager = AgentManager()
    @MainActor
    static func main(args: [String]) async {
        guard args.count > 3 else { print("Usage: create-agent --id=<ID> --role=<ROLE> --performanceScore=<SCORE>"); return }
        var id: String? = nil
        var role: String? = nil
        var performanceScore: Double? = nil
        for (index, element) in args.enumerated() {
            switch element {
                case "--id":
                    if index + 1 < args.count { id = args[index + 1] }
                case "--role":
                    if index + 1 < args.count { role = args[index + 1] }
                case "--performanceScore":
                    if index + 1 < args.count {
                        performanceScore = Double(args[index + 1])
                    }
                default:
                    break
            }
        }
        if let id = id, let role = role, let score = performanceScore {
            let newAgent = await agentManager.createAgent(id: id, role: role, performanceScore: score)
            print("Created Agent: \nID: \(newAgent.id)\nRole: \(newAgent.role)\nPerformance Score: \(newAgent.performanceScore)")
        } else {
            print("Usage: create-agent --id=<ID> --role=<ROLE> --performanceScore=<SCORE>");
        }
    }
}