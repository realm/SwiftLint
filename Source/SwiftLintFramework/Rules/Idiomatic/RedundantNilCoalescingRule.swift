import Foundation
import SourceKittenFramework

public struct RedundantNilCoalescingRule: OptInRule, SubstitutionCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_nil_coalescing",
        name: "Redundant Nil Coalescing",
        description: "nil coalescing operator is only evaluated if the lhs is nil" +
            ", coalescing operator with nil as rhs is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var myVar: Int?; myVar ?? 0\n")
        ],
        triggeringExamples: [
            Example("var myVar: Int? = nil; myVar↓ ?? nil\n"),
            Example("var myVar: Int? = nil; myVar↓??nil\n")
        ],
        corrections: [
            Example("var myVar: Int? = nil; let foo = myVar↓ ?? nil\n"):
                Example("var myVar: Int? = nil; let foo = myVar\n"),
            Example("var myVar: Int? = nil; let foo = myVar↓??nil\n"):
                Example("var myVar: Int? = nil; let foo = myVar\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return file.match(pattern: "\\s?\\?{2}\\s*nil\\b", with: [.keyword])
    }
}
