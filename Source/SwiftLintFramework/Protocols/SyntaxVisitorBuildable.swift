/// Builds a ViolationSyntaxVisitor that is responsible for matching a single syntax node.
///
/// The syntax matchers that make up the syntax for the SyntaxVisitor DSL will conform to this protocol.
/// These builders create a mapping to the appropriate ViolationSyntaxVisiting class.
/// It will also handle creating the parent-child relationships of visitors.
public protocol SyntaxVisitorBuildable {
    func makeVisitor() -> ViolationSyntaxVisiting
}
