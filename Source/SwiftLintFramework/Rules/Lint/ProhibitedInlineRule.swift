import SourceKittenFramework

public struct ProhibitedInlineRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_inline",
        name: "Prohibited Inline",
        description: "Avoid using @inline. Apple engineers discourage its use.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("func f() {}"),
            Example("dynamic func f() {}"),
            Example("@objc func f() {}"),
            Example("@_transparent func f()")
        ],
        triggeringExamples: [
            Example("@inline(__always) func f() {}"),
            Example("@inline(never) dynamic func f() {}"),
            Example("@objc @inline(__always) func f() {}"),
            Example("@inline(__always) @objc func f() {}"),
            Example("@inline(never) dynamic func f() {}"),
            Example("@inline(__always)\nfunc f() {}"),
            Example("@inline(never)\ndynamic func f() {}"),
            Example("@objc\n@inline(__always) func f() {}"),
            Example("@inline(__always)\n@objc func f() {}"),
            Example("@inline(never)\ndynamic func f() {}"),
            Example("@objc\n@inline(__always)\nfunc f() {}"),
            Example("@inline(__always)\n@objc\nfunc f() {}"),
            Example("@inline(never)\ndynamic\nfunc f() {}")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard functionKinds.contains(kind),
            dictionary.enclosedSwiftAttributes.contains(.inline),
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
