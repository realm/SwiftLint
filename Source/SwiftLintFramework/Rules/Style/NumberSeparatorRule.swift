import Foundation
import SourceKittenFramework

public struct NumberSeparatorRule: OptInRule, CorrectableRule, ConfigurationProviderRule {
    public var configuration = NumberSeparatorConfiguration(
        minimumLength: 0,
        minimumFractionLength: nil,
        excludeRanges: []
    )

    public init() {}

    public static let description = RuleDescription(
        identifier: "number_separator",
        name: "Number Separator",
        description: "Underscores should be used as thousand separator in large decimal numbers.",
        kind: .style,
        nonTriggeringExamples: NumberSeparatorRuleExamples.nonTriggeringExamples,
        triggeringExamples: NumberSeparatorRuleExamples.triggeringExamples,
        corrections: NumberSeparatorRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violatingRanges(in: file).map { range, _ in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }

    private func violatingRanges(in file: SwiftLintFile) -> [(NSRange, String)] {
        let numberTokens = file.syntaxMap.tokens.filter { $0.kind == .number }
        return numberTokens.compactMap { (token: SwiftLintSyntaxToken) -> (NSRange, String)? in
            guard
                let content = file.contents(for: token),
                isDecimal(number: content),
                !isInValidRanges(number: content)
            else {
                return nil
            }

            let signs = CharacterSet(charactersIn: "+-")
            let exponential = CharacterSet(charactersIn: "eE")
            guard let nonSign = content.components(separatedBy: signs).last,
                case let exponentialComponents = nonSign.components(separatedBy: exponential),
                let nonExponential = exponentialComponents.first else {
                    return nil
            }

            let components = nonExponential.components(separatedBy: ".")

            var validFraction = true
            var expectedFraction: String?
            if components.count == 2, let fractionSubstring = components.last {
                let result = isValid(number: fractionSubstring, isFraction: true)
                validFraction = result.0
                expectedFraction = result.1
            }

            guard let integerSubstring = components.first,
                case let (valid, expected) = isValid(number: integerSubstring, isFraction: false),
                !valid || !validFraction,
                let range = file.stringView.byteRangeToNSRange(token.range)
            else {
                return nil
            }

            var corrected = ""
            let hasSign = content.countOfLeadingCharacters(in: signs) == 1
            if hasSign {
                corrected += String(content.prefix(1))
            }

            corrected += expected
            if let fraction = expectedFraction {
                corrected += "." + fraction
            }

            if exponentialComponents.count == 2, let exponential = exponentialComponents.last {
                let exponentialSymbol = content.contains("e") ? "e" : "E"
                corrected += exponentialSymbol + exponential
            }

            return (range, corrected)
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = self.violatingRanges(in: file).filter { range, _ in
            return !file.ruleEnabled(violatingRanges: [range], for: self).isEmpty
        }

        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for (violatingRange, correction) in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: correction)
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func isDecimal(number: String) -> Bool {
        let lowercased = number.lowercased()
        let prefixes = ["0x", "0o", "0b"].flatMap { [$0, "-\($0)", "+\($0)"] }

        return !prefixes.contains(where: lowercased.hasPrefix)
    }

    private func isInValidRanges(number: String) -> Bool {
        let doubleValue = Double(number.replacingOccurrences(of: "_", with: ""))
        if let doubleValue = doubleValue, configuration.excludeRanges.contains(where: { $0.contains(doubleValue) }) {
            return true
        }

        return false
    }

    private func isValid(number: String, isFraction: Bool) -> (Bool, String) {
        var correctComponents = [String]()
        let clean = number.replacingOccurrences(of: "_", with: "")

        let minimumLength: Int
        if isFraction {
            minimumLength = configuration.minimumFractionLength ?? configuration.minimumLength
        } else {
            minimumLength = configuration.minimumLength
        }

        let shouldAddSeparators = clean.count >= minimumLength

        var numerals = 0
        for char in reversedIfNeeded(clean, reversed: !isFraction) {
            defer { correctComponents.append(String(char)) }
            guard char.unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains) else { continue }

            if numerals % 3 == 0 && numerals > 0 && shouldAddSeparators {
                correctComponents.append("_")
            }
            numerals += 1
        }

        let expected = reversedIfNeeded(correctComponents, reversed: !isFraction).joined()
        return (expected == number, expected)
    }

    private func reversedIfNeeded<T>(_ collection: T, reversed: Bool) -> [T.Element] where T: Collection {
        if reversed {
            return collection.reversed()
        }

        return Array(collection)
    }
}
