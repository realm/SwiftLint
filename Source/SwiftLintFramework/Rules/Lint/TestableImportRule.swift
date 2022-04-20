import SourceKittenFramework
import SwiftSyntax

public struct TestableImportRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "testable_import",
        name: "Testable Import",
        description: "@testable import should only be used in test files",
        kind: .lint,
        nonTriggeringExamples: [
            Example("import Foo"),
            Example("""
            @testable import Foo
            import XCTest
            """),
            Example("""
            @testable import Foo
            import class XCTest.XCTestCase
            """),
            Example("""
            @testable import Foo
            import TestUtils

            class FooTests: XCTestCase {}
            """),
        ],
        triggeringExamples: [
            Example("↓@testable import Foo"),
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree else { return [] }

        let visitor = TestableImportRuleVisitor()
        visitor.walk(tree)

        if visitor.isTestFile {
            return []
        }

        return visitor.positions.map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position)))
        }
    }
}

private final class TestableImportRuleVisitor: SyntaxVisitor {
    private(set) var positions: [AbsolutePosition] = []
    private(set) var isTestFile = false

    override func visitPost(_ node: ImportDeclSyntax) {
        if node.isTestableImport {
            positions.append(node.positionAfterSkippingLeadingTrivia)
        }

        let testImports: Set = ["XCTest", "Quick", "Nimble"]
        let components = node.path.withoutTrivia().map(\.name.text)
        if !testImports.isDisjoint(with: components) {
            isTestFile = true
        }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        let inheritedTypes = node.inheritanceClause?.inheritedTypeCollection.map {
            $0.withoutTrivia().typeName.description
        } ?? []
        let testClasses: Set = ["XCTestCase", "QuickSpec"]
        if !testClasses.isDisjoint(with: inheritedTypes) {
            isTestFile = true
        }
    }
}

private extension ImportDeclSyntax {
    var isTestableImport: Bool {
        guard let attributes = self.attributes else {
            return false
        }

        return attributes.contains { syntax in
            syntax.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("testable")
        }
    }
}
