# Meta Agentic AI System

## Overview
A Meta Agentic AI System built in Swift, leveraging Ollama with structured output mode, with individual agents running in isolated Swift containers. It dynamically manages agent-LLM pairings, optimizes task assignments, and evaluates performance using judge agents, ensuring continuous progress without infinite loops. Bootstrapped with Grok 4 for rapid development.

## Features
- **Dynamic Agent Management**: Assigns and optimizes agent-LLM pairings for tasks.
- **Performance Evaluation**: Judge agents evaluate tasks with structured JSON output (score 0-1, feedback) using LLM structured output mode.
- **Loop Prevention**: Avoids "spinning the wheels" with cycle detection and progress tracking.
- **Scalability**: Thread-safe design using Swift concurrency for concurrent operations.
- **LLM Integration**: Uses Ollama with structured output mode.
- **Containerization**: Runs individual agents in isolated Swift containers.

## Tech Stack
- **Language**: Swift
- **Containerization**: Swift containers for individual agents
- **Dependencies**: `OpenAPIKit`, `SwiftNIO`, `UUID`
- **APIs**: Ollama (structured output mode)
- **Bootstrapping Tools**: Grok 4

## Installation
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/MetaAgentSystem.git
   cd MetaAgentSystem
   ```
2. **Install Swift**:
   Follow [Swift installation guide](https://swift.org/download/).
3. **Install Ollama**:
   Follow [Ollama installation guide](https://ollama.ai/download) for local LLM execution.
4. **Build and Run**:
   ```bash
   swift package init
   swift build
   swift run
   ```

## Development Plan
Adopting an agile approach with fast, testable sprints. See [AgilePlan.md](./AgilePlan.md) for details.

## License
MIT License. See [LICENSE](LICENSE) for details.