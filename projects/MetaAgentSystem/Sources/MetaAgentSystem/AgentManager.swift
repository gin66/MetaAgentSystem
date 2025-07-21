// AgentManager class to manage creation and maintenance of agents.
@MainActor
class AgentManager {
    func createAgent(id: String, role: String, performanceScore: Double) -> Agent {
        return Agent(id: id, role: role, performanceScore: performanceScore)
    }
}