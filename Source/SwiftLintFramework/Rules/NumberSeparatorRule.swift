//
//  NumberSeparatorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 05/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NumberSeparatorRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "number_separator",
        name: "Number Separator",
        description: "Underscores should be used as thousand separator in large decimal numbers.",
        nonTriggeringExamples: [
            "let foo = 100",
            "let foo = 1_000",
            "let foo = 1_000_000",
            "let foo = 1.000_1",
            "let foo = 1_000_000.000_000_1",
            "let binary = 0b10000",
            "let binary = 0b1000_0001",
            "let hex = 0xA",
            "let hex = 0xAA_BB",
            "let octal = 0o21",
            "let octal = 0o21_1",
            "let octal = -0o21_1",
            "let exp = 1_000_000.000_000e2",
            "let negative = -1_000_000.000_000",
            "let positive = +1_000_000.000_000"
        ],
        triggeringExamples: [
            "let foo = ↓10_0",
            "let foo = ↓1000",
            "let foo = ↓1__000",
            "let foo = ↓1.0001",
            "let foo = ↓1_000_000.000000_1",
            "let foo = ↓1000000.000000_1"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let numberTokens = file.syntaxMap.tokens.filter { SyntaxKind(rawValue: $0.type) == .number }
        let violations = numberTokens.filter { token in
            guard let content = contentFrom(file: file, token: token),
                isDecimal(number: content) else {
                    return false
            }

            let signals = CharacterSet(charactersIn: "+-")
            guard let nonSignal = content.components(separatedBy: signals).first,
                let nonExponential = nonSignal.components(separatedBy: "e").first else {
                return false
            }

            let components = nonExponential.components(separatedBy: ".")
            if let integerSubstring = components.first,
                !isValid(number: integerSubstring, reversed: true) {
                return true
            }

            if components.count == 2, let fractionSubstring = components.last,
                !isValid(number: fractionSubstring, reversed: false) {
                return true
            }

            return false
        }.map { token in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: token.offset))
        }

        return violations
    }

    private func isDecimal(number: String) -> Bool {
        let lowercased = number.lowercased()
        let prefixes = ["0x", "0o", "0b"].flatMap { [$0, "-" + $0] }

        return prefixes.filter { lowercased.hasPrefix($0) }.isEmpty
    }

    private func isValid(number: String, reversed: Bool) -> Bool {
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
        return expected == number
    }

    private func reversedIfNeeded<T>(_ array: [T], reversed: Bool) -> [T] {
        if reversed {
            return array.reversed()
        }

        return array
    }

    private func contentFrom(file: File, token: SyntaxToken) -> String? {
        return file.contents.substringWithByteRange(start: token.offset, length: token.length)
    }
}
