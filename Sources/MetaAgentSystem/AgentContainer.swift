// Agent container implementation
import Foundation
public class AgentContainer {
	private var agents = [String: Agent]()
	public func addAgent(_ agent: Agent, withId id: String) {
		agents[id] = agent
	}
	public func getAgent(withId id: String) -> Agent? {
		return agents[id]
	}
	public func removeAgent(withId id: String) {
		agents.removeValue(forKey: id)
	}
}