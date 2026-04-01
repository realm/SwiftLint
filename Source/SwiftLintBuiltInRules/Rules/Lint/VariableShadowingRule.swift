import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct VariableShadowingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "variable_shadowing",
        name: "Variable Shadowing",
        description: "Do not shadow variables declared in outer scopes",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            var a: String?
            func test(a: String?) {
                print(a)
            }
            """),
            Example("""
            var a: String = "hello"
            if let b = a {
                print(b)
            }
            """),
            Example("""
            var a: String?
            func test() {
                if let b = a {
                    print(b)
                }
            }
            """),
            Example("""
            for i in 1...10 {
                print(i)
            }
            for j in 1...10 {
                print(j)
            }
            """),
            Example("""
            func test() {
                var a: String = "hello"
                func nested() {
                    var b: String = "world"
                    print(a, b)
                }
            }
            """),
            Example("""
            class Test {
                var a: String?
                func test(a: String?) {
                    print(a)
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            var outer: String = "hello"
            func test() {
                let ↓outer = "world"
                print(outer)
            }
            """),
        ]
    )
}

private extension VariableShadowingRule {
    final class Visitor: DeclaredIdentifiersTrackingVisitor<ConfigurationType> {
        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            // Early exit for member blocks (class/struct properties)
            if node.parent?.is(MemberBlockItemSyntax.self) != true {
                // Check for shadowing BEFORE adding to scope
                node.bindings.forEach { binding in
                    checkForShadowing(in: binding.pattern)
                }
            }
            return super.visit(node)
        }

        private func checkForShadowing(in pattern: PatternSyntax) {
            // Handle direct identifier patterns
            if let identifier = pattern.as(IdentifierPatternSyntax.self) {
                let identifierText = identifier.identifier.text
                if isShadowingOuterScope(identifierText) {
                    violations.append(identifier.identifier.positionAfterSkippingLeadingTrivia)
                }
                return
            }

            // Recurse into tuple patterns: e.g., (a, b)
            if let tuple = pattern.as(TuplePatternSyntax.self) {
                tuple.elements.forEach { element in
                    checkForShadowing(in: element.pattern)
                }
                return
            }

            // Recurse into value binding patterns: e.g., `let a`, `var (a, b)`
            if let valueBinding = pattern.as(ValueBindingPatternSyntax.self) {
                checkForShadowing(in: valueBinding.pattern)
                return
            }

            // Other pattern kinds are not relevant for shadowing checks here; no action needed.
        }

        private func isShadowingOuterScope(_ identifier: String) -> Bool {
            guard !scope.isEmpty, scope.count > 1 else { return false }

            // Use early exit and lazy evaluation for better performance
            for scopeDeclarations in scope.dropLast() where
                scopeDeclarations.lazy.contains(where: { $0.declares(id: identifier) }) {
                return true
            }
            return false
        }
    }
}
