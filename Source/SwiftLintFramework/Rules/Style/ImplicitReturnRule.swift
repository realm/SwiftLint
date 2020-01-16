import Foundation
import SourceKittenFramework

public struct ImplicitReturnRule: ConfigurationProviderRule, SubstitutionCorrectableRule, OptInRule {
    public var configuration = ImplicitReturnConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures, functions and getters.",
        kind: .style,
        nonTriggeringExamples: ImplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitReturnRuleExamples.triggeringExamples,
        corrections: ImplicitReturnRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).compactMap {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let pattern = "(?:\\bin|\\{)\\s+(return\\s+)"
        let contents = file.stringView

        return file.matchesAndSyntaxKinds(matching: pattern).compactMap { result, kinds in
            let range = result.range
            guard kinds == [.keyword, .keyword] || kinds == [.keyword],
                let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length),
                let outerKindString = file.structureDictionary.kinds(forByteOffset: byteRange.location).last?.kind
            else {
                return nil
            }

            func isKindIncluded(_ kind: ImplicitReturnConfiguration.ReturnKind) -> Bool {
                return self.configuration.isKindIncluded(kind)
            }

            if let outerKind = SwiftExpressionKind(rawValue: outerKindString),
                isKindIncluded(.closure),
                [.call, .argument, .closure].contains(outerKind) {
                    return result.range(at: 1)
            }

            if let outerKind = SwiftDeclarationKind(rawValue: outerKindString),
                (isKindIncluded(.function) && SwiftDeclarationKind.functionKinds.contains(outerKind)) ||
                (isKindIncluded(.getter) && SwiftDeclarationKind.variableKinds.contains(outerKind)) {
                    return result.range(at: 1)
            }

            return nil
        }
    }
}
