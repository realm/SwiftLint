import SourceKittenFramework

public struct CollectionAlignmentRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = CollectionAlignmentConfiguration()

    public init() {}

    public static var description = RuleDescription(
        identifier: "collection_alignment",
        name: "Alignment of Collection Elements",
        description: "All elements in a collection literal should be vertically aligned",
        kind: .style,
        nonTriggeringExamples: [
            """
            someFunction(arg: [
                "foo": 1,
                "bar": 2
            ])
            """
        ],
        triggeringExamples: [
            """
            someFunction(arg: [
                "foo": 1,
                    "bar"↓: 2,
                "fizz": 2,
            "buzz"↓: 2
            ])
            """
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .dictionary || kind == .array else { return [] }

        let keyLocations: [Location]
        if kind == .array {
            keyLocations = getArrayElementLocations(with: file, dictionary: dictionary)
        } else {
            keyLocations = getDictionaryKeyLocations(with: file, dictionary: dictionary)
        }

        guard keyLocations.count >= 2 else {
            return []
        }

        let firstKeyLocation = keyLocations[0]
        let violationLocations = zip(keyLocations[1...], 1...)
            .compactMap { location, index -> Location? in
                let previousLocation = keyLocations[index - 1]
                if previousLocation.line! < location.line! && firstKeyLocation.character! != location.character! {
                    return location
                } else {
                    return nil
                }
            }

        return violationLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: $0)
        }
    }

    private func getArrayElementLocations(with file: File, dictionary: [String: SourceKitRepresentable]) -> [Location] {
        let contents = file.contents.bridge()
        return dictionary.elements.compactMap { element -> Location? in
            guard let byteOffset = element.offset,
                let (line, character) = contents.lineAndCharacter(forByteOffset: byteOffset) else {
                return nil
            }
            return Location(file: file.path, line: line, character: character)
        }
    }

    private func getDictionaryKeyLocations(with file: File,
                                           dictionary: [String: SourceKitRepresentable]) -> [Location] {
        var keys: [[String: SourceKitRepresentable]] = []
        var values: [[String: SourceKitRepresentable]] = []
        zip(dictionary.elements, 0...).forEach { element, index in
            // in a dictionary, the even elements are keys, and the odd elements are values
            if index % 2 == 0 {
                keys.append(element)
            } else {
                values.append(element)
            }
        }

        return zip(keys, values).compactMap { key, value -> Location? in
            guard let keyOffset = key.offset,
                let valueOffset = value.offset,
                let keyLength = key.length else { return nil }

            if configuration.alignColons {
                return getColonLocation(with: file,
                                        keyOffset: keyOffset,
                                        keyLength: keyLength,
                                        valueOffset: valueOffset)
            } else {
                return getKeyLocation(with: file, keyOffset: keyOffset)
            }
        }
    }

    private func getColonLocation(with file: File, keyOffset: Int, keyLength: Int, valueOffset: Int) -> Location? {
        let contents = file.contents.bridge()
        let matchStart = keyOffset + keyLength
        let matchLength = valueOffset - matchStart
        let range = contents.byteRangeToNSRange(start: matchStart, length: matchLength)

        guard let colonRange = file.match(pattern: ":", range: range).first?.0,
            let (line, character) = contents.lineAndCharacter(forCharacterOffset: colonRange.location)
            else { return nil }

        return Location(file: file.path, line: line, character: character)
    }

    private func getKeyLocation(with file: File, keyOffset: Int) -> Location? {
        guard let (line, character) = file.contents.lineAndCharacter(forByteOffset: keyOffset) else { return nil }
        return Location(file: file.path, line: line, character: character)
    }
}

extension CollectionAlignmentRule {
    struct Examples {

    }
}
