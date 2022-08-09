import SwiftSyntax

/// Visits "as" expressions used in downcasting i.e. let x = y as? Int
public final class AsExprVisitor: ViolationSyntaxVisitor {
    /// Represents the different operators that are used in downcasting
    public enum Form {
        /// Example: let x = y as? Int
        case optional

        /// Example: let x = y as! Int
        case forced

        /// Example: let x = y as Int
        case normal
    }

    /// The filters used to search for "as" expressions
    public struct Attributes {
        /// The operator used in the downcast
        var form: Form?

        /// Creates the AsExprVisitor's Attributes.
        public init(form: Form? = nil) {
            self.form = form
        }
    }

    /// The filters used to search for "as" expressions
    public let attributes: Attributes

    /// Creates an AsExprVisitor
    public init(attributes: Attributes = Attributes(), childVisitors: [ViolationSyntaxVisiting] = []) {
        self.attributes = attributes
        super.init()
        self.childVisitors = childVisitors
    }

    override public func visitPost(_ node: AsExprSyntax) {
        if let form = attributes.form {
            guard node.form == form else {
                return
            }
        }

        addViolations(node)
    }
}

private extension AsExprSyntax {
    var form: AsExprVisitor.Form {
        switch questionOrExclamationMark?.tokenKind {
        case .postfixQuestionMark:
            return .optional
        case .exclamationMark:
            return .forced
        default:
            return .normal
        }
    }
}
