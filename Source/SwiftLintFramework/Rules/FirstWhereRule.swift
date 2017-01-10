//
//  FirstWhereRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct FirstWhereRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "first_where",
        name: "First Where",
        description: "Prefer using `.first(where:)` over `.filter { }.first` in collections.",
        nonTriggeringExamples: [
            "kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier\n",
            "myList.first(where: { $0 % 2 == 0 })\n",
            "match(pattern: pattern).filter { $0.first == .identifier }\n"
        ],
        triggeringExamples: [
            "↓myList.filter { $0 % 2 == 0 }.first\n",
            "↓myList.filter({ $0 % 2 == 0 }).first\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()\n",
            "↓myList.filter(someFunction).first\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "[\\s\\}\\)]*\\.first"
        let firstRanges = file.match(pattern: pattern, with: [.identifier])
        let contents = file.contents.bridge()
        let structure = file.structure

        let violatingLocations: [Int] = firstRanges.flatMap {
            guard let bodyByteRange = contents.NSRangeToByteRange(start: $0.location,
                                                                  length: $0.length),
                case let firstLocation = $0.location + $0.length - 1,
                let firstByteRange = contents.NSRangeToByteRange(start: firstLocation,
                                                                 length: 1) else {
                return nil
            }

            return methodCall(forByteOffset: bodyByteRange.location - 1, excludingOffset: firstByteRange.location,
                              dictionary: structure.dictionary, predicate: { dictionary in
                guard let name = dictionary["key.name"] as? String else {
                    return false
                }

                return name.hasSuffix(".filter")
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

        if let kindString = (dictionary["key.kind"] as? String),
            SwiftExpressionKind(rawValue: kindString) == .call,
            let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }),
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            let byteRange = NSRange(location: bodyOffset, length: bodyLength)

            if NSLocationInRange(byteOffset, byteRange) &&
                !NSLocationInRange(excludingOffset, byteRange) && predicate(dictionary) {
                return offset
            }
        }

        for dictionary in dictionary.substructure {
            if let offset = methodCall(forByteOffset: byteOffset, excludingOffset: excludingOffset,
                                       dictionary: dictionary, predicate: predicate) {
                return offset
            }
        }

        return nil
    }
}
