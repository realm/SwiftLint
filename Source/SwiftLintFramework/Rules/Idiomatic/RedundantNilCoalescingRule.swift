import Foundation
import SourceKittenFramework

public struct RedundantNilCoalescingRule: OptInRule, SubstitutionCorrectableRule, ConfigurationProviderRule,
                                          AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_nil_coalescing",
        name: "Redundant Nil Coalescing",
        description: "nil coalescing operator is only evaluated if the lhs is nil" +
            ", coalescing operator with nil as rhs is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "var myVar: Int?; myVar ?? 0\n"
        ],
        triggeringExamples: [
            "var myVar: Int? = nil; myVar↓ ?? nil\n",
            "var myVar: Int? = nil; myVar↓??nil\n"
        ],
        corrections: [
            "var myVar: Int? = nil; let foo = myVar↓ ?? nil\n": "var myVar: Int? = nil; let foo = myVar\n",
            "var myVar: Int? = nil; let foo = myVar↓??nil\n": "var myVar: Int? = nil; let foo = myVar\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "")
    }

    public func violationRanges(in file: File) -> [NSRange] {
        return file.match(pattern: "\\s?\\?{2}\\s*nil\\b", with: [.keyword])
    }
}
