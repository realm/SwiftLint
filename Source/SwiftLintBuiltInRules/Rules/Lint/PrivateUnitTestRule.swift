import Foundation
import SwiftSyntax

struct PrivateUnitTestRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = PrivateUnitTestConfiguration()

    static let description = RuleDescription(
        identifier: "private_unit_test",
        name: "Private Unit Test",
        description: "Unit tests marked private are silently skipped",
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
                private static func test3() {}
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
        ],
        corrections: [
            Example("""

                ↓private class Test: XCTestCase {}
                """): Example("""

                    class Test: XCTestCase {}
                    """),
            Example("""
                class Test: XCTestCase {

                    ↓private func test1() {}
                    private func test2(i: Int) {}
                    @objc private func test3() {}
                    internal func test4() {}
                }
                """): Example("""
                    class Test: XCTestCase {

                        func test1() {}
                        private func test2(i: Int) {}
                        @objc private func test3() {}
                        internal func test4() {}
                    }
                    """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            configuration: configuration,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private class Visitor: ViolationsSyntaxVisitor {
    private let configuration: PrivateUnitTestConfiguration

    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

    init(configuration: PrivateUnitTestConfiguration) {
        self.configuration = configuration
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        !node.isPrivate && node.hasParent(configuredIn: configuration) ? .visitChildren : .skipChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if node.isPrivate, node.hasParent(configuredIn: configuration) {
            violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if node.isTestMethod, node.isPrivate {
            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [AbsolutePosition] = []
    private let configuration: PrivateUnitTestConfiguration
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(configuration: PrivateUnitTestConfiguration,
         locationConverter: SourceLocationConverter,
         disabledRegions: [SourceRange]) {
        self.configuration = configuration
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        guard
            node.isPrivate,
            node.hasParent(configuredIn: configuration),
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        else {
            return super.visit(node)
        }

        correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
        let (modifiers, declKeyword) = withoutPrivate(modifiers: node.modifiers, declKeyword: node.classKeyword)
        return super.visit(node.with(\.modifiers, modifiers).with(\.classKeyword, declKeyword))
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard
            node.isTestMethod,
            node.isPrivate,
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        else {
            return super.visit(node)
        }

        correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
        let (modifiers, declKeyword) = withoutPrivate(modifiers: node.modifiers, declKeyword: node.funcKeyword)
        return super.visit(node.with(\.modifiers, modifiers).with(\.funcKeyword, declKeyword))
    }

    private func withoutPrivate(modifiers: DeclModifierListSyntax,
                                declKeyword: TokenSyntax) -> (DeclModifierListSyntax, TokenSyntax) {
        var filteredModifiers = [DeclModifierSyntax]()
        var leadingTrivia = Trivia()
        for modifier in modifiers {
            let accumulatedLeadingTrivia = leadingTrivia + (modifier.leadingTrivia)
            if modifier.name.tokenKind == .keyword(.private) {
                leadingTrivia = accumulatedLeadingTrivia
            } else {
                filteredModifiers.append(modifier.with(\.leadingTrivia, accumulatedLeadingTrivia))
                leadingTrivia = Trivia()
            }
        }
        let declKeyword = declKeyword.with(\.leadingTrivia, leadingTrivia + (declKeyword.leadingTrivia))
        return (DeclModifierListSyntax(filteredModifiers), declKeyword)
    }
}

private extension ClassDeclSyntax {
    func hasParent(configuredIn config: PrivateUnitTestConfiguration) -> Bool {
        inheritanceClause?.inheritedTypes.contains { type in
            if let name = type.type.as(IdentifierTypeSyntax.self)?.name.text {
                return config.regex.numberOfMatches(in: name, range: name.fullNSRange) > 0
                    || config.testParentClasses.contains(name)
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
           name.text.hasPrefix("test")
        && signature.parameterClause.parameters.isEmpty
        && signature.returnClause == nil
        && (modifiers.isEmpty || !modifiers.hasStatic)
    }
}

private extension DeclModifierListSyntax {
    var hasPrivate: Bool {
        contains { $0.name.tokenKind == .keyword(.private) }
    }

    var hasStatic: Bool {
        contains { $0.name.tokenKind == .keyword(.static) }
    }
}

private func resultInPrivateProperty(modifiers: DeclModifierListSyntax, attributes: AttributeListSyntax) -> Bool {
    modifiers.isNotEmpty && modifiers.hasPrivate && !attributes.contains(attributeNamed: "objc")
}
