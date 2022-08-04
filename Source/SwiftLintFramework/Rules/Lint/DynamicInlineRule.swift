import Foundation
import SourceKittenFramework

public struct DynamicInlineRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "dynamic_inline",
        name: "Dynamic Inline",
        description: "Avoid using 'dynamic' and '@inline(__always)' together.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class C {\ndynamic func f() {}}"),
            Example("class C {\n@inline(__always) func f() {}}"),
            Example("class C {\n@inline(never) dynamic func f() {}}")
        ],
        triggeringExamples: [
            Example("class C {\n@inline(__always) dynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always) public dynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always) dynamic internal ↓func f() {}\n}"),
            Example("class C {\n@inline(__always)\ndynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always)\ndynamic\n↓func f() {}\n}")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        // Look for functions with both "inline" and "dynamic". For each of these, we can get offset
        // of the "func" keyword. We can assume that the nearest "@inline" before this offset is
        // the attribute we are interested in.
        guard functionKinds.contains(kind),
            case let attributes = dictionary.enclosedSwiftAttributes,
            attributes.contains(.dynamic),
            attributes.contains(.inline),
            let funcOffset = dictionary.offset.flatMap(file.stringView.location),
            case let inlinePattern = regex("@inline"),
            case let range = NSRange(location: 0, length: funcOffset),
            let inlineMatch = inlinePattern.matches(in: file.contents, options: [], range: range)
                .last,
            inlineMatch.range.location != NSNotFound,
            case let attributeRange = NSRange(location: inlineMatch.range.location,
                                              length: funcOffset - inlineMatch.range.location),
            case let alwaysInlinePattern = regex("@inline\\(\\s*__always\\s*\\)"),
            alwaysInlinePattern.firstMatch(in: file.contents, options: [], range: attributeRange) != nil
        else {
            return []
        }
        return [StyleViolation(ruleDescription: Self.description,
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
