import SourceKittenFramework

struct DiscouragedOptionalCollectionRule: ASTRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "discouraged_optional_collection",
        name: "Discouraged Optional Collection",
        description: "Prefer empty collection over optional collection",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalCollectionExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalCollectionExamples.triggeringExamples
    )

    func validate(file: SwiftLintFile,
                  kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let offsets = variableViolations(kind: kind, dictionary: dictionary) +
            functionViolations(file: file, kind: kind, dictionary: dictionary)

        return offsets.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    // MARK: - Private

    private func variableViolations(kind: SwiftDeclarationKind, dictionary: SourceKittenDictionary) -> [ByteCount] {
        guard
            SwiftDeclarationKind.variableKinds.contains(kind),
            let offset = dictionary.offset,
            let typeName = dictionary.typeName else { return [] }

        return typeName.optionalCollectionRanges().map { _ in offset }
    }

    private func functionViolations(file: SwiftLintFile,
                                    kind: SwiftDeclarationKind,
                                    dictionary: SourceKittenDictionary) -> [ByteCount] {
        guard
            SwiftDeclarationKind.functionKinds.contains(kind),
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let length = dictionary.length,
            let offset = dictionary.offset,
            case let start = nameOffset + nameLength,
            case let end = dictionary.bodyOffset ?? offset + length,
            case let byteRange = ByteRange(location: start, length: end - start),
            case let contents = file.stringView,
            let range = file.stringView.byteRangeToNSRange(byteRange),
            let match = file.match(pattern: "->\\s*(.*?)\\{", excludingSyntaxKinds: excludingKinds, range: range).first
            else { return [] }

        return contents.substring(with: match).optionalCollectionRanges().map { _ in nameOffset }
    }

    private let excludingKinds = SyntaxKind.allKinds.subtracting([.typeidentifier])
}

private extension String {
    /// Ranges of optional collections within the bounds of the string.
    ///
    /// Example: [String: [Int]?]
    ///
    ///         [  S  t  r  i  n  g  :     [  I  n  t  ]  ?  ]
    ///         0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
    ///                                    ^              ^
    /// = [9, 14]
    /// = [9, 15), mathematical interval, w/ lower and upper bounds.
    ///
    /// Example: [String: [Int]?]?
    ///
    ///         [  S  t  r  i  n  g  :     [  I  n  t  ]  ?  ]  ?
    ///         0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16
    ///         ^                          ^              ^     ^
    /// = [0, 16], [9, 14]
    /// = [0, 17), [9, 15), mathematical interval, w/ lower and upper bounds.
    ///
    /// Example: var x = Set<Int>?
    ///
    ///         v  a  r     x     =     S  e  t  <  I  n  t  >  ?
    ///         0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16
    ///                                 ^                       ^
    /// = [8, 16]
    /// = [8, 17), mathematical interval, w/ lower and upper bounds.
    ///
    /// - returns: An array of ranges.
    func optionalCollectionRanges() -> [Range<String.Index>] {
        let squareBrackets = balancedRanges(from: "[", to: "]").compactMap { range -> Range<String.Index>? in
            guard
                range.upperBound < endIndex,
                let finalIndex = index(range.upperBound, offsetBy: 1, limitedBy: endIndex),
                self[range.upperBound] == "?" else { return nil }

            return range.lowerBound..<finalIndex
        }

        let angleBrackets = balancedRanges(from: "<", to: ">").compactMap { range -> Range<String.Index>? in
            guard
                range.upperBound < endIndex,
                let initialIndex = index(range.lowerBound, offsetBy: -3, limitedBy: startIndex),
                let finalIndex = index(range.upperBound, offsetBy: 1, limitedBy: endIndex),
                self[initialIndex..<range.lowerBound] == "Set",
                self[range.upperBound] == "?" else { return nil }

            return initialIndex..<finalIndex
        }

        return squareBrackets + angleBrackets
    }

    /// Indices of character within the bounds of the string.
    ///
    /// Example:
    ///         a m a n h a
    ///         0 1 2 3 4 5
    ///         ^   ^     ^
    /// = [0, 2, 5]
    ///
    /// - parameter character: The character to look for.
    /// - returns: Array of indices.
    private func indices(of character: Character) -> [String.Index] {
        return indices.compactMap { self[$0] == character ? $0 : nil }
    }

    /// Ranges of balanced substrings.
    ///
    /// Example:
    ///
    /// ```
    /// ((1+2)*(3+4))
    /// (  (  1  +  2  )  *  (  3  +  4  )  )
    /// 0  1  2  3  4  5  6  7  8  9  10 11 12
    /// ^ ^            ^     ^           ^  ^
    /// = [0, 12], [1, 5], [7, 11]
    /// = [0, 13), [1, 6), [7, 12), mathematical interval, w/ lower and upper bounds.
    /// ```
    ///
    /// - parameter prefix: The prefix to look for.
    /// - parameter suffix: The suffix to look for.
    ///
    /// - returns: Array of ranges of balanced substrings.
    private func balancedRanges(from prefix: Character, to suffix: Character) -> [Range<String.Index>] {
        return indices(of: prefix).compactMap { prefixIndex in
            var pairCount = 0
            var currentIndex = prefixIndex
            var foundCharacter = false

            while currentIndex < endIndex {
                let character = self[currentIndex]
                currentIndex = index(after: currentIndex)

                if character == prefix { pairCount += 1 }
                if character == suffix { pairCount -= 1 }
                if pairCount != 0 { foundCharacter = true }
                if pairCount == 0 && foundCharacter { break }
            }

            return pairCount == 0 && foundCharacter ? prefixIndex..<currentIndex : nil
        }
    }
}
