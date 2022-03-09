import SwiftSyntax

/// A rule that leverages the SwiftSyntax library.
public protocol SyntaxRule: Rule {
    /// The `SyntaxRuleVisitor` type that will be used to compute violations.
    associatedtype Visitor: SyntaxRuleVisitor

    /// Creates the visitor that will be used to compute violations. By default, it calls `Visitor.init()`.
    func makeVisitor() -> Visitor
}

/// A SwiftSyntax visitor that collects data to provide violations for a specific rule.
public protocol SyntaxRuleVisitor: SyntaxVisitor {
    /// The rule that uses this visitor.
    associatedtype Rule: SyntaxRule

    /// A default initializer for visitors. All visitors need to be trivially initializable.
    init()

    /// Returns the violations that should be calculated based on data that was accumulated during the `visit` methods.
    func violations(for rule: Rule, in file: SwiftLintFile) -> [StyleViolation]
}

public extension SyntaxRule where Visitor.Rule == Self {
    /// Wraps computation of violations based on a visitor.
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree else {
            return []
        }

        let visitor = makeVisitor()
        visitor.walk(tree)
        return visitor.violations(for: self, in: file)
    }

    func makeVisitor() -> Visitor {
        return Visitor()
    }
}
