import Foundation
import SourceKittenFramework

struct ImplicitReturnRule: ConfigurationProviderRule, SubstitutionCorrectableRule, OptInRule {
    var configuration = ImplicitReturnConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures, functions and getters",
        kind: .style,
        nonTriggeringExamples: ImplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitReturnRuleExamples.triggeringExamples,
        corrections: ImplicitReturnRuleExamples.corrections
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).compactMap {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let pattern = "(?:\\bin|\\{)\\s+(return\\s+)"
        let contents = file.stringView

        return file.matchesAndSyntaxKinds(matching: pattern).compactMap { result, kinds in
            let range = result.range
            guard kinds == [.keyword, .keyword] || kinds == [.keyword],
                let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length),
                case let kinds = file.structureDictionary.kinds(forByteOffset: byteRange.location),
                let outerKindString = kinds.lastExcludingBrace()?.kind
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

private extension Array where Element == (kind: String, byteRange: ByteRange) {
    func lastExcludingBrace() -> Element? {
        guard SwiftVersion.current >= .fiveDotFour else {
            return last
        }

        guard let last = last else {
            return nil
        }

        guard last.kind == "source.lang.swift.stmt.brace", count > 1 else {
            return last
        }

        let secondLast = self[endIndex - 2]
        if SwiftExpressionKind(rawValue: secondLast.kind) == .closure {
            return secondLast
        }

        return last
    }
}
