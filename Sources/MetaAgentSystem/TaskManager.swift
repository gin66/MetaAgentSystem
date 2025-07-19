// Task management system
class TaskManager {
    private var tasks: [String: Bool] = [:]
    func assignTask(_ taskId: String) {
        tasks[taskId] = false
    }
    func completeTask(_ taskId: String) {
        tasks[taskId] = true
    }
    func monitorTasks() -> [String: Bool] {
        return tasks
    }
}
