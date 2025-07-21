// TaskStore class manages in-memory storage for tasks.
struct Task {
    let id: String
    let description: String
}

class TaskStore {
    // Dictionary to store tasks by their ID
    private var tasks: [String: Task] = [:]
    
    // Method to add a task to the store
    func addTask(task: Task) {
        tasks[task.id] = task
    }
    
    // Method to retrieve a task from the store by its ID
    func getTask(byID id: String) -> Task? {
        return tasks[id]
    }
    
    // Method to remove a task from the store by its ID
    func removeTask(byID id: String) {
        tasks.removeValue(forKey: id)
    }
}