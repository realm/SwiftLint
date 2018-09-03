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
                    ↓"bar": 2,
                "fizz": 2,
            ↓"buzz": 2
            ])
            """
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .dictionary || kind == .array else { return [] }

        let keyElements: [[String: SourceKitRepresentable]]
        if kind == .array {
            keyElements = dictionary.elements
        } else {
            // in a dictionary, only even elements are keys
            keyElements = zip(dictionary.elements, 0...).compactMap { element, index in
                index % 2 == 0 ? element : nil
            }
        }

        let contents = file.contents.bridge()
        let keyLocations = keyElements.compactMap { element -> Location? in
            guard let byteOffset = element.offset,
                let (line, character) = contents.lineAndCharacter(forByteOffset: byteOffset) else {
                return nil
            }
            return Location(file: file.path, line: line, character: character)
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
}

extension CollectionAlignmentRule {
    struct Examples {

    }
}
