import Foundation
import SourceKittenFramework

extension ColonRule {
    internal func functionCallColonViolationRanges(in file: SwiftLintFile,
                                                   dictionary: SourceKittenDictionary) -> [NSRange] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return functionCallColonViolationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }

    internal func functionCallColonViolationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                                   dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .argument,
            let ranges = functionCallColonRanges(dictionary: dictionary) else {
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

    private func functionCallColonRanges(dictionary: SourceKittenDictionary) -> [NSRange]? {
        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength, nameLength > 0,
            let bodyOffset = dictionary.bodyOffset,
            case let location = nameOffset + nameLength,
            bodyOffset > location else {
                return nil
        }

        return [NSRange(location: location, length: bodyOffset - location)]
    }
}
