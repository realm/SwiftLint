import SourceKittenFramework

public struct FirstWhereRule: CallPairRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "first_where",
        name: "First Where",
        description: "Prefer using `.first(where:)` over `.filter { }.first` in collections.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier\n"),
            Example("myList.first(where: { $0 % 2 == 0 })\n"),
            Example("match(pattern: pattern).filter { $0.first == .identifier }\n"),
            Example("(myList.filter { $0 == 1 }.suffix(2)).first\n"),
            Example("collection.filter(\"stringCol = '3'\").first"),
            Example("realm?.objects(User.self).filter(NSPredicate(format: \"email ==[c] %@\", email)).first"),
            Example("if let pause = timeTracker.pauses.filter(\"beginDate < %@\", beginDate).first { print(pause) }")
        ],
        triggeringExamples: [
            Example("↓myList.filter { $0 % 2 == 0 }.first\n"),
            Example("↓myList.filter({ $0 % 2 == 0 }).first\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first\n"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()\n"),
            Example("↓myList.filter(someFunction).first\n"),
            Example("↓myList.filter({ $0 % 2 == 0 })\n.first\n"),
            Example("(↓myList.filter { $0 == 1 }).first\n"),
            Example("↓myListOfDict.filter { dict in dict[\"1\"] }.first"),
            Example("↓myListOfDict.filter { $0[\"someString\"] }.first")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(
            file: file,
            pattern: "[\\}\\)]\\s*\\.first",
            patternSyntaxKinds: [.identifier],
            callNameSuffix: ".filter",
            severity: configuration.severity
        ) { dictionary in
            if
                dictionary.substructure.isNotEmpty &&
                dictionary.substructure.last?.expressionKind != .argument &&
                dictionary.substructure.last?.name != "NSPredicate"
            {
                return true // has a substructure, like a closure
            }

            guard let bodyRange = dictionary.bodyByteRange else {
                return true
            }

            let syntaxKinds = file.syntaxMap.kinds(inByteRange: bodyRange)
            let isStringKeyDict = syntaxKinds == [.identifier, .keyword, .identifier, .string]
            let isStringKeyShortenedDict = syntaxKinds == [.identifier, .string]
            return  isStringKeyDict || isStringKeyShortenedDict || !syntaxKinds.contains(.string)
        }
    }
}
