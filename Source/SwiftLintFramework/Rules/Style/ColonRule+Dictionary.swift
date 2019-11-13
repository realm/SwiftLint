import Foundation
import SourceKittenFramework

extension ColonRule {
    internal func dictionaryColonViolationRanges(in file: SwiftLintFile,
                                                 dictionary: SourceKittenDictionary) -> [NSRange] {
        guard configuration.applyToDictionaries else {
            return []
        }

        let ranges: [NSRange] = dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return dictionaryColonViolationRanges(in: file, kind: kind, dictionary: subDict)
        }

        return ranges.unique
    }

    internal func dictionaryColonViolationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                                 dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .dictionary,
            let ranges = dictionaryColonRanges(dictionary: dictionary) else {
                return []
        }

        let contents = file.linesContainer
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

    private func dictionaryColonRanges(dictionary: SourceKittenDictionary) -> [NSRange]? {
        let elements = dictionary.elements
        guard elements.count % 2 == 0 else {
            return nil
        }

        let expectedKind = "source.lang.swift.structure.elem.expr"
        let ranges: [NSRange] = elements.compactMap { subDict in
            guard subDict.kind == expectedKind,
                let offset = subDict.offset,
                let length = subDict.length else {
                    return nil
            }

            return NSRange(location: offset, length: length)
        }

        let even = ranges.enumerated().compactMap { $0 % 2 == 0 ? $1 : nil }
        let odd = ranges.enumerated().compactMap { $0 % 2 != 0 ? $1 : nil }

        return zip(even, odd).map { evenRange, oddRange -> NSRange in
            let location = NSMaxRange(evenRange)
            let length = oddRange.location - location

            return NSRange(location: location, length: length)
        }
    }
}
