//
//  SortedFirstLastRule.swift
//  SwiftLint
//
//  Created by Tom Quist on 06.11.17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SortedFirstLastRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "sorted_first_last",
        name: "Min or Max over Sorted First or Last",
        description: "Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`",
        kind: .performance,
        nonTriggeringExamples: [
            "let min = myList.min()\n",
            "let min = myList.min(by: { $0 < $1 })\n",
            "let min = myList.min(by: >)\n",
            "let min = myList.max()\n",
            "let min = myList.max(by: { $0 < $1 })\n"
        ],
        triggeringExamples: [
            "↓myList.sorted().first\n",
            "↓myList.sorted(by: { $0.description < $1.description }).first\n",
            "↓myList.sorted(by: >).first\n",
            "↓myList.map { $0 + 1 }.sorted().first\n",
            "↓myList.sorted(by: someFunction).first\n",
            "↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.first\n",
            "↓myList.sorted().last\n",
            "↓myList.sorted().last?.something()\n",
            "↓myList.sorted(by: { $0.description < $1.description }).last\n",
            "↓myList.map { $0 + 1 }.sorted().last\n",
            "↓myList.sorted(by: someFunction).last\n",
            "↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.last\n"

        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "[\\}\\)]\\s*\\.(first|last)"
        let firstRanges = file.match(pattern: pattern, with: [.identifier])
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

                                return name.hasSuffix(".sorted")
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
            let bodyOffset = dictionary.offset,
            let bodyLength = dictionary.length,
            let offset = dictionary.offset {
            let byteRange = NSRange(location: bodyOffset, length: bodyLength == 0 ? 1 : bodyLength)

            if NSLocationInRange(byteOffset, byteRange),
                !NSLocationInRange(excludingOffset, byteRange),
                predicate(dictionary) {
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
