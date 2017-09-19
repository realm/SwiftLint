//
//  ContainsOverFirstNotNilRule.swift
//  SwiftLint
//
//  Created by Samuel Susla on 17/09/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ContainsOverFirstNotNilRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_first_not_nil",
        name: "Contains over first not nil",
        description: "Prefer `contains` over `first(where:) != nil`",
        kind: .performance,
        nonTriggeringExamples: [
            "let first = myList.first(where: { $0 % 2 == 0 })\n",
            "let first = myList.first { $0 % 2 == 0 }\n"
        ],
        triggeringExamples: [
            "↓myList.first { $0 % 2 == 0 } != nil\n",
            "↓myList.first(where: { $0 % 2 == 0 }) != nil\n",
            "↓myList.map { $0 + 1 }.first(where: { $0 % 2 == 0 }) != nil\n",
            "↓myList.first(where: someFunction) != nil\n",
            "↓myList.map { $0 + 1 }.first { $0 % 2 == 0 } != nil\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "[\\}\\)]\\s*!=\\s*nil"
        let firstRanges = file.match(pattern: pattern, with: [.keyword])
        let contents = file.contents.bridge()
        let structure = file.structure

        let violatingLocations: [Int] = firstRanges.flatMap { range in
            guard let bodyByteRange = contents.NSRangeToByteRange(start: range.location,
                                                                  length: range.length),
                case let firstLocation = range.location + range.length - 1,
                let firstByteRange = contents.NSRangeToByteRange(start: firstLocation, length: 1)
                else {
                    return nil
            }

            return methodCall(forByteOffset: bodyByteRange.location - 1,
                              excludingOffset: firstByteRange.location, dictionary: structure.dictionary,
                              predicate: { dictionary in
                guard let name = dictionary.name else {
                    return false
                }

                return name.hasSuffix(".first")
            })
        }

        return violatingLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func methodCall(forByteOffset byteOffset: Int, excludingOffset: Int,
                            dictionary: [String: SourceKitRepresentable],
                            predicate: ([String: SourceKitRepresentable]) -> Bool) -> Int? {

        if let kindString = dictionary.kind,
            SwiftExpressionKind(rawValue: kindString) == .call,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let offset = dictionary.offset {
            let byteRange = NSRange(location: bodyOffset, length: bodyLength)

            if NSLocationInRange(byteOffset, byteRange) &&
                !NSLocationInRange(excludingOffset, byteRange) && predicate(dictionary) {
                return offset
            }
        }

        for dictionary in dictionary.substructure {
            if let offset = methodCall(forByteOffset: byteOffset,
                                       excludingOffset: excludingOffset,
                                       dictionary: dictionary,
                                       predicate: predicate) {
                return offset
            }
        }

        return nil
    }
}
