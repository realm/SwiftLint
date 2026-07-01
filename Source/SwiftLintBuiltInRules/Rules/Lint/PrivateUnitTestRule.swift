import Foundation
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct PrivateUnitTestRule: Rule {
    var configuration = PrivateUnitTestConfiguration()

    static let description = RuleDescription(
        identifier: "private_unit_test",
        name: "Private Unit Test",
        description: "Unit tests marked private are silently skipped",
        kind: .lint,
        nonTriggeringExamples: #examples([
            """
            class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """,
            """
            internal class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """,
            """
            public class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """,
            """
            @objc private class FooTest: XCTestCase {
                @objc private func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """,
            // Non-test classes
            """
            private class Foo: NSObject {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """,
            """
            private class Foo {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """,
            // Non-test methods
            """
            public class FooTest: XCTestCase {
                private func test1(param: Int) {}
                private func test2() -> String { "" }
                private func atest() {}
                private static func test3() {}
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            private ↓class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private func test4() {}
            }
            """,
            """
            class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """,
            """
            internal class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """,
            """
            public class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """,
        ]),
        corrections: #corrections([
            """

                ↓private class Test: XCTestCase {}
                """: """

                    class Test: XCTestCase {}
                    """,
            """
                class Test: XCTestCase {

                    ↓private func test1() {}
                    private func test2(i: Int) {}
                    @objc private func test3() {}
                    internal func test4() {}
                }
                """: """
                    class Test: XCTestCase {

                        func test1() {}
                        private func test2(i: Int) {}
                        @objc private func test3() {}
                        internal func test4() {}
                    }
                    """,
        ])
    )
}

private extension PrivateUnitTestRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            !node.isPrivate && node.isXCTestCase(configuration.testParentClasses) ? .visitChildren : .skipChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if node.isPrivate, node.isXCTestCase(configuration.testParentClasses) {
                violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.isTestMethod, node.isPrivate {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            guard node.isPrivate, node.isXCTestCase(configuration.testParentClasses) else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let (modifiers, declKeyword) = withoutPrivate(modifiers: node.modifiers, declKeyword: node.classKeyword)
            return super.visit(node.with(\.modifiers, modifiers).with(\.classKeyword, declKeyword))
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            guard node.isTestMethod, node.isPrivate else {
                return super.visit(node)
            }
            numberOfCorrections += 1
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
}

private extension ClassDeclSyntax {
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
        && (modifiers.isEmpty || !modifiers.contains(keyword: .static))
    }
}

private func resultInPrivateProperty(modifiers: DeclModifierListSyntax, attributes: AttributeListSyntax) -> Bool {
    modifiers.contains(keyword: .private) && !attributes.contains(attributeNamed: "objc")
}
