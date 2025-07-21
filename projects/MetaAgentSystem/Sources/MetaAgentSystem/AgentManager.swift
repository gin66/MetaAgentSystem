// AgentManager class is responsible for creating and maintaining agents in the system.
class AgentManager {
    // Method to create a new agent with specified properties.
    func createAgent(id: String, role: String, performanceScore: Double) -> Agent {
        return Agent(id: id, role: role, performanceScore: performanceScore)
    }
}