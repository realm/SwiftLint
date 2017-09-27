//
//  NoExtensionAccessModifier.swift
//  SwiftLint
//
//  Created by Samuel Susla on 09/1/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NoExplicitBooleanComparisonRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_explicit_boolean_comparison",
        name: "No Explicit Boolean Comparision",
        description: "",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "if a {}",
            "if !a {}",
            "guard a { return }",
            "guard !a else { return }"
        ],
        triggeringExamples: [
            "if b == 7 &&\n↓a == true {}",
            "if ↓a == true {}",
            "if ↓a == false {}",
            "if ↓a != true {}",
            "if ↓a != false {}",
            "if ↓true == a {}",
            "if ↓true != a {}",
            "if ↓false == a {}",
            "if ↓false != a {}",
            "guard ↓a == true else { return }",
            "guard ↓true == a else { return }",
            "guard ↓a != true else { return }",
            "guard ↓true != a else { return }",
            "guard ↓a == false else { return }",
            "guard ↓false == a else { return }",
            "guard ↓a != false else { return }",
            "guard ↓false != a else { return }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let rightHand = "\\w\\s(==|!=)\\s(true|false)"
        let leftHand = "(true|false)\\s(==|!=)\\s\\w"
        let ranges = file.match(pattern: rightHand,
                                with: [.identifier, .keyword]) +
                     file.match(pattern: leftHand,
                                with: [.keyword, .identifier])

        let contents = file.contents.bridge()
        let structure = file.structure

        let violatingLocations: [Int] = ranges.flatMap {
            guard let bodyByteRange = contents.NSRangeToByteRange(start: $0.location,
                                                                  length: $0.length)
                else {
                    return nil
            }

            if methodCall(for: bodyByteRange, dictionary: structure.dictionary) {
                return bodyByteRange.location
            } else {
                return nil
            }
        }

        return violatingLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func methodCall(for range: NSRange,
                            dictionary: [String: SourceKitRepresentable]) -> Bool {
        let kind = "source.lang.swift.structure.elem.condition_expr"
        if let kindString = (dictionary.kind),
            kindString == kind,
            let length = dictionary.length,
            let offset = dictionary.offset {
            let byteRange = NSRange(location: offset, length: length)
            return NSLocationInRange(range.location, byteRange)
        }

        for element in dictionary.elements {
            return methodCall(for: range, dictionary: element)
        }

        for dictionary in dictionary.substructure {
            return methodCall(for: range, dictionary: dictionary)
        }

        return false
    }

}
