/// Conform to this protocol if the syntax can inherit or adopt from a protocol i.e. Classes, Structs, Enums
public protocol InheritableSyntaxVisitorBuildable: SyntaxVisitorBuildable {
    /// Filters to apply when searching for inheritable syntax nodes.
    var attributes: DeclVisitor.Attributes { get set }
    /// The actual type to look for. Tells the visitor to skip traversing other types.
    var objectType: ObjectType { get }
    /// If the node violates according to the attributes and the current node has children,
    /// visit the children node with this validator.
    var childValidator: SyntaxVisitorRuleValidator { get }
}

public extension InheritableSyntaxVisitorBuildable {
    func makeVisitor() -> ViolationSyntaxVisiting {
        DeclVisitor(
            objectType: objectType,
            attributes: attributes,
            childVisitors: childValidator.visitors
        )
    }
}

// MARK: - Lint Modifiers
public extension InheritableSyntaxVisitorBuildable {
    /// Filter by the access control of the type
    func accessControl(_ accessControl: AccessControlLevel) -> Self {
        var new = self
        new.attributes.accessControl = accessControl
        return new
    }

    /// Skip any nodes that inherit from the given set
    func skipIfInheritsFrom(_ skipIfInheritsFrom: Set<String>) -> Self {
        var new = self
        new.attributes.skipIfInheritsFrom = skipIfInheritsFrom
        return new
    }

    /// Filter by nodes that inherit from this set.
    /// The list will be treated as an OR statement i.e. the node inherits from any parent from the given set.
    func inheritsFrom(_ inheritsFrom: Set<String>) -> Self {
        var new = self
        new.attributes.inheritsFrom = inheritsFrom
        return new
    }

    /// Filter by the suffix of the node's name.
    func suffix(_ suffix: String) -> Self {
        var new = self
        new.attributes.suffix = suffix
        return new
    }
}
