// Document agent communication protocol
# Agent Communication Protocol
## Message Format
- `sender`: String - The sending agent's identifier.
- `receiver`: String - The receiving agent's identifier.
- `content`: String - The message content.

## Communication Module
### sendMessage(message: AgentMessage) -> Bool
Sends a message to the specified receiver.