<!--
This file is intended to be read by the AI agents and not parsed by the agentic system.
-->
# Stakeholder Requirements Document for Meta Agentic AI System

## 1. Purpose
Define requirements for a Meta Agentic AI System, to be developed in a dedicated `MetaAgentSystem` sub-folder, to manage agent-LLM pairings, optimize processes via feature prioritization and decomposition, and ensure continuous progress via performance evaluation, with agents running in isolated Swift containers.

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
5. **Requirements and Feature Management**:
   - Maintain a database of features/use cases for prioritization and processing.
   - Judge if a feature is clear enough for implementation.
   - Decompose unclear or non-atomic features along a hierarchical system design, with each element broken into a maximum of five sub-elements.
   - Break non-atomic features (requiring changes to more than one file) into groups for parallel implementation by independent agents.
   - Activate refactoring for features needing system architecture changes.
   - Require every feature/use case to include a Test Plan with strategy and performance criteria; feature incomplete without tests.
6. **Interface**:
   - Use Ollama API for LLM interactions with structured output mode.
   - All LLM responses must use structured JSON output as defined by API's structured output mode.

## 4. Non-Functional Requirements
1. **Programming Language**:
   - Implement in Swift for performance and safety.
   - Use Swift 6 and apply Swift concurrency using async and await.
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
- Features are prioritized, decomposed, and implemented parallelly where needed.
- Every feature passes its Test Plan; full regression tests pass after implementation.

## 8. Automated Workflow Strategy
The system shall adhere to a rigorous, documentation-driven automated workflow for applying changes, ensuring that each step is small, verifiable, and atomically committed. The AgilePlan is replaced by a database of features/use cases.

1. **Feature Management**: Maintain and prioritize a database of features/use cases.
2. **Processing per Feature**: Process prioritized features one at a time or in parallel groups.
    a. **Judge Clarity**: A clarity judge agent determines if the feature is clear and atomic (implementable by changing one file).
    b. **Decompose if Needed**: If unclear or non-atomic, a decomposition agent breaks it down along a hierarchical system design, into a maximum of five sub-elements per level, creating a group of sub-features.
    c. **Refactor if Needed**: If architecture changes are required, activate a refactor agent to update the system architecture.
    d. **Include Test Plan**: Every feature must define a Test Plan with strategy, execution steps, and criteria.
    e. **Implement**: For atomic features, follow the iteration workflow (verify clean state, update design, verify design, implement code, verify implementation, build/test including regression, atomic commit). For groups, implement sub-features parallelly using independent agents.
3. **Retry on Failure**: If any step fails, loop back to the preceding step (max five attempts per feature).
4. **Handle Persistent Failure**: If fails after five attempts, discard changes via `git checkout -- .` and terminate for manual intervention.
5. **Regression Testing**: After implementation, run all existing tests to prevent breaking prior features.

## 9. Roles
- Configuration Manager Agent
- Planner Agent
- DocWriter Agent
- CodeGen Agent
- Verifier Agent (for design and implementation)
- Refiner Agent
- ErrorAnalyzer Agent
- Requirements Manager Agent
- Prioritizer Agent
- Clarity Judge Agent
- Decomposition Agent
- Refactor Agent
- Judge Agents (for performance evaluation)

## 10. Directory Hierarchy
- **MetaAgentSystem/**: Root folder for the system.
  - **Sources/**: Swift source code files.
  - **Tests/**: Unit and integration test files.
  - **design/**: Design documents (e.g., SystemArchitecture.md).
  - **docs/**: Additional documentation like Vision.md, StakeholderRequirements.md.
  - **db/**: Feature/use case database (e.g., JSON or Swift data store).
  - **agents/**: Isolated Swift containers for agents.
