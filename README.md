# Meta Agentic AI System

## Overview
This project involves developing a Meta Agentic AI system using Swift and Ollama. The system is designed to be self-improving, optimizing agent and LLM performance through adaptive process design and rigorous performance evaluation.

The project is structured to ensure that all development and operations are contained within the `projects/MetaAgentSystem` directory. This includes all source code, tests, documentation, and operational scripts.

## Vision
The vision is to create a dynamic, self-improving meta agentic AI system that optimizes agent and LLM performance, ensuring continuous progress and breakthrough results through adaptive process design and rigorous performance evaluation.

## Stakeholder Requirements
The system will manage agent-LLM pairings, optimize processes, and ensure continuous progress via performance evaluation, with agents running in isolated Swift containers. All operations and file modifications are restricted to the `projects/MetaAgentSystem` directory.

## Agile Plan
The project will follow an agile implementation plan with fast sprints. Each sprint will deliver a testable deliverable. All work, including code, tests, and documentation, is managed within the `projects/MetaAgentSystem` directory.

## How it Works
The system uses a `bootstrap.swift` script to automate the development process. This script operates exclusively within the `projects/MetaAgentSystem` directory and performs the following steps:
1.  **Verifies a clean git state.** Before starting, it ensures that there are no uncommitted changes.
2.  **Reads the current sprint plan.** It reads the `NextSteps.json` file to determine the tasks for the current sprint.
3.  **Generates code.** An AI agent generates Swift code and unit tests based on the sprint plan.
4.  **Builds and tests.** The script compiles the code and runs the unit tests.
5.  **Commits the changes.** If the build and tests are successful, the script commits the changes with a descriptive message.
6.  **Plans the next sprint.** An AI agent updates `NextSteps.json` with the plan for the next sprint.

This entire process is confined to the `projects/MetaAgentSystem` directory, ensuring that no other part of the file system is affected.
