//
//  CallPairRule.swift
//  SwiftLint
//
//  Created by Tom Quist on 11/07/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol CallPairRule: Rule {}

extension CallPairRule {

    public func validate(file: File,
                         pattern: String,
                         patternSyntaxKind: [SyntaxKind],
                         callNameSuffix: String,
                         severity: ViolationSeverity) -> [StyleViolation] {
        let firstRanges = file.match(pattern: pattern, with: patternSyntaxKind)
        let contents = file.contents.bridge()
        let structure = file.structure

        let violatingLocations: [Int] = firstRanges.flatMap { range in
            guard let bodyByteRange = contents.NSRangeToByteRange(start: range.location,
                                                                  length: range.length),
                case let firstLocation = range.location + range.length - 1,
                let firstByteRange = contents.NSRangeToByteRange(start: firstLocation,
                                                                 length: 1) else {
                                                                    return nil
            }

            return methodCall(forByteOffset: bodyByteRange.location - 1,
                              excludingOffset: firstByteRange.location,
                              dictionary: structure.dictionary,
                              predicate: { dictionary in
                                guard let name = dictionary.name else {
                                    return false
                                }

                                return name.hasSuffix(callNameSuffix)
            })
        }

        return violatingLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: severity,
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
