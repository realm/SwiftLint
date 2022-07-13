// swiftlint:disable unused_declaration

/// This result builder enables us to write lint rules that traverse
/// the source file's AST using SwiftSyntax with a convenient DSL.
///
/// The components of the DSL will be objects that conform to SyntaxVisitorBuildable.
/// The result builder will know how to compose each individual
/// SyntaxVisitorBuildable object into a SyntaxVisitorRuleValidating object,
/// which is just a collection of SyntaxVisitors.
@resultBuilder
public struct SyntaxVisitorRuleValidatorBuilder {
    typealias Expression = SyntaxVisitorBuildable
    typealias Component = SyntaxVisitorRuleValidator

    static func buildBlock(_ component: Component...) -> Component {
        let visitors = component.flatMap(\.visitors)
        return SyntaxVisitorRuleValidator(visitors: visitors)
    }

    static func buildExpression(_ expression: SyntaxVisitorBuildable) -> Component {
        let visitor = expression.makeVisitor()
        return SyntaxVisitorRuleValidator(visitors: [visitor])
    }

    static func buildExpression(_ expression: ViolationSyntaxVisiting) -> Component {
        return SyntaxVisitorRuleValidator(visitors: [expression])
    }
}
