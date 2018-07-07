import Foundation
import SourceKittenFramework

public struct AnyObjectProtocolRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "anyobject_protocol",
        name: "AnyObject Protocol",
        description: "Prefer using `AnyObject` over `class` for class-only protocols.",
        kind: .lint,
        nonTriggeringExamples: [
            "protocol SomeProtocol {}",
            "protocol SomeClassOnlyProtocol: AnyObject {}",
            "protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}"
        ],
        triggeringExamples: [
            "↓protocol SomeClassOnlyProtocol: class {}",
            "↓protocol SomeClassOnlyProtocol: class, SomeInheritedProtocol {}"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .protocol,
            dictionary.inheritedTypes.contains("class"),
            let offset = dictionary.offset
            else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
