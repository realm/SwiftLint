import SwiftSyntax

/// A type that finds and collects the positions of lint violations in a file.
public protocol ViolationCollecting: AnyObject {
    /// The AbsolutePositions of the syntax nodes that caused lint violations
    var positionsOfViolations: [AbsolutePosition] { get }
    
    /// A collection of ViolationSyntaxVisiting classes that will be used to visit the
    /// children of the node IF addViolations is called on the node.
    var childVisitors: [ViolationSyntaxVisiting] { get }
    
    /// Walks the AST starting at `tree`
    func findViolations<SyntaxType: SyntaxProtocol>(_ tree: SyntaxType) -> [AbsolutePosition]
    
    /// If there are no childVisitors, adds the position of `node` to `positionsOfViolations`.
    /// If there are childVisitors, do not add the positions of this `node`. Instead, run all `childVisitors`
    /// on the node's children.
    func addViolations<SyntaxType: SyntaxProtocol>(_ node: SyntaxType)
}

/// Convenience typealias for conforming to both ViolationCollecting and inheriting from SwiftSyntax's SyntaxVisitor
public typealias ViolationSyntaxVisiting = ViolationCollecting & SyntaxVisitor

/// Defines the shared behavior among all visitors that look for lint violations.
///
/// Subclass this class if you want to create a lint rule that traverses the Swift AST using SwiftSyntax.
/// /// /// To implement your subclass, you can override any of the visit(node:)
/// functions given by the SyntaxVisitor parent class and check if the node
/// violate the lint rule. If it does, call addViolations(node:).
/// If the object does not have any childVisitors, it adds the violations to the file.
/// Otherwise, it creates a new instance of each child visitor
/// and recrusively adds the violations found by the child visitors.
///
/// To use this class, call findViolations(node:) in order to start walking the AST
/// starting at the given node.
/// - Warning:
///  - You **must** always return .visitChildren within your override of visit(nodel).
///  If you don't, some nodes may be missed and not collected by the linter.
open class ViolationSyntaxVisitor: ViolationSyntaxVisiting {
    /// A collection of ViolationSyntaxVisiting classes that will be used to visit the
    /// children of the node IF addViolations is called on the node.
    public var childVisitors: [ViolationSyntaxVisiting] = []

    /// The AbsolutePositions of leaf nodes that called addViolations.
    ///
    /// Use this in your rule to create StyleViolations from these positions.
    public var positionsOfViolations: [AbsolutePosition] = []

    /// Call this function to walk through the AST starting at the given node
    /// and return all of the lint violations found.
    ///
    /// Calling this function will reset positionsOfViolations to an empty array and will
    /// restart the search for violations starting at the given node.
    public func findViolations<SyntaxType: SyntaxProtocol>(_ node: SyntaxType) -> [AbsolutePosition] {
        positionsOfViolations = []
        walk(node)
        return positionsOfViolations
    }

    /// Add the node's position after any leading trivia to positionsOfViolations.
    ///
    /// Subclasses should call this function within visitPost(node:) after determining this node violates a lint rule.
    public func addViolations<SyntaxType: SyntaxProtocol>(_ node: SyntaxType) {
        if childVisitors.isNotEmpty {
            childVisitors.forEach { childVistor in
                for child in node.children {
                    positionsOfViolations += childVistor.findViolations(child)
                }
            }
        } else {
            positionsOfViolations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
