// swiftlint:disable unused_import

@testable import SwiftLintFramework
import SwiftSyntax
#if canImport(SwiftSyntaxParser)
import SwiftSyntaxParser
#endif
import XCTest

final class AsExprVisitorTests: XCTestCase {
    func testOptionalAsExpressions() {
        let source = """
            let x = y as? Int
            let a = b as Int
            let foo = bar as Int
        """
        let attributes = AsExprVisitor.Attributes(form: .optional)
        let visitor = AsExprVisitor(attributes: attributes)

        assertVisitorRaisesViolations(
            on: source,
            visitor: visitor,
            expectedViolations: 1
        )
    }

    func testForcedAsExpressions() {
        let source = """
            let x = y as? Int
            let a = b as! Int
            let foo = bar as! Int
        """
        let attributes = AsExprVisitor.Attributes(form: .forced)
        let visitor = AsExprVisitor(attributes: attributes)

        assertVisitorRaisesViolations(
            on: source,
            visitor: visitor,
            expectedViolations: 2
        )
    }

    func testNormalAsExpressions() {
        let source = """
            let x = y as Int
            let a = b as! Int
            let foo = bar as! Int
        """
        let attributes = AsExprVisitor.Attributes(form: .normal)
        let visitor = AsExprVisitor(attributes: attributes)

        assertVisitorRaisesViolations(
            on: source,
            visitor: visitor,
            expectedViolations: 1
        )
    }

    func testNoAttributesFindsAllAsExpressions() {
        let source = """
            let x = y as? Int
            let a = b as! Int
            let foo = bar as! Int
        """
        let visitor = AsExprVisitor()

        assertVisitorRaisesViolations(
            on: source,
            visitor: visitor,
            expectedViolations: 3
        )
    }
}

private extension AsExprVisitorTests {
    func assertVisitorRaisesViolations(
        on source: String,
        visitor: AsExprVisitor,
        expectedViolations: Int) {
        XCTAssertNoThrow(try {
            let node = try SyntaxParser.parse(source: source)
            let violations = visitor.findViolations(node)
            XCTAssertEqual(violations.count, expectedViolations)
        }())
    }
}
