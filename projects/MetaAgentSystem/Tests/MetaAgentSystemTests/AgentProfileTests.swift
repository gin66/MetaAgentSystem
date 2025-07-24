// swift-tools-version:6.0
import XCTest
@testable import MetaAgentSystem

class AgentProfileTests: XCTestCase {
    func testInitialization() {
        let profile = AgentProfile(
            id: UUID(),
            name: "John Doe",
            email: "john.doe@example.com",
            phone: "123-456-7890",
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        XCTAssertEqual(profile.name, "John Doe")
        XCTAssertEqual(profile.email, "john.doe@example.com")
        XCTAssertEqual(profile.phone, "123-456-7890")
        XCTAssertEqual(profile.status.rawValue, "active")
    }
}