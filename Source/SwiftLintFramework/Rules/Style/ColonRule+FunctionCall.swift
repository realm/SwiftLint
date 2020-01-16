import SourceKittenFramework

extension ColonRule {
    internal func functionCallColonViolationRanges(in file: SwiftLintFile,
                                                   dictionary: SourceKittenDictionary) -> [ByteRange] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return functionCallColonViolationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }

    internal func functionCallColonViolationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                                   dictionary: SourceKittenDictionary) -> [ByteRange] {
        guard kind == .argument,
            let ranges = functionCallColonRanges(dictionary: dictionary)
        else {
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

    private func functionCallColonRanges(dictionary: SourceKittenDictionary) -> [ByteRange]? {
        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength, nameLength > 0,
            let bodyOffset = dictionary.bodyOffset,
            case let location = nameOffset + nameLength,
            bodyOffset > location
        else {
            return nil
        }

        return [ByteRange(location: location, length: bodyOffset - location)]
    }
}
