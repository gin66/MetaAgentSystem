// Implement container for agents
class AgentContainer {
    private var agents = [String: Agent]()
    func addAgent(_ agent: Agent, withId id: String) {
        agents[id] = agent
    }
    func getAgent(withId id: String) -> Agent? {
        return agents[id]
    }
}