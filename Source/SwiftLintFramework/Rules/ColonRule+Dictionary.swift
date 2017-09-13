//
//  ColonRule+Dictionary.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 09/13/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension ColonRule {

    internal func dictionaryColonViolationRanges(in file: File,
                                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard configuration.applyToDictionaries else {
            return []
        }

        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            guard let kindString = subDict.kind,
                let kind = KindType(rawValue: kindString) else {
                    return []
            }
            return dictionaryColonViolationRanges(in: file, dictionary: subDict) +
                dictionaryColonViolationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }

    internal func dictionaryColonViolationRanges(in file: File, kind: SwiftExpressionKind,
                                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .dictionary,
            let ranges = dictionaryColonRanges(dictionary: dictionary) else {
                return []
        }

        let contents = file.contents.bridge()
        return ranges.filter {
            guard let colon = contents.substringWithByteRange(start: $0.location, length: $0.length) else {
                return false
            }

            if configuration.flexibleRightSpacing {
                let isCorrect = colon.hasPrefix(": ") || colon.hasPrefix(":\n")
                return !isCorrect
            }

            return colon != ": " && !colon.hasPrefix(":\n")
        }
    }

    private func dictionaryColonRanges(dictionary: [String: SourceKitRepresentable]) -> [NSRange]? {
        let elements = dictionary.elements
        guard elements.count % 2 == 0 else {
            return nil
        }

        let expectedKind = "source.lang.swift.structure.elem.expr"
        let ranges: [NSRange] = elements.flatMap { subDict in
            guard subDict.kind == expectedKind,
                let offset = subDict.offset,
                let length = subDict.length else {
                    return nil
            }

            return NSRange(location: offset, length: length)
        }

        let even = ranges.enumerated().flatMap { $0 % 2 == 0 ? $1 : nil }
        let odd = ranges.enumerated().flatMap { $0 % 2 != 0 ? $1 : nil }

        return zip(even, odd).map { evenRange, oddRange -> NSRange in
            let location = NSMaxRange(evenRange)
            let length = oddRange.location - location

            return NSRange(location: location, length: length)
        }
    }
}
