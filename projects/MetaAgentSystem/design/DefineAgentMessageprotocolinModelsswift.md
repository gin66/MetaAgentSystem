# Define Agent Message Protocol in Models.swift

## Overview
This document outlines the design for implementing a basic agent communication protocol by defining an `AgentMessage` protocol.

## Components
### Protocols
- **AgentMessage**: A protocol that defines the structure and requirements of messages exchanged between agents.

## Implementations
### Models.swift
```swift
// Define AgentMessage protocol
protocol AgentMessage {
    var id: String { get }
    var content: String { get }
    var timestamp: Date { get }
}
```

## Usage
- All agent messages must conform to the `AgentMessage` protocol.
- Ensure that all properties (`id`, `content`, and `timestamp`) are implemented in message structures.

## Interactions
### Example Implementation
```swift
struct ExampleMessage: AgentMessage {
    var id: String
    var content: String
    var timestamp: Date
}
```
