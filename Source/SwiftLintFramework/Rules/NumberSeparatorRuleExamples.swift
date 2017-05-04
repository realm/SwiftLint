//
//  NumberSeparatorRuleExamples.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/29/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

internal struct NumberSeparatorRuleExamples {

    static let nonTriggeringExamples: [String] = {
        return ["-", "+", ""].flatMap { (sign: String) -> [String] in
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
        }
    }()

    static let triggeringExamples = makeTriggeringExamples(signs: ["↓-", "+↓", "↓"])

    static let corrections = makeCorrections(signs: [("↓-", "-"), ("+↓", "+"), ("↓", "")])

    private static func makeTriggeringExamples(signs: [String]) -> [String] {
        return signs.flatMap { (sign: String) -> [String] in
            [
                "let foo = \(sign)10_0",
                "let foo = \(sign)1000",
                "let foo = \(sign)1000e2",
                "let foo = \(sign)1000E2",
                "let foo = \(sign)1__000",
                "let foo = \(sign)1.0001",
                "let foo = \(sign)1_000_000.000000_1",
                "let foo = \(sign)1000000.000000_1"
            ]
        }
    }

    private static func makeCorrections(signs: [(String, String)]) -> [String: String] {
        var result = [String: String]()

        for (violation, sign) in signs {
            result["let foo = \(violation)10_0"] = "let foo = \(sign)100"
            result["let foo = \(violation)1000"] = "let foo = \(sign)1_000"
            result["let foo = \(violation)1000e2"] = "let foo = \(sign)1_000e2"
            result["let foo = \(violation)1000E2"] = "let foo = \(sign)1_000E2"
            result["let foo = \(violation)1__000"] = "let foo = \(sign)1_000"
            result["let foo = \(violation)1.0001"] = "let foo = \(sign)1.000_1"
            result["let foo = \(violation)1_000_000.000000_1"] = "let foo = \(sign)1_000_000.000_000_1"
            result["let foo = \(violation)1000000.000000_1"] = "let foo = \(sign)1_000_000.000_000_1"
        }

        return result
    }

}
