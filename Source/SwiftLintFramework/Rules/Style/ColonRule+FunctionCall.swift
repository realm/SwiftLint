import Foundation
import SourceKittenFramework

extension ColonRule {
    internal func functionCallColonViolationRanges(in file: File,
                                                   dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            var ranges: [NSRange] = []
            if let kindString = subDict.kind,
                let kind = KindType(rawValue: kindString) {
                    ranges += functionCallColonViolationRanges(in: file, kind: kind, dictionary: subDict)
            }
            ranges += functionCallColonViolationRanges(in: file, dictionary: subDict)
            return ranges
        }
    }

    internal func functionCallColonViolationRanges(in file: File, kind: SwiftExpressionKind,
                                                   dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .argument,
            let ranges = functionCallColonRanges(dictionary: dictionary) else {
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

    private func functionCallColonRanges(dictionary: [String: SourceKitRepresentable]) -> [NSRange]? {
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
