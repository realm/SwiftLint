/// Matches downcasting or "as" expressions in Swift
///
/// A constant or variable of a certain class type may actually
/// refer to an instance of a subclass behind the scenes.
/// Where you believe this is the case, you can try to
/// downcast to the subclass type with a type cast operator (as? or as!).
public struct DownCast: SyntaxVisitorBuildable {
    public var attributes = AsExprVisitor.Attributes()
    public let childValidator: SyntaxVisitorRuleValidator

    /// Creates a Class matcher.
    ///
    /// - parameter makeChildValidator A closure that creates a SyntaxVisitorRuleValidator.
    ///                               The returned validator will be set as this matcher's child.
    public init(
        @SyntaxVisitorRuleValidatorBuilder
        makeChildValidator: () -> (SyntaxVisitorRuleValidator) = { SyntaxVisitorRuleValidator(visitors: []) }
    ) {
        self.childValidator = makeChildValidator()
    }

    /// Creates the visitor that will find the as expressions according to the
    /// attributes set.
    public func makeVisitor() -> ViolationSyntaxVisiting {
        AsExprVisitor(attributes: attributes, childVisitors: childValidator.visitors)
    }
}

// MARK: - Lint Modifiers
public extension DownCast {
    /// Filter by the form of downcasting used
    func form(_ form: AsExprVisitor.Form) -> Self {
        var new = self
        new.attributes.form = form
        return new
    }
}
