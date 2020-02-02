import SourceKittenFramework

public struct CollectionAlignmentRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = CollectionAlignmentConfiguration()

    public init() {}

    public static var description = RuleDescription(
        identifier: "collection_alignment",
        name: "Collection Element Alignment",
        description: "All elements in a collection literal should be vertically aligned",
        kind: .style,
        nonTriggeringExamples: Examples(alignColons: false).nonTriggeringExamples,
        triggeringExamples: Examples(alignColons: false).triggeringExamples
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .dictionary || kind == .array else { return [] }

        let keyLocations: [Location]
        if kind == .array {
            keyLocations = arrayElementLocations(with: file, dictionary: dictionary)
        } else {
            keyLocations = dictionaryKeyLocations(with: file, dictionary: dictionary)
        }

        guard keyLocations.count >= 2 else {
            return []
        }

        let firstKeyLocation = keyLocations[0]
        let remainingKeyLocations = keyLocations[1...]
        let violationLocations = zip(remainingKeyLocations.indices, remainingKeyLocations)
            .compactMap { index, location -> Location? in
                let previousLocation = keyLocations[index - 1]
                guard let previousLine = previousLocation.line,
                    let locationLine = location.line,
                    let firstKeyCharacter = firstKeyLocation.character,
                    let locationCharacter = location.character,
                    previousLine < locationLine,
                    firstKeyCharacter != locationCharacter else { return nil }

                return location
            }

        return violationLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: $0)
        }
    }

    private func arrayElementLocations(with file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [Location] {
        return dictionary.elements.compactMap { element -> Location? in
            element.offset.map { Location(file: file, byteOffset: $0) }
        }
    }

    private func dictionaryKeyLocations(with file: SwiftLintFile,
                                        dictionary: SourceKittenDictionary) -> [Location] {
        var keys: [SourceKittenDictionary] = []
        var values: [SourceKittenDictionary] = []
        dictionary.elements.enumerated().forEach { index, element in
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
                return colonLocation(with: file,
                                     keyOffset: keyOffset,
                                     keyLength: keyLength,
                                     valueOffset: valueOffset)
            } else {
                return Location(file: file, byteOffset: keyOffset)
            }
        }
    }

    private func colonLocation(with file: SwiftLintFile, keyOffset: ByteCount, keyLength: ByteCount,
                               valueOffset: ByteCount) -> Location? {
        let contents = file.stringView
        let matchStart = keyOffset + keyLength
        let matchLength = valueOffset - matchStart
        let byteRange = ByteRange(location: matchStart, length: matchLength)
        let range = contents.byteRangeToNSRange(byteRange)

        let matches = file.match(pattern: ":", excludingSyntaxKinds: [.comment], range: range)
        return matches.first.map { Location(file: file, characterOffset: $0.location) }
    }
}

extension CollectionAlignmentRule {
    struct Examples {
        private let alignColons: Bool

        init(alignColons: Bool) {
            self.alignColons = alignColons
        }

        var triggeringExamples: [Example] {
            let examples = alignColons ? alignColonsTriggeringExamples : alignLeftTriggeringExamples
            return examples + sharedTriggeringExamples
        }

        var nonTriggeringExamples: [Example] {
            let examples = alignColons ? alignColonsNonTriggeringExamples : alignLeftNonTriggeringExamples
            return examples + sharedNonTriggeringExamples
        }

        private var alignColonsTriggeringExamples: [Example] {
            return [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                    "fizz"↓: 2,
                    "buzz"↓: 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                    "beta"↓: "b",
                    "gamma": "c",
                    "delta": "d",
                    "epsilon"↓: "e"
                ]
                """),
                Example("""
                var weirdColons = [
                    "a"    :  1,
                    "b"  ↓:2,
                    "c"    :      3
                ]
                """)
            ]
        }

        private var alignColonsNonTriggeringExamples: [Example] {
            return [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                   "fizz": 2,
                   "buzz": 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                     "beta": "b",
                    "gamma": "g",
                    "delta": "d",
                  "epsilon": "e"
                ]
                """),
                Example("""
                var weirdColons = [
                    "a"    :  1,
                      "b"  :2,
                       "c" :      3
                ]
                """)
            ]
        }

        private var alignLeftTriggeringExamples: [Example] {
            return [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                   ↓"fizz": 2,
                   ↓"buzz": 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                     ↓"beta": "b",
                    "gamma": "g",
                    "delta": "d",
                  ↓"epsilon": "e"
                ]
                """),
                Example("""
                let meals = [
                                "breakfast": "oatmeal",
                                "lunch": "sandwich",
                    ↓"dinner": "burger"
                ]
                """)
            ]
        }

        private var alignLeftNonTriggeringExamples: [Example] {
            return [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                    "fizz": 2,
                    "buzz": 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                    "beta": "b",
                    "gamma": "g",
                    "delta": "d",
                    "epsilon": "e"
                ]
                """),
                Example("""
                let meals = [
                                "breakfast": "oatmeal",
                                "lunch": "sandwich",
                                "dinner": "burger"
                ]
                """)
            ]
        }

        private var sharedTriggeringExamples: [Example] {
            return [
                Example("""
                let coordinates = [
                    CLLocationCoordinate2D(latitude: 0, longitude: 33),
                        ↓CLLocationCoordinate2D(latitude: 0, longitude: 66),
                    CLLocationCoordinate2D(latitude: 0, longitude: 99)
                ]
                """),
                Example("""
                var evenNumbers: Set<Int> = [
                    2,
                  ↓4,
                    6
                ]
                """)
            ]
        }

        private var sharedNonTriggeringExamples: [Example] {
            return [
                Example("""
                let coordinates = [
                    CLLocationCoordinate2D(latitude: 0, longitude: 33),
                    CLLocationCoordinate2D(latitude: 0, longitude: 66),
                    CLLocationCoordinate2D(latitude: 0, longitude: 99)
                ]
                """),
                Example("""
                var evenNumbers: Set<Int> = [
                    2,
                    4,
                    6
                ]
                """),
                Example("""
                let abc = [1, 2, 3, 4]
                """),
                Example("""
                let abc = [
                    1, 2, 3, 4
                ]
                """),
                Example("""
                let abc = [
                    "foo": "bar", "fizz": "buzz"
                ]
                """)
            ]
        }
    }
}
