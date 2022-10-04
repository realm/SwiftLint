import Foundation
import SwiftSyntax

public struct PrivateUnitTestRule: SwiftSyntaxRule, ConfigurationProviderRule, CacheDescriptionProvider {
    public var configuration: PrivateUnitTestConfiguration = {
        var configuration = PrivateUnitTestConfiguration(identifier: "private_unit_test")
        configuration.message = "Unit test marked `private` will not be run by XCTest."
        configuration.regex = regex("XCTestCase")
        return configuration
    }()

    internal var cacheDescription: String {
        return configuration.cacheDescription
    }

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_unit_test",
        name: "Private Unit Test",
        description: "Unit tests marked private are silently skipped.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            internal class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            public class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            @objc private class FooTest: XCTestCase {
                @objc private func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            // Non-test classes
            Example("""
            private class Foo: NSObject {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            private class Foo {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            // Non-test methods
            Example("""
            public class FooTest: XCTestCase {
                private func test1(param: Int) {}
                private func test2() -> String { "" }
                private func atest() {}
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            private ↓class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private func test4() {}
            }
            """),
            Example("""
            class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """),
            Example("""
            internal class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """),
            Example("""
            public class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(parentClassRegex: configuration.regex)
    }
}

private class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []
    private let parentClassRegex: NSRegularExpression

    init(parentClassRegex: NSRegularExpression) {
        self.parentClassRegex = parentClassRegex
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        node.hasParent(matching: parentClassRegex) && !node.isPrivate ? .visitChildren : .skipChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if node.hasParent(matching: parentClassRegex), node.isPrivate {
            violationPositions.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if node.isTestMethod, node.isPrivate {
            violationPositions.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ClassDeclSyntax {
    func hasParent(matching pattern: NSRegularExpression) -> Bool {
        inheritanceClause?.inheritedTypeCollection.contains { type in
            if let name = type.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text {
                return pattern.numberOfMatches(in: name, range: name.fullNSRange) > 0
            }
            return false
        } ?? false
    }

    var isPrivate: Bool {
        resultInPrivateProperty(modifiers: modifiers, attributes: attributes)
    }
}

private extension FunctionDeclSyntax {
    var isPrivate: Bool {
        resultInPrivateProperty(modifiers: modifiers, attributes: attributes)
    }

    var isTestMethod: Bool {
        identifier.text.hasPrefix("test") && signature.input.parameterList.isEmpty && signature.output == nil
    }
}

private extension ModifierListSyntax {
    var hasPrivate: Bool {
        contains { $0.name.tokenKind == .privateKeyword }
    }
}

private func resultInPrivateProperty(modifiers: ModifierListSyntax?, attributes: AttributeListSyntax?) -> Bool {
    guard let modifiers, modifiers.hasPrivate else {
        return false
    }
    guard let attributes else {
        return true
    }
    return !attributes.contains { $0.as(AttributeSyntax.self)?.attributeName.tokenKind == .contextualKeyword("objc") }
}
