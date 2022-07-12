@testable import SwiftLintFramework
import SwiftSyntax
#if canImport(SwiftSyntaxParser)
import SwiftSyntaxParser
#endif
import XCTest

final class ClassMatcherTests: XCTestCase {
    func testClassFindsAll() {
        @SyntaxVisitorRuleValidatorBuilder
        var validator: SyntaxVisitorRuleValidator {
            Class()
        }

        XCTAssertEqual(validator.visitors.count, 1)

        guard let visitor = validator.visitors.first else {
            XCTFail("validator does not have a visitor")
            return
        }

        XCTAssertTrue(visitor is DeclVisitor)
        XCTAssertNoThrow(try {
            let source = """
                class A {}
                struct B {}
                struct C {}
            """
            let parsed = try SyntaxParser.parse(source: source)
            let positions = validator.collectViolations(parsed)
            XCTAssertEqual(positions.count, 1)
        }())
    }

    func testDuplicateLintModifiersUsesLastOne() {
        @SyntaxVisitorRuleValidatorBuilder
        var validator: SyntaxVisitorRuleValidator {
            Class()
                .inheritsFrom(["Foo"])
                .inheritsFrom(["Bar"])
        }

        XCTAssertEqual(validator.visitors.count, 1)

        guard let visitor = validator.visitors.first else {
            XCTFail("validator does not have a visitor")
            return
        }

        XCTAssertTrue(visitor is DeclVisitor)
        XCTAssertNoThrow(try {
            let source = """
                class A: Foo {}
                class B: Foo {}
                class C: Bar {}
            """
            let parsed = try SyntaxParser.parse(source: source)
            let positions = validator.collectViolations(parsed)
            XCTAssertEqual(positions.count, 1)
        }())
    }
}
