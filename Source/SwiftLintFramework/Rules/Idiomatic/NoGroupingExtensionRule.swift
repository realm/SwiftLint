import SourceKittenFramework

public struct NoGroupingExtensionRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_grouping_extension",
        name: "No Grouping Extension",
        description: "Extensions shouldn't be used to group code within the same source file.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "protocol Food {}\nextension Food {}\n",
            "class Apples {}\nextension Oranges {}\n",
            "class Box<T> {}\nextension Box where T: Vegetable {}\n"
        ],
        triggeringExamples: [
            "enum Fruit {}\n↓extension Fruit {}\n",
            "↓extension Tea: Error {}\nstruct Tea {}\n",
            "class Ham { class Spam {}}\n↓extension Ham.Spam {}\n",
            "extension External { struct Gotcha {}}\n↓extension External.Gotcha {}\n"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let collector = NamespaceCollector(dictionary: file.structureDictionary)
        let elements = collector.findAllElements(of: [.class, .enum, .struct, .extension])

        let susceptibleNames = Set(elements.compactMap { $0.kind != .extension ? $0.name : nil })

        return elements.compactMap { element in
            guard element.kind == .extension, susceptibleNames.contains(element.name) else {
                return nil
            }

            guard !hasWhereClause(dictionary: element.dictionary, file: file) else {
                return nil
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: element.offset))
        }
    }

    private func hasWhereClause(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        let contents = file.linesContainer

        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyOffset = dictionary.bodyOffset else {
            return false
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = bodyOffset - rangeStart

        guard let range = contents.byteRangeToNSRange(start: rangeStart, length: rangeLength) else {
            return false
        }

        return !file.match(pattern: "\\bwhere\\b", with: [.keyword], range: range).isEmpty
    }
}
