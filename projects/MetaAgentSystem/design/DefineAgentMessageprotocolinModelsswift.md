# Design Document
## Sprint Goal: Implement Basic Agent Communication Protocol
### Step: Define `AgentMessage` protocol in Models.swift

#### Classes:
- **AgentMessage**
  - **Description:** A protocol defining the basic structure for messages exchanged between agents.

#### Structs:
- None

#### Functions:
- None

#### Protocols:
- **AgentMessage**
  - **Methods:**
    - `init(from: JSON)` -> Self (Required)
      - **Description:** Initializes a new instance of the protocol with data from a JSON object.
    - `toJSON()` -> JSON (Required)
      - **Description:** Converts the message to a JSON representation.

#### Interactions:
- None specified
