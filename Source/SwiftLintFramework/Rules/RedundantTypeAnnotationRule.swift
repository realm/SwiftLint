import Foundation
import SourceKittenFramework

public struct RedundantTypeAnnotationRule: Rule, OptInRule, CorrectableRule,
                                           ConfigurationProviderRule, AutomaticTestableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_type_annotation",
        name: "Redundant Type Annotation",
        description: "Variables should not have redundant type annotation",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "var url = URL()",
            "var url: CustomStringConvertible = URL()"
        ],
        triggeringExamples: [
            "↓var url:URL=URL()",
            "↓var url:URL = URL(string: \"\")",
            "↓var url: URL = URL()",
            "↓let url: URL = URL()",
            "lazy ↓var url: URL = URL()",
            "↓let alphanumerics: CharacterSet = CharacterSet.alphanumerics"
        ],
        corrections: [
            "var url↓: URL = URL()": "var url = URL()",
            "let url↓: URL = URL()": "let url = URL()",
            "let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics":
                "let alphanumerics = CharacterSet.alphanumerics"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {

        return violationRanges(in: file).map { range in
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }

    public func correct(file: File) -> [Correction] {

        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        let typeAnnotationRanges = violatingRanges.map { typeAnnotationRange(in: file, violationRange: $0) }
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for typeAnnotationRange in typeAnnotationRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(typeAnnotationRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: "")
                adjustedLocations.insert(typeAnnotationRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description, location: Location(file: file, characterOffset: $0))
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {

        let pattern = "(var|let)\\s?\\w+:\\s?\\w+\\s?=\\s?\\w+(\\(|.)"

        let foundRanges = file.match(pattern: pattern, with: [.keyword, .identifier, .typeidentifier, .identifier])

        return foundRanges.filter { range in !isFalsePositive(in: file, range: range) }
    }

    private func typeAnnotationRange(in file: File, violationRange: NSRange) -> NSRange {
        return file.match(pattern: ":\\s?\\w+", excludingSyntaxKinds: [])[0]
    }

    private func isFalsePositive(in file: File, range: NSRange) -> Bool {

        let substring = file.contents.bridge().substring(with: range)

        let components = substring.components(separatedBy: "=")
        let charactersToTrimFromRhs = CharacterSet(charactersIn: ".(").union(.whitespaces)

        guard
            components.count == 2,
            let lhsTypeName = components[0].components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
        else {
            return true
        }

        let rhsTypeName = components[1].trimmingCharacters(in: charactersToTrimFromRhs)

        return lhsTypeName != rhsTypeName
    }
}
