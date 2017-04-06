//
//  RedundantDiscardableLetRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/25/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct RedundantDiscardableLetRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_discardable_let",
        name: "Redundant Discardable Let",
        description: "Prefer `_ = foo()` over `let _ = foo()` when discarding a result from a function.",
        nonTriggeringExamples: [
            "_ = foo()\n",
            "if let _ = foo() { }\n",
            "guard let _ = foo() else { return }\n",
            "let _: ExplicitType = foo()"
        ],
        triggeringExamples: [
            "↓let _ = foo()\n",
            "if _ = foo() { ↓let _ = bar() }\n"
        ],
        corrections: [
            "↓let _ = foo()\n": "_ = foo()\n",
            "if _ = foo() { ↓let _ = bar() }\n": "if _ = foo() { _ = bar() }\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: "_")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {
        let contents = file.contents.bridge()
        return file.match(pattern: "let\\s+_\\b", with: [.keyword, .keyword]).filter { range in
            guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length) else {
                return false
            }

            return !isInBooleanCondition(byteOffset: byteRange.location,
                                         dictionary: file.structure.dictionary)
                && !hasExplicitType(utf16Range: range.location ..< range.location + range.length,
                                    fileContents: contents)
        }
    }

    private func isInBooleanCondition(byteOffset: Int, dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard let offset = dictionary.offset,
            let byteRange = dictionary.length.map({ NSRange(location: offset, length: $0) }),
            NSLocationInRange(byteOffset, byteRange) else {
                return false
        }

        if let kind = dictionary.kind.flatMap(StatementKind.init), kind == .if || kind == .guard {
            let conditionKind = "source.lang.swift.structure.elem.condition_expr"
            for element in dictionary.elements where element.kind == conditionKind {
                guard let elementOffset = element.offset,
                    let elementRange = element.length.map({ NSRange(location: elementOffset, length: $0) }),
                    NSLocationInRange(byteOffset, elementRange) else {
                        continue
                }

                return true
            }
        }

        for subDict in dictionary.substructure where
            isInBooleanCondition(byteOffset: byteOffset, dictionary: subDict) {
                return true
        }

        return false
    }

    private func hasExplicitType(utf16Range: Range<Int>, fileContents: NSString) -> Bool {
        guard utf16Range.upperBound != fileContents.length else {
            return false
        }
        let nextUTF16Unit = fileContents.substring(with: NSRange(location: utf16Range.upperBound, length: 1))
        return nextUTF16Unit == ":"
    }

}
