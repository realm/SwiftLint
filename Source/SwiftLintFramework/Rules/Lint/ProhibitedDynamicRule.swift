import Foundation
import SourceKittenFramework

public struct ProhibitedDynamicRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_dynamic",
        name: "Prohibted Dynamic",
        description: "Avoid using dynamic.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("func f() {}"),
            Example("@inline(__always) func f() {}"),
            Example("@inline(never) func f() {}"),
            Example("@objc func f() {}")
        ],
        triggeringExamples: [
            Example("dynamic func f() {}"),
            Example("@inline(never) dynamic func f() {}"),
            Example("@objc dynamic func f() {}"),
            Example("@inline(never) dynamic func f() {}"),
            Example("dynamic\nfunc f() {}"),
            Example("@inline(never)\ndynamic func f() {}"),
            Example("@objc\ndynamic func f() {}"),
            Example("@inline(never)\ndynamic func f() {}"),
            Example("@objc\ndynamic\nfunc f() {}"),
            Example("@inline(never)\ndynamic\nfunc f() {}")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard functionKinds.contains(kind),
            dictionary.enclosedSwiftAttributes.contains(.dynamic),
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
