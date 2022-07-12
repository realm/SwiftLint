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

    public init(
        @SyntaxVisitorRuleValidatorBuilder
        makeChildValidator: () -> (SyntaxVisitorRuleValidator) = { SyntaxVisitorRuleValidator(visitors: []) }
    ) {
        self.childValidator = makeChildValidator()
    }
}
