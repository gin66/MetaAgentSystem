import Foundation

struct AgentContainer {
    var identifier: String
    var process: Process?

    init(identifier: String) {
        self.identifier = identifier
        setupProcess()
    }

    private mutating func setupProcess() {
        let process = Process()
        // Configure process for agent
        self.process = process
    }

    func start() throws {
        guard let process = process else { return } 
        try process.launch()
    }

    func terminate() {
        process?.terminate()
    }
}