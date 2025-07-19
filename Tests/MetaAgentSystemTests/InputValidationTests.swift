// Unit Tests for Input Validation
import XCTest
@testable import MetaAgentSystem
class InputValidationTests: XCTestCase {
    func testValidate() {
        let validation = InputValidation()
        XCTAssertTrue(validation.validate(input: "safe input"))
        XCTAssertFalse(validation.validate(input: "unsafe input"))
    }
}