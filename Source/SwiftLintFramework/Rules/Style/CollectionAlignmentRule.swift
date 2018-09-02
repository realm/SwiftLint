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
                ↓"foo": 1,
                    "bar": 2
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
        let (lines, characters) = keyElements.reduce((Set<Int>(), Set<Int>())) { result, element in
            guard let offset = element.offset,
                let (line, character) = contents.lineAndCharacter(forByteOffset: offset)
                else { return result }
            return (result.0.union([line]), result.1.union([character]))
        }

        guard lines.count > 1, !characters.isEmpty else {
            return []
        }

        let firstLine = lines.sorted(by: <).first
        let firstCharacter = characters.sorted(by: <).first
        let location = Location(file: file.path, line: firstLine, character: firstCharacter)

        guard lines.count == keyElements.count else {
            let reason = "Elements in a collection literal should each be on their own line, except when all elements are on the same line."
            return [makeViolation(for: location, reason: reason)]
        }

        guard characters.count == 1 else {
            let reason = "Elements in a collection literal should have the same indentation."
            return [makeViolation(for: location, reason: reason)]
        }

        return []
    }

    private func makeViolation(for location: Location, reason: String) -> StyleViolation {
        return StyleViolation(ruleDescription: CollectionAlignmentRule.description,
                              severity: configuration.severityConfiguration.severity,
                              location: location,
                              reason: reason)
    }
}

extension CollectionAlignmentRule {
    struct Examples {

    }
}
