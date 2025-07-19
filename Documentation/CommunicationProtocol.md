# Agent Communication Protocol
This document outlines the communication protocol between agents in the Meta Agentic AI System.

## Overview
Agents can send and receive messages using a predefined protocol.

## Usage
### Sending Messages
```swift
agent1.sendMessage(to: "agent2", message: "Hello, World!")
```

### Receiving Messages
```swift
let message = agent2.receiveMessage(from: "agent1")
```