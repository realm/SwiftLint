//
//  CallPairRule.swift
//  SwiftLint
//
//  Created by Tom Quist on 11/07/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

internal protocol CallPairRule: Rule {}

extension CallPairRule {

    /**
     Validates the given file for pairs of expressions where the first part of the expression
     is a method call (with or without parameters) having the given `callNameSuffix` and the
     second part is some expression matching the given pattern which is looked up in expressions
     of the given syntax kind.
     
     Example:
     ```
     .someMethodCall(someParams: param).someExpression
     \_____________/                  \______________/
      callNameSuffix                      pattern
     ```
     
     - parameters:
        - file: The file to validate
        - pattern: Regular expression which matches the second part of the expression
        - patternSyntaxKinds: Syntax kinds matches should have
        - callNameSuffix: Suffix of the first method call name
        - severity: Severity of violations
     */
    internal func validate(file: File,
                           pattern: String,
                           patternSyntaxKinds: [SyntaxKind],
                           callNameSuffix: String,
                           severity: ViolationSeverity) -> [StyleViolation] {
        let firstRanges = file.match(pattern: pattern, with: patternSyntaxKinds)
        let contents = file.contents.bridge()
        let structure = file.structure

        let violatingLocations: [Int] = firstRanges.compactMap { range in
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
