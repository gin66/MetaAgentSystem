// Unit tests for AuthService
import XCTest
@testable import MetaAgentSystem
class AuthServiceTests: XCTestCase {
    var authService: AuthService!

    override func setUp() {
        super.setUp()
        authService = AuthService()
    }

    func testUserRegistration() {
        do {
            let user = try authService.register(username: "testuser", email: "test@example.com", password: "password123")
            XCTAssertEqual(user.username, "testuser")
            XCTAssertEqual(user.email, "test@example.com")
        } catch {
            XCTFail("Expected successful registration: \(error)")
        }
    }

    func testUserLogin() {
        do {
            let _ = try authService.register(username: "testuser", email: "test@example.com", password: "password123")
            let user = try authService.login(username: "testuser", password: "password123")
            XCTAssertEqual(user.username, "testuser")
        } catch {
            XCTFail("Expected successful login: \(error)")
        }
    }

    func testUserAlreadyExists() {
        do {
            let _ = try authService.register(username: "testuser", email: "test@example.com", password: "password123")
            XCTAssertThrowsError(try authService.register(username: "testuser", email: "test@example.com", password: "password123")) {
                error in
                XCTAssertEqual(error as? AuthService.AuthError, AuthService.AuthError.userAlreadyExists)
            }
        } catch {
            XCTFail("Expected successful first registration: \(error)")
        }
    }

    func testInvalidCredentials() {
        do {
            let _ = try authService.register(username: "testuser", email: "test@example.com", password: "password123")
            XCTAssertThrowsError(try authService.login(username: "testuser", password: "wrongPassword")) {
                error in
                XCTAssertEqual(error as? AuthService.AuthError, AuthService.AuthError.invalidCredentials)
            }
        } catch {
            XCTFail("Expected successful first registration: \(error)")
        }
    }
}