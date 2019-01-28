import Foundation
import SourceKittenFramework

public struct ProtocolPropertyAccessorsOrderRule: ConfigurationProviderRule, SubstitutionCorrectableRule,
                                                  AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "protocol_property_accessors_order",
        name: "Protocol Property Accessors Order",
        description: "When declaring properties in protocols, the order of accessors should be `get set`.",
        kind: .style,
        nonTriggeringExamples: [
            "protocol Foo {\n var bar: String { get set }\n }",
            "protocol Foo {\n var bar: String { get }\n }",
            "protocol Foo {\n var bar: String { set }\n }"
        ],
        triggeringExamples: [
            "protocol Foo {\n var bar: String { ↓set get }\n }"
        ],
        corrections: [
            "protocol Foo {\n var bar: String { ↓set get }\n }":
                "protocol Foo {\n var bar: String { get set }\n }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: File) -> [NSRange] {
        return file.match(pattern: "\\bset\\s*get\\b", with: [.keyword, .keyword])
    }

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "get set")
    }
}
