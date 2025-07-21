// AgentStore class manages in-memory storage for agents.
class AgentStore {
    // Dictionary to store agents by their ID
    private var agents: [String: Agent] = [:]
     
    // Method to add an agent to the store
    func addAgent(agent: Agent) {
        agents[agent.id] = agent
    }
     
    // Method to retrieve an agent from the store by its ID
    func getAgent(byID id: String) -> Agent? {
        return agents[id]
    }
     
    // Method to remove an agent from the store by its ID
    func removeAgent(byID id: String) {
        agents.removeValue(forKey: id)
    }
}