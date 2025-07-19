// Agent registration and discovery service
import Foundation
public class AgentRegistrar {
	private var registeredAgents = [String]()
	public func registerAgent(_ agentId: String) {
		registeredAgents.append(agentId)
	}
	public func getRegisteredAgents() -> [String] {
		return registeredAgents
	}
}