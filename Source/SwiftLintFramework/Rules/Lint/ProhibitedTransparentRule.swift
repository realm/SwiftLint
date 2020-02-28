import SourceKittenFramework

public struct ProhibitedTransparentRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_transparent",
        name: "Prohibted Transparent",
        description: "Avoid using transparent. Apple engineers discourage its use.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("func f() {}"),
            Example("@inline(__always) func f() {}"),
            Example("@inline(never) func f() {}"),
            Example("@objc func f() {}")
        ],
        triggeringExamples: [
            Example("@_transparent func f() {}")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard functionKinds.contains(kind),
            dictionary.enclosedSwiftAttributes.contains(.transparent),
            let funcOffset = dictionary.offset.flatMap(file.stringView.location) else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: funcOffset))]
    }

    fileprivate let functionKinds: [SwiftDeclarationKind] = [
        .functionAccessorAddress,
        .functionAccessorDidset,
        .functionAccessorGetter,
        .functionAccessorMutableaddress,
        .functionAccessorSetter,
        .functionAccessorWillset,
        .functionConstructor,
        .functionDestructor,
        .functionFree,
        .functionMethodClass,
        .functionMethodInstance,
        .functionMethodStatic,
        .functionOperator,
        .functionSubscript
    ]
}
