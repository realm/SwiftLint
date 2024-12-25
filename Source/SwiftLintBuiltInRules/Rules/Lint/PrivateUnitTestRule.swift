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
            """),
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
            """),
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
                    """),
        ]
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

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let (modifiers, declKeyword) = withoutPrivate(modifiers: node.modifiers, declKeyword: node.classKeyword)
            return super.visit(node.with(\.modifiers, modifiers).with(\.classKeyword, declKeyword))
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            guard node.isTestMethod, node.isPrivate else {
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
