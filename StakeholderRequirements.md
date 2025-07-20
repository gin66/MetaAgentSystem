<!--
This file is intended to be read by the AI agents and not parsed by the agentic system.
-->
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
The system shall adhere to a rigorous, documentation-driven automated workflow for applying changes, ensuring that each step is small, verifiable, and atomically committed.

1.  **Sprint Planning**: Each sprint's goals shall be broken down into a series of tiny, verifiable implementation steps.
2.  **Iteration per Step**: The system will iterate through each tiny step one at a time. The workflow for a single step is as follows:
    a. **Verify Clean State**: Check if the `git` working tree is clean.
    b. **Update/Create Design Documentation**: Before any code is written, a dedicated agent must produce design documentation for the current implementation step. This includes specifying interactions, flows, classes, structs, APIs, and protocols.
    c. **Verify Design**: A verifier agent must check that the proposed design is logical, sound, and correctly addresses the implementation step. The design must be approved before proceeding.
    d. **Implement Code**: The coding agent will write or modify Swift code and corresponding tests based *only* on the verified design documentation.
    e. **Verify Implementation**: The verifier agent must check that the generated code is a sensible and correct implementation of the approved design.
    f. **Build and Test**: The system will execute `swift build` and `swift test` to validate the changes.
    g. **Atomic Commit**: If verification, build, and tests all pass, the changes to both the design documentation and the source code will be committed to git together in a single, atomic commit.
3.  **Retry on Failure**: If any verification, build, or test step fails, the system will loop back to the appropriate preceding step (e.g., a design verification failure returns to the design step). This loop can be repeated for a maximum of five attempts per implementation step.
4.  **Handle Persistent Failure**: If a step fails after five attempts, all changes for that step are discarded by executing `git checkout -- .`, and the entire process is terminated to await manual intervention.