import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct VariableShadowingRule: Rule {
    var configuration = VariableShadowingConfiguration()

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
            """, configuration: ["ignore_parameters": true]),
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
            for i in 1...10 {
                print(i)
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
            Example("""
            let a: Int?
            if let a { print(a) }
            """),
            Example("""
            let a: Int?
            guard let a else { return }
            """),
            Example("""
            let a: Int?
            while let a { print(a) }
            """),
            Example("""
            var a = 1
            if let a = a {
                print(a)
            }
            """),
            Example("""
            var a = 1
            if let a = self.a {
                print(a)
            }
            """),
            Example("""
            struct S {
                static let c: Int? = nil
                var a: Int?
                var b: Int {
                    if let a = self.a { a }
                    else if let c = Self.c { c }
                    else { 0 }
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            var foo = 1
            do {
                let ↓foo = 2
            }
            """),
            Example("""
            var a = 1
            if let ↓a = Optional(2) {
                let ↓a = 3
                print(a)
            }
            """),
            Example("""
            var i = 1
            for ↓i in 1...3 {
                let ↓i = 2
                print(i)
            }
            """),
            Example("""
            var a = 1
            func test() {
                do {
                    var ↓a = 2
                    print(a)
                }
            }
            """),
            Example("""
            func test() {
                var a = 1
                if var ↓a = Optional(2) {
                    var ↓a = 2
                    print(a)
                }
            }
            """),
            Example("""
            func test() {
                var a = 1
                for ↓a in 0..<1 {
                    var ↓a = 2
                    print(a)
                }
            }
            """),
            Example("""
            func test() {
                var a = 1
                while true {
                    var ↓a = 2
                    break
                }
            }
            """),
            Example("""
            var a: String?
            func test(↓a: String?) {
                let ↓a = ""
                print(a)
            }
            """, configuration: ["ignore_parameters": false]),
            Example("""
            struct S {
                var a = 1
                var b: Int {
                    let ↓a = 2
                    return a
                }
            }
            """),
            Example("""
            var a: String?
            while let ↓a = Optional("hello") {}
            """),
            Example("""
            var a = "outer"
            let (↓a, c) = ("first", "second")
            """),
        ]
    )
}

private extension VariableShadowingRule {
    final class Visitor: DeclaredIdentifiersTrackingVisitor<VariableShadowingConfiguration> {
        init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file, includeMembers: true)
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.parent?.is(MemberBlockItemSyntax.self) == false {
                let isUnmodifiable = node.bindingSpecifier.tokenKind == .keyword(.let)
                for binding in node.bindings where isUnmodifiable || !binding.isIdentity {
                    checkForShadowing(in: binding.pattern)
                }
            }
            return super.visit(node)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if !configuration.ignoreParameters {
                for param in node.signature.parameterClause.parameters {
                    let nameToken = param.secondName ?? param.firstName
                    if nameToken.text != "_", hasSeenDeclaration(for: nameToken.text) {
                        violations.append(nameToken.positionAfterSkippingLeadingTrivia)
                    }
                }
            }
            return super.visit(node)
        }

        override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
            checkForShadowing(in: node.pattern)
            return super.visit(node)
        }

        override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
            for condition in node.conditions {
                if let optBinding = condition.condition.as(OptionalBindingConditionSyntax.self) {
                    checkForShadowing(in: optBinding.pattern, binding: optBinding)
                }
            }
            return super.visit(node)
        }

        override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
            for condition in node.conditions {
                if let optBinding = condition.condition.as(OptionalBindingConditionSyntax.self) {
                    checkForShadowing(in: optBinding.pattern, binding: optBinding)
                }
            }
            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
            for condition in node.conditions {
                if let optBinding = condition.condition.as(OptionalBindingConditionSyntax.self) {
                    checkForShadowing(in: optBinding.pattern, binding: optBinding)
                }
            }
            return super.visit(node)
        }

        // Checking shadowing in both variable declarations and optional bindings.
        // For optional bindings, skips idiomatic patterns (if let a / if let a = a).
        private func checkForShadowing(in pattern: PatternSyntax, binding: OptionalBindingConditionSyntax? = nil) {
            if let identifier = pattern.as(IdentifierPatternSyntax.self) {
                let name = identifier.identifier.text
                if let binding, binding.initializer?.isBindingFor(name: name) != false {
                    return
                }
                if hasSeenDeclaration(for: name) {
                    violations.append(identifier.identifier.positionAfterSkippingLeadingTrivia)
                }
            } else if let tuple = pattern.as(TuplePatternSyntax.self) {
                tuple.elements.forEach { element in
                    checkForShadowing(in: element.pattern, binding: binding)
                }
            } else if let valueBinding = pattern.as(ValueBindingPatternSyntax.self) {
                checkForShadowing(in: valueBinding.pattern, binding: binding)
            }
        }
    }
}

private extension PatternBindingSyntax {
    var isIdentity: Bool {
        guard let initializer, let identifierPattern = pattern.as(IdentifierPatternSyntax.self) else {
            return false
        }
        return initializer.isBindingFor(name: identifierPattern.identifier.text)
    }
}

private extension InitializerClauseSyntax {
    func isBindingFor(name: String) -> Bool {
        if let identifierExpr = value.as(DeclReferenceExprSyntax.self) {
            return identifierExpr.baseName.text == name
        }
        if let memberAccessExpr = value.as(MemberAccessExprSyntax.self),
           let baseName = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.text,
           ["self", "Self"].contains(baseName) {
            return memberAccessExpr.declName.baseName.text == name
        }
        return false
    }
}
