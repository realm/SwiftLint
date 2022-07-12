import SwiftSyntax

/// Visits type declaration nodes such as Enum, Class, and Struct
/// and adds a violation based on the criteria provided by Attributes.
public class DeclVisitor: ViolationSyntaxVisitor {
    /// These attributes will determine whether or not a decl node is violating
    public struct Attributes {
        /// Nodes with the specified access control will be considered a violation.
        public var accessControl: AccessControlLevel?

        /// If this is set, nodes that inherit from this set will NOT be considered a violation.
        /// This attribute takes precedence over other attributes.
        public var skipIfInheritsFrom: Set<String>?

        /// Nodes that inherit from this set will be considered a violation.
        public var inheritsFrom: Set<String>?

        /// Nodes with names that end with the given suffix will be considered a violation.
        public var suffix: String?

        public init(
            accessControl: AccessControlLevel? = nil,
            skipIfInheritsFrom: Set<String>? = nil,
            inheritsFrom: Set<String>? = nil,
            suffix: String? = nil
        ) {
            self.accessControl = accessControl
            self.skipIfInheritsFrom = skipIfInheritsFrom
            self.inheritsFrom = inheritsFrom
            self.suffix = suffix
        }
    }

    /// The type to check for. Can be enum, class, or struct.
    let objectType: ObjectType

    /// The attributes that determine whether a node is violating.
    let attributes: Attributes

    public init(
        objectType: ObjectType,
        attributes: Attributes = Attributes(),
        childVisitors: [ViolationSyntaxVisiting] = []
    ) {
        self.objectType = objectType
        self.attributes = attributes
        super.init()
        self.childVisitors = childVisitors
    }

    override public func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        guard objectType == .enum else {
            return .visitChildren
        }
        process(node)

        return .visitChildren
    }

    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard objectType == .class else {
            return .visitChildren
        }
        process(node)

        return .visitChildren
    }

    override public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        guard objectType == .struct else {
            return .visitChildren
        }
        process(node)

        return .visitChildren
    }
}

// MARK: - Private
private extension DeclVisitor {
    func process<SyntaxType: SyntaxProtocol & DeclSyntaxTraits>(_ node: SyntaxType) {
        guard nodeIsViolating(node) else {
            return
        }

        addViolations(node)
    }

    func nodeIsViolating(_ node: DeclSyntaxTraits) -> Bool {
        if let accessControl = attributes.accessControl {
            guard node.modifiers?.names.contains(accessControl.description) == true else {
                return false
            }
        }

        if let skipIfInheritsFrom = attributes.skipIfInheritsFrom {
            guard !objectInheritsFromInheritanceTypes(node.inheritance, typesToCheck: skipIfInheritsFrom) else {
                return false
            }
        }

        if let inheritsFrom = attributes.inheritsFrom {
            guard objectInheritsFromInheritanceTypes(node.inheritance, typesToCheck: inheritsFrom) else {
                return false
            }
        }

        if let suffix = attributes.suffix {
            guard node.name.hasSuffix(suffix) else {
                return false
            }
        }

        return true
    }

    func objectInheritsFromInheritanceTypes(_ inheritance: [String], typesToCheck: Set<String>) -> Bool {
        Set(inheritance).intersection(typesToCheck).isNotEmpty
    }
}
