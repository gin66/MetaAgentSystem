# Meta Agentic AI System

## Overview
A Meta Agentic AI System built in Rust, leveraging OpenAI API with structured JSON output, and supporting Ollama as a fallback for local LLM deployment. It dynamically manages agent-LLM pairings, optimizes task assignments, and evaluates performance using judge agents, ensuring continuous progress without infinite loops. Bootstrapped with Grok 4 and Gemini for rapid development.

## Features
- **Dynamic Agent Management**: Assigns and optimizes agent-LLM pairings for tasks.
- **Performance Evaluation**: Judge agents evaluate tasks with structured JSON output (score 0-1, feedback).
- **Loop Prevention**: Avoids "spinning the wheels" with cycle detection and progress tracking.
- **Scalability**: Thread-safe design using Rust’s mutex for concurrent operations.
- **LLM Integration**: Uses OpenAI API primarily, with Ollama as a fallback for local execution.

## Tech Stack
- **Language**: Rust
- **Dependencies**: `openai-api`, `serde`, `tokio`, `uuid`
- **APIs**: OpenAI API (structured JSON output), Ollama (fallback)
- **Bootstrapping Tools**: Grok 4, Gemini

## Installation
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/MetaAgentSystem.git
   cd MetaAgentSystem
   ```
2. **Install Rust**:
   Follow [Rust installation guide](https://www.rust-lang.org/tools/install).
3. **Install Ollama (Optional)**:
   Follow [Ollama installation guide](https://ollama.ai/download) for local LLM fallback.
4. **Build and Run**:
   ```bash
   cargo build
   cargo run
   ```

## Development Plan
Adopting an agile approach with fast, testable sprints. See [AgilePlan.md](./AgilePlan.md) for details.

## License
MIT License. See [LICENSE](LICENSE) for details.