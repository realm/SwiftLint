import SourceKittenFramework

extension ColonRule {
    internal func dictionaryColonViolationRanges(in file: SwiftLintFile,
                                                 dictionary: SourceKittenDictionary) -> [ByteRange] {
        guard configuration.applyToDictionaries else {
            return []
        }

        let ranges: [ByteRange] = dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return dictionaryColonViolationRanges(in: file, kind: kind, dictionary: subDict)
        }

        return ranges.unique
    }

    internal func dictionaryColonViolationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                                 dictionary: SourceKittenDictionary) -> [ByteRange] {
        guard kind == .dictionary,
            let ranges = dictionaryColonRanges(dictionary: dictionary) else {
                return []
        }

        let contents = file.stringView
        return ranges.filter {
            guard let colon = contents.substringWithByteRange($0) else {
                return false
            }

            if configuration.flexibleRightSpacing {
                let isCorrect = colon.hasPrefix(": ") || colon.hasPrefix(":\n")
                return !isCorrect
            }

            return colon != ": " && !colon.hasPrefix(":\n")
        }
    }

    private func dictionaryColonRanges(dictionary: SourceKittenDictionary) -> [ByteRange]? {
        let elements = dictionary.elements
        guard elements.count % 2 == 0 else {
            return nil
        }

        let expectedKind = "source.lang.swift.structure.elem.expr"
        let ranges: [ByteRange] = elements.compactMap { subDict in
            guard subDict.kind == expectedKind else {
                return nil
            }

            return subDict.byteRange
        }

        let even = ranges.enumerated().compactMap { $0 % 2 == 0 ? $1 : nil }
        let odd = ranges.enumerated().compactMap { $0 % 2 != 0 ? $1 : nil }

        return zip(even, odd).map { evenRange, oddRange -> ByteRange in
            let location = evenRange.upperBound
            let length = oddRange.location - location
            return ByteRange(location: location, length: length)
        }
    }
}
