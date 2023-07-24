// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

/// The rule list containing all available rules built into SwiftLint.
public let builtInRules: [Rule.Type] = [
    AccessibilityLabelForImageRule.self,
    AccessibilityTraitForButtonRule.self,
    AnonymousArgumentInMultilineClosureRule.self,
    AnyObjectProtocolRule.self,
    ArrayInitRule.self,
    AttributesRule.self,
    BalancedXCTestLifecycleRule.self,
    BlanketDisableCommandRule.self,
    BlockBasedKVORule.self,
    CaptureVariableRule.self,
    ClassDelegateProtocolRule.self,
    ClosingBraceRule.self,
    ClosureBodyLengthRule.self,
    ClosureEndIndentationRule.self,
    ClosureParameterPositionRule.self,
    ClosureSpacingRule.self,
    CollectionAlignmentRule.self,
    ColonRule.self,
    CommaInheritanceRule.self,
    CommaRule.self,
    CommentSpacingRule.self,
    CommentStyleRule.self,
    CompilerProtocolInitRule.self,
    ComputedAccessorsOrderRule.self,
    ConditionalReturnsOnNewlineRule.self,
    ContainsOverFilterCountRule.self,
    ContainsOverFilterIsEmptyRule.self,
    ContainsOverFirstNotNilRule.self,
    ContainsOverRangeNilComparisonRule.self,
    ControlStatementRule.self,
    ConvenienceTypeRule.self,
    CyclomaticComplexityRule.self,
    DeploymentTargetRule.self,
    DirectReturnRule.self,
    DiscardedNotificationCenterObserverRule.self,
    DiscouragedAssertRule.self,
    DiscouragedDirectInitRule.self,
    DiscouragedNoneNameRule.self,
    DiscouragedObjectLiteralRule.self,
    DiscouragedOptionalBooleanRule.self,
    DiscouragedOptionalCollectionRule.self,
    DuplicateConditionsRule.self,
    DuplicateEnumCasesRule.self,
    DuplicateImportsRule.self,
    DuplicatedKeyInDictionaryLiteralRule.self,
    DynamicInlineRule.self,
    EmptyCollectionLiteralRule.self,
    EmptyCountRule.self,
    EmptyEnumArgumentsRule.self,
    EmptyParametersRule.self,
    EmptyParenthesesWithTrailingClosureRule.self,
    EmptyStringRule.self,
    EmptyXCTestMethodRule.self,
    EnumCaseAssociatedValuesLengthRule.self,
    ExpiringTodoRule.self,
    ExplicitACLRule.self,
    ExplicitEnumRawValueRule.self,
    ExplicitInitRule.self,
    ExplicitSelfRule.self,
    ExplicitTopLevelACLRule.self,
    ExplicitTypeInterfaceRule.self,
    ExtensionAccessModifierRule.self,
    FallthroughRule.self,
    FatalErrorMessageRule.self,
    FileHeaderRule.self,
    FileLengthRule.self,
    FileNameNoSpaceRule.self,
    FileNameRule.self,
    FileTypesOrderRule.self,
    FirstWhereRule.self,
    FlatMapOverMapReduceRule.self,
    ForWhereRule.self,
    ForceCastRule.self,
    ForceTryRule.self,
    ForceUnwrappingRule.self,
    FunctionBodyLengthRule.self,
    FunctionDefaultParameterAtEndRule.self,
    FunctionParameterCountRule.self,
    GenericTypeNameRule.self,
    IBInspectableInExtensionRule.self,
    IdenticalOperandsRule.self,
    IdentifierNameRule.self,
    ImplicitGetterRule.self,
    ImplicitReturnRule.self,
    ImplicitlyUnwrappedOptionalRule.self,
    InclusiveLanguageRule.self,
    IndentationWidthRule.self,
    InertDeferRule.self,
    InvalidSwiftLintCommandRule.self,
    IsDisjointRule.self,
    JoinedDefaultParameterRule.self,
    LargeTupleRule.self,
    LastWhereRule.self,
    LeadingWhitespaceRule.self,
    LegacyCGGeometryFunctionsRule.self,
    LegacyConstantRule.self,
    LegacyConstructorRule.self,
    LegacyHashingRule.self,
    LegacyMultipleRule.self,
    LegacyNSGeometryFunctionsRule.self,
    LegacyObjcTypeRule.self,
    LegacyRandomRule.self,
    LetVarWhitespaceRule.self,
    LineLengthRule.self,
    LiteralExpressionEndIndentationRule.self,
    LocalDocCommentRule.self,
    LowerACLThanParentRule.self,
    MarkRule.self,
    MissingDocsRule.self,
    ModifierOrderRule.self,
    MultilineArgumentsBracketsRule.self,
    MultilineArgumentsRule.self,
    MultilineFunctionChainsRule.self,
    MultilineLiteralBracketsRule.self,
    MultilineParametersBracketsRule.self,
    MultilineParametersRule.self,
    MultipleClosuresWithTrailingClosureRule.self,
    NSLocalizedStringKeyRule.self,
    NSLocalizedStringRequireBundleRule.self,
    NSNumberInitAsFunctionReferenceRule.self,
    NSObjectPreferIsEqualRule.self,
    NestingRule.self,
    NimbleOperatorRule.self,
    NoExtensionAccessModifierRule.self,
    NoFallthroughOnlyRule.self,
    NoGroupingExtensionRule.self,
    NoMagicNumbersRule.self,
    NoSpaceInMethodCallRule.self,
    NotificationCenterDetachmentRule.self,
    NumberSeparatorRule.self,
    ObjectLiteralRule.self,
    OpeningBraceRule.self,
    OperatorFunctionWhitespaceRule.self,
    OperatorUsageWhitespaceRule.self,
    OptionalEnumCaseMatchingRule.self,
    OrphanedDocCommentRule.self,
    OverriddenSuperCallRule.self,
    OverrideInExtensionRule.self,
    PatternMatchingKeywordsRule.self,
    PeriodSpacingRule.self,
    PreferNimbleRule.self,
    PreferSelfInStaticReferencesRule.self,
    PreferSelfTypeOverTypeOfSelfRule.self,
    PreferZeroOverExplicitInitRule.self,
    PrefixedTopLevelConstantRule.self,
    PrivateActionRule.self,
    PrivateOutletRule.self,
    PrivateOverFilePrivateRule.self,
    PrivateSubjectRule.self,
    PrivateSwiftUIStatePropertyRule.self,
    PrivateUnitTestRule.self,
    ProhibitedInterfaceBuilderRule.self,
    ProhibitedSuperRule.self,
    ProtocolPropertyAccessorsOrderRule.self,
    QuickDiscouragedCallRule.self,
    QuickDiscouragedFocusedTestRule.self,
    QuickDiscouragedPendingTestRule.self,
    RawValueForCamelCasedCodableEnumRule.self,
    ReduceBooleanRule.self,
    ReduceIntoRule.self,
    RedundantDiscardableLetRule.self,
    RedundantNilCoalescingRule.self,
    RedundantObjcAttributeRule.self,
    RedundantOptionalInitializationRule.self,
    RedundantSelfInClosureRule.self,
    RedundantSetAccessControlRule.self,
    RedundantStringEnumValueRule.self,
    RedundantTypeAnnotationRule.self,
    RedundantVoidReturnRule.self,
    RequiredDeinitRule.self,
    RequiredEnumCaseRule.self,
    ReturnArrowWhitespaceRule.self,
    ReturnValueFromVoidFunctionRule.self,
    SelfBindingRule.self,
    SelfInPropertyInitializationRule.self,
    ShorthandOperatorRule.self,
    ShorthandOptionalBindingRule.self,
    SingleTestClassRule.self,
    SortedEnumCasesRule.self,
    SortedFirstLastRule.self,
    SortedImportsRule.self,
    StatementPositionRule.self,
    StaticOperatorRule.self,
    StrictFilePrivateRule.self,
    StrongIBOutletRule.self,
    SuperfluousElseRule.self,
    SwitchCaseAlignmentRule.self,
    SwitchCaseOnNewlineRule.self,
    SyntacticSugarRule.self,
    TestCaseAccessibilityRule.self,
    TodoRule.self,
    ToggleBoolRule.self,
    TrailingClosureRule.self,
    TrailingCommaRule.self,
    TrailingNewlineRule.self,
    TrailingSemicolonRule.self,
    TrailingWhitespaceRule.self,
    TypeBodyLengthRule.self,
    TypeContentsOrderRule.self,
    TypeNameRule.self,
    TypesafeArrayInitRule.self,
    UnavailableConditionRule.self,
    UnavailableFunctionRule.self,
    UnhandledThrowingTaskRule.self,
    UnneededBreakInSwitchRule.self,
    UnneededOverrideRule.self,
    UnneededParenthesesInClosureArgumentRule.self,
    UnneededSynthesizedInitializerRule.self,
    UnownedVariableCaptureRule.self,
    UntypedErrorInCatchRule.self,
    UnusedCaptureListRule.self,
    UnusedClosureParameterRule.self,
    UnusedControlFlowLabelRule.self,
    UnusedDeclarationRule.self,
    UnusedEnumeratedRule.self,
    UnusedImportRule.self,
    UnusedOptionalBindingRule.self,
    UnusedSetterValueRule.self,
    ValidIBInspectableRule.self,
    VerticalParameterAlignmentOnCallRule.self,
    VerticalParameterAlignmentRule.self,
    VerticalWhitespaceBetweenCasesRule.self,
    VerticalWhitespaceClosingBracesRule.self,
    VerticalWhitespaceOpeningBracesRule.self,
    VerticalWhitespaceRule.self,
    VoidFunctionInTernaryConditionRule.self,
    VoidReturnRule.self,
    WeakDelegateRule.self,
    XCTFailMessageRule.self,
    XCTSpecificMatcherRule.self,
    YodaConditionRule.self
]
