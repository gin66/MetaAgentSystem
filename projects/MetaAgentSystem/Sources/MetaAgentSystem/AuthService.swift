// Service for user authentication
import Foundation
class AuthService {
    private var users = [UUID: User]()

    func register(username: String, email: String, password: String) throws -> User {
        guard !users.values.contains(where: { $0.username == username }) else {
            throw AuthError.userAlreadyExists
        }

        let userID = UUID()
        let passwordHash = hashPassword(password)
        let newUser = User(id: userID, username: username, email: email, passwordHash: passwordHash)
        users[userID] = newUser
        return newUser
    }

    func login(username: String, password: String) throws -> User {
        guard let user = users.values.first(where: { $0.username == username }) else {
            throw AuthError.invalidCredentials
        }

        if hashPassword(password) != user.passwordHash {
            throw AuthError.invalidCredentials
        }

        return user
    }

    private func hashPassword(_ password: String) -> String {
        // Simple hash function for demonstration purposes. Use a proper hashing library in production.
        return Data(password.utf8).map { String(format: "%02hhx", $0) }.joined()
    }

    enum AuthError: Error, LocalizedError {
        case userAlreadyExists
        case invalidCredentials

        var errorDescription: String? {
            switch self {
                case .userAlreadyExists:
                    return "User already exists."
                case .invalidCredentials:
                    return "Invalid credentials."
            }
        }
    }
}