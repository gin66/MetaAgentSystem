```markdown
# Design Document for In-Memory Storage System for Agents and Tasks

## Overview
This document outlines the design for an in-memory storage system to manage `Agent` and `Task` structures within the Meta Agent System. The aim is to provide a simple, efficient way to store and retrieve agents and tasks without persistent storage.

## Components
### Classes
#### `AgentManager`
- **Responsibility**: Manages creation and maintenance of `Agent` instances.
- **Methods**
  - `createAgent(id:role:performanceScore:) -> Agent`
    - Creates a new agent with the specified properties.

### Structs
#### `Agent`
- **Properties**
  - `id: String` (Identifier for the agent)
  - `role: String` (Role of the agent within the system)
  - `performanceScore: Double` (Performance score of the agent)

## In-Memory Storage System Design
### `AgentStore` Class
The `AgentStore` class will manage in-memory storage for agents.
- **Properties**
  - `agents: [String: Agent]` (Dictionary to store agents by their ID)
- **Methods**
  - `addAgent(agent: Agent)`
    - Adds an agent to the store.
  - `getAgent(byID id: String) -> Agent?`
    - Retrieves an agent from the store by its ID.
  - `removeAgent(byID id: String)`
    - Removes an agent from the store by its ID.

### `TaskStore` Class
The `TaskStore` class will manage in-memory storage for tasks.
- **Properties**
  - `tasks: [String: Task]` (Dictionary to store tasks by their ID)
- **Methods**
  - `addTask(task: Task)`
    - Adds a task to the store.
  - `getTask(byID id: String) -> Task?`
    - Retrieves a task from the store by its ID.
  - `removeTask(byID id: String)`
    - Removes a task from the store by its ID.

## Example Usage
```swift
let agentStore = AgentStore()
let taskStore = TaskStore()
let agentManager = AgentManager()

// Create and add an agent to the store
let newAgent = agentManager.createAgent(id: "1", role: "Analyst", performanceScore: 95.0)
agentStore.addAgent(agent: newAgent)
```

## Conclusion
This design provides a clear path for implementing an in-memory storage system to manage agents and tasks within the Meta Agent System, ensuring efficient creation, retrieval, and management of these entities.
```