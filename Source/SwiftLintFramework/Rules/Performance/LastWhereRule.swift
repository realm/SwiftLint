import SourceKittenFramework

public struct LastWhereRule: CallPairRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "last_where",
        name: "Last Where",
        description: "Prefer using `.last(where:)` over `.filter { }.last` in collections.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.last == .identifier\n"),
            Example("myList.last(where: { $0 % 2 == 0 })\n"),
            Example("match(pattern: pattern).filter { $0.last == .identifier }\n"),
            Example("(myList.filter { $0 == 1 }.suffix(2)).last\n"),
            Example("collection.filter(\"stringCol = '3'\").last")
        ],
        triggeringExamples: [
            Example("↓myList.filter { $0 % 2 == 0 }.last\n"),
            Example("↓myList.filter({ $0 % 2 == 0 }).last\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last?.something()\n"),
            Example("↓myList.filter(someFunction).last\n"),
            Example("↓myList.filter({ $0 % 2 == 0 })\n.last\n"),
            Example("(↓myList.filter { $0 == 1 }).last\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(file: file,
                        pattern: "[\\}\\)]\\s*\\.last",
                        patternSyntaxKinds: [.identifier],
                        callNameSuffix: ".filter",
                        severity: configuration.severity) { dictionary in
            let substructure: [SourceKittenDictionary] = {
                if SwiftVersion.current >= .fiveDotSix {
                    return dictionary.substructure.flatMap { dict -> [SourceKittenDictionary] in
                        if dict.expressionKind == .argument {
                            return dict.substructure
                        }
                        return [dict]
                    }
                }

                return dictionary.substructure
            }()
            if substructure.isNotEmpty {
                return true // has a substructure, like a closure
            }

            guard let bodyRange = dictionary.bodyByteRange else {
                return true
            }

            let syntaxKinds = file.syntaxMap.kinds(inByteRange: bodyRange)
            return !syntaxKinds.contains(.string)
        }
    }
}
