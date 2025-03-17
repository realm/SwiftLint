@testable import SwiftLintFramework
import XCTest

final class NonFinalClassRuleTests: XCTestCase {
    func testNonTriggeringExamples() {
        let examples = [
            "final class MyClass {}",
            "open class MyClass {}",
            "public final class MyClass {}",
        ]
        examples.forEach { example in
            verifyRule(NonFinalClassRule.description, string: example, expected: [])
        }
    }

    func testTriggeringExamples() {
        let examples = [
            "class MyClass {}",
            "public class MyClass {}",
        ]
        examples.forEach { example in
            let violations = violationsForRule(NonFinalClassRule.description, string: example)
            XCTAssertEqual(violations.count, 1, "Expected one violation in: \(example)")
            XCTAssertEqual(violations.first?.reason,
                "Classes should be marked as `final` unless they are explicitly `open`")
        }
    }

    func testCorrections() {
        assertCorrection(NonFinalClassRule.description,
                         input: "class MyClass {}",
                         expected: "final class MyClass {}")
        assertCorrection(NonFinalClassRule.description,
                         input: "public class MyClass {}",
                         expected: "public final class MyClass {}")
    }
}
