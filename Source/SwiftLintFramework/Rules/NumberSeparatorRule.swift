//
//  NumberSeparatorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/05/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NumberSeparatorRule: OptInRule, CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static var corrections: [String: String] {
        var result = [String: String]()

        for (violation, sign) in [("↓-", "-"), ("+↓", "+"), ("↓", "")] {
            result["let foo = \(violation)10_0"] = "let foo = \(sign)100"
            result["let foo = \(violation)1000"] = "let foo = \(sign)1_000"
            result["let foo = \(violation)1000e2"] = "let foo = \(sign)1_000e2"
            result["let foo = \(violation)1__000"] = "let foo = \(sign)1_000"
            result["let foo = \(violation)1.0001"] = "let foo = \(sign)1.000_1"
            result["let foo = \(violation)1_000_000.000000_1"] = "let foo = \(sign)1_000_000.000_000_1"
            result["let foo = \(violation)1000000.000000_1"] = "let foo = \(sign)1_000_000.000_000_1"
        }

        return result
    }

    public static let description = RuleDescription(
        identifier: "number_separator",
        name: "Number Separator",
        description: "Underscores should be used as thousand separator in large decimal numbers.",
        nonTriggeringExamples: ["-", "+", ""].flatMap { (sign: String) -> [String] in
            [
                "let foo = \(sign)100",
                "let foo = \(sign)1_000",
                "let foo = \(sign)1_000_000",
                "let foo = \(sign)1.000_1",
                "let foo = \(sign)1_000_000.000_000_1",
                "let binary = \(sign)0b10000",
                "let binary = \(sign)0b1000_0001",
                "let hex = \(sign)0xA",
                "let hex = \(sign)0xAA_BB",
                "let octal = \(sign)0o21",
                "let octal = \(sign)0o21_1",
                "let exp = \(sign)1_000_000.000_000e2"
            ]
        },
        triggeringExamples: ["↓-", "+↓", "↓"].flatMap { (sign: String) -> [String] in
            [
                "let foo = \(sign)10_0",
                "let foo = \(sign)1000",
                "let foo = \(sign)1000e2",
                "let foo = \(sign)1__000",
                "let foo = \(sign)1.0001",
                "let foo = \(sign)1_000_000.000000_1",
                "let foo = \(sign)1000000.000000_1"
            ]
        },
        corrections: NumberSeparatorRule.corrections
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        return violatingRanges(file).map { range, _ in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }

    private func violatingRanges(_ file: File) -> [(NSRange, String)] {
        let numberTokens = file.syntaxMap.tokens.filter { SyntaxKind(rawValue: $0.type) == .number }
        return numberTokens.flatMap { token in
            guard let content = contentFrom(file: file, token: token),
                isDecimal(number: content) else {
                    return nil
            }

            let signs = CharacterSet(charactersIn: "+-")
            guard let nonSign = content.components(separatedBy: signs).last,
                case let exponentialComponents = nonSign.components(separatedBy: "e"),
                let nonExponential = exponentialComponents.first else {
                    return nil
            }

            let components = nonExponential.components(separatedBy: ".")

            var validFraction = true
            var expectedFraction: String?
            if components.count == 2, let fractionSubstring = components.last {
                let result = isValid(number: fractionSubstring, reversed: false)
                validFraction = result.0
                expectedFraction = result.1
            }

            guard let integerSubstring = components.first,
                case let (valid, expected) = isValid(number: integerSubstring, reversed: true),
                !valid || !validFraction,
                let range = file.contents.bridge().byteRangeToNSRange(start: token.offset,
                                                                      length: token.length) else {
                    return nil
            }

            var corrected = ""
            let hasSign = content.countOfLeadingCharacters(in: signs) == 1
            if hasSign {
                corrected += String(content.characters.prefix(1))
            }

            corrected += expected
            if let fraction = expectedFraction {
                corrected += "." + fraction
            }

            if exponentialComponents.count == 2, let exponential = exponentialComponents.last {
                corrected += "e" + exponential
            }

            return (range, corrected)
        }
    }

    public func correctFile(_ file: File) -> [Correction] {
        let ranges = violatingRanges(file).filter { range, _ in
            return !file.ruleEnabledViolatingRanges([range], forRule: self).isEmpty
        }

        return writeToFile(file, violatingRanges: ranges)
    }

    private func writeToFile(_ file: File, violatingRanges: [(NSRange, String)]) -> [Correction] {
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
        let prefixes = ["0x", "0o", "0b"].flatMap { [$0, "-" + $0, "+" + $0] }

        return prefixes.filter { lowercased.hasPrefix($0) }.isEmpty
    }

    private func isValid(number: String, reversed: Bool) -> (Bool, String) {
        var correctComponents = [String]()
        let clean = number.replacingOccurrences(of: "_", with: "")

        for (idx, char) in reversedIfNeeded(Array(clean.characters),
                                            reversed: reversed).enumerated() {
            if idx % 3 == 0 && idx > 0 {
                correctComponents.append("_")
            }

            correctComponents.append(String(char))
        }

        let expected = reversedIfNeeded(correctComponents, reversed: reversed).joined()
        return (expected == number, expected)
    }

    private func reversedIfNeeded<T>(_ array: [T], reversed: Bool) -> [T] {
        if reversed {
            return array.reversed()
        }

        return array
    }

    private func contentFrom(file: File, token: SyntaxToken) -> String? {
        return file.contents.bridge().substringWithByteRange(start: token.offset,
                                                             length: token.length)
    }
}
