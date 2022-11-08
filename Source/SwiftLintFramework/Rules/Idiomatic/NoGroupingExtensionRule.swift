import SourceKittenFramework

struct NoGroupingExtensionRule: OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "no_grouping_extension",
        name: "No Grouping Extension",
        description: "Extensions shouldn't be used to group code within the same source file.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("protocol Food {}\nextension Food {}\n"),
            Example("class Apples {}\nextension Oranges {}\n"),
            Example("class Box<T> {}\nextension Box where T: Vegetable {}\n")
        ],
        triggeringExamples: [
            Example("enum Fruit {}\n↓extension Fruit {}\n"),
            Example("↓extension Tea: Error {}\nstruct Tea {}\n"),
            Example("class Ham { class Spam {}}\n↓extension Ham.Spam {}\n"),
            Example("extension External { struct Gotcha {}}\n↓extension External.Gotcha {}\n")
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
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

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: element.offset))
        }
    }

    private func hasWhereClause(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyOffset = dictionary.bodyOffset,
            case let contents = file.stringView,
            case let rangeStart = nameOffset + nameLength,
            case let rangeLength = bodyOffset - rangeStart,
            let range = contents.byteRangeToNSRange(ByteRange(location: rangeStart, length: rangeLength))
        else {
            return false
        }

        return file.match(pattern: "\\bwhere\\b", with: [.keyword], range: range).isNotEmpty
    }
}
