# Stakeholder Requirements Document for Meta Agentic AI System

## 1. Purpose
Define requirements for a Meta Agentic AI System, to be developed in a dedicated `MetaAgentSystem` sub-folder, to manage agent-LLM pairings, optimize processes, and ensure continuous progress via performance evaluation, with agents running in isolated Swift containers.

## 2. Stakeholders
- **System Developers**: Need robust, maintainable code and clear documentation.
- **End Users**: Expect efficient task execution and reliable outcomes.
- **Administrators**: Require tools to monitor and adjust agent performance and system processes.

## 3. Functional Requirements
1. **Agent Management**:
   - Dynamically assign and manage agent-LLM pairings for tasks.
   - Support creation, deletion, and updating of agent profiles with unique IDs and roles.
   - Run each agent in an isolated Swift container.
2. **Task Management**:
   - Allow task creation, assignment, and tracking with statuses (e.g., pending, completed).
   - Assign tasks based on agent performance metrics.
3. **Performance Evaluation**:
   - Include judge agents to evaluate task performance, running in isolated Swift containers.
   - Judges provide structured JSON output with score (0-1) and feedback using LLM structured output mode.
   - Prioritize high-performing judges for assignments.
4. **Process Optimization**:
   - Optimize agent-task assignments for maximum efficiency.
   - Prevent endless loops of rework or over-optimization.
5. **Interface**:
   - Use Ollama API for LLM interactions with structured output mode.
   - All LLM responses must use structured JSON output as defined by API's structured output mode.

## 4. Non-Functional Requirements
1. **Programming Language**:
   - Implement in Swift for performance and safety.
2. **Containerization**:
   - Run individual agents and judge agents in isolated Swift containers for process isolation.
3. **Scalability**:
   - Handle increasing agents, tasks, and evaluations without performance degradation.
4. **Reliability**:
   - Ensure consistent progress and avoid infinite loops.
5. **Security**:
   - Securely handle sensitive data.
6. **Maintainability**:
   - Code must be modular, well-documented, and adhere to Swift best practices.

## 5. Constraints
- Integrate with Ollama API for all LLM interactions using structured output mode.
- Structured output in JSON format as defined by API's structured output mode.
- Avoid external file I/O or network calls beyond Ollama API.

## 6. Assumptions
- Ollama API with structured output mode is available and reliable.
- Sufficient computational resources for Swift-based execution and agent containerization.
- Stakeholders understand basic AI system management.

## 7. Acceptance Criteria
- System assigns agents to tasks and optimizes based on performance metrics.
- Judge agents produce structured JSON output with valid scores and feedback using LLM structured output mode.
- System demonstrates progress without infinite loops in test scenarios.
- Code compiles and runs without errors, with agents in Swift containers.
- Agent interactions with Ollama API are secure and efficient.

## 8. Automated Workflow Strategy
The system shall adhere to the following automated workflow for applying changes:
1. **Verify Clean State**: Check if the `git` working tree is clean (no uncommitted changes).
2. **Apply Changes**: Perform the requested code modification or task.
3. **Build and Test**: Execute the `swift build` and `swift test` commands to validate the changes.
4. **Retry on Failure**: If the build or tests fail, loop back to step 2 to attempt a fix. This loop can be repeated for a maximum of five attempts.
5. **Handle Persistent Failure**: If the build or tests still fail after five attempts, discard all changes by executing a `git checkout -- .` and terminate the process.
6. **Commit on Success**: If the build and tests pass, commit the changes to the repository with a clear and descriptive commit message.
