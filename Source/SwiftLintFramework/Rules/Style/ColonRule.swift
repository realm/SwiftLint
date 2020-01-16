import Foundation
import SourceKittenFramework

private enum ColonKind {
    case type
    case dictionary
    case functionCall
}

public struct ColonRule: CorrectableRule, ConfigurationProviderRule {
    public var configuration = ColonConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "colon",
        name: "Colon",
        description: "Colons should be next to the identifier when specifying a type " +
                     "and next to the key in dictionary literals.",
        kind: .style,
        nonTriggeringExamples: ColonRuleExamples.nonTriggeringExamples,
        triggeringExamples: ColonRuleExamples.triggeringExamples,
        corrections: ColonRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let violations = typeColonViolationRanges(in: file, matching: pattern).compactMap { range in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }

        let dictionaryViolations: [StyleViolation]
        if configuration.applyToDictionaries {
            dictionaryViolations = validate(file: file, dictionary: file.structureDictionary)
        } else {
            dictionaryViolations = []
        }

        return (violations + dictionaryViolations).sorted { $0.location < $1.location }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violations = correctionRanges(in: file)
        let matches = violations.filter {
            !file.ruleEnabled(violatingRanges: [$0.range], for: self).isEmpty
        }

        guard !matches.isEmpty else { return [] }
        let regularExpression = regex(pattern)
        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for (range, kind) in matches.reversed() {
            switch kind {
            case .type:
                contents = regularExpression.stringByReplacingMatches(in: contents,
                                                                      options: [],
                                                                      range: range,
                                                                      withTemplate: "$1$2: $3")
            case .dictionary, .functionCall:
                contents = contents.bridge().replacingCharacters(in: range, with: ": ")
            }

            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }

    private typealias RangeWithKind = (range: NSRange, kind: ColonKind)

    private func correctionRanges(in file: SwiftLintFile) -> [RangeWithKind] {
        let violations: [RangeWithKind] = typeColonViolationRanges(in: file, matching: pattern).map {
            (range: $0, kind: ColonKind.type)
        }
        let dictionary = file.structureDictionary
        let contents = file.stringView
        let dictViolations: [RangeWithKind] = dictionaryColonViolationRanges(in: file,
                                                                             dictionary: dictionary).compactMap {
            return contents.byteRangeToNSRange($0).map { (range: $0, kind: .dictionary) }
        }
        let functionViolations: [RangeWithKind] = functionCallColonViolationRanges(in: file,
                                                                                   dictionary: dictionary).compactMap {
            return contents.byteRangeToNSRange($0).map { (range: $0, kind: .functionCall) }
        }

        return (violations + dictViolations + functionViolations).sorted {
            $0.range.location < $1.range.location
        }
    }
}

extension ColonRule: ASTRule {
    /// Only returns dictionary and function calls colon violations.
    ///
    /// - parameter file:       The file to validate.
    /// - parameter kind:       The expression kind to parse.
    /// - parameter dictionary: The substructure to validate.
    ///
    /// - returns: Colon rule style violations in dictionaries and function calls.
    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let ranges = dictionaryColonViolationRanges(in: file, kind: kind, dictionary: dictionary) +
            functionCallColonViolationRanges(in: file, kind: kind, dictionary: dictionary)

        return ranges.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: $0.location))
        }
    }
}
