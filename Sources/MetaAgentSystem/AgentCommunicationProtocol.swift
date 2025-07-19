//
// AgentCommunicationProtocol.swift
// Definition of the communication protocol between agents.
//
import Foundation

protocol AgentCommunicationProtocol {
    func sendMessage(to agent: String, message: Data) throws -> Void
    func receiveMessage(from agent: String) throws -> Data?
}
