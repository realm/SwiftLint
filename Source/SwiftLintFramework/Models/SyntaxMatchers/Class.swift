/// Creates a ViolationSyntaxVisitor class that will visit all class declarations 
/// and the position of the node from the source file if it has the charactaristics
/// declared by attributes.
///
/// Filter your search by using matcher modifiers. To find all classes that
/// inherit from UICollectionView, use:
///
///     Class().inheritsFrom("[UICollectionView]")
public struct Class: InheritableSyntaxVisitorBuildable {
    public let objectType: ObjectType = .class

    public var attributes = DeclVisitor.Attributes()
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
}
