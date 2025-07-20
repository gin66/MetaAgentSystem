# Design Document: Define `AgentMessage` Protocol in Models.swift
## Sprint Goal: Implement Basic Agent Communication Protocol
### Step: Define `AgentMessage` Protocol in `Models.swift`

## Classes, Structs, and Protocols
### `AgentMessage` Protocol
The `AgentMessage` protocol will define the structure of messages that agents use to communicate.
```swift
// Models.swift

import Foundation

protocol AgentMessage {
    var sender: String { get }
    var recipient: String { get }
    var timestamp: Date { get }
    var content: String { get }
}
```
## Interactions
- **Agent Classes**: Any class representing an agent should be able to create and send instances of `AgentMessage`.
- **Message Handling**: There will be a message handler or router that processes messages conforming to the `AgentMessage` protocol, ensuring it can handle various types of agents' communications.

## Example Usage
```swift
struct SimpleAgentMessage: AgentMessage {
    let sender: String
    let recipient: String
    let timestamp: Date
    let content: String
}

let message = SimpleAgentMessage(sender: "agent1", recipient: "agent2", timestamp: Date(), content: "Hello, Agent 2!")
```