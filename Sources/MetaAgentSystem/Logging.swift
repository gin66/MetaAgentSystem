// Central logger for all agent activities
import Foundation
class Logger {
    static let shared = Logger()
    private init() {}
    func log(_ message: String) {
        print(message)
        // Implementation to capture logs centrally
    }
}
