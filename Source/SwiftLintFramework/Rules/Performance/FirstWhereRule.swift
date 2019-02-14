import Foundation
import SourceKittenFramework

public struct FirstWhereRule: CallPairRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "first_where",
        name: "First Where",
        description: "Prefer using `.first(where:)` over `.filter { }.first` in collections.",
        kind: .performance,
        nonTriggeringExamples: [
            "kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier\n",
            "myList.first(where: { $0 % 2 == 0 })\n",
            "match(pattern: pattern).filter { $0.first == .identifier }\n",
            "(myList.filter { $0 == 1 }.suffix(2)).first\n",
            "collection.filter(\"stringCol = '3'\").first",
            "realm?.objects(User.self).filter(NSPredicate(format: \"email ==[c] %@\", email)).first",
            "if let pause = timeTracker.pauses.filter(\"beginDate < %@\", beginDate).first { print(pause) }"
        ],
        triggeringExamples: [
            "↓myList.filter { $0 % 2 == 0 }.first\n",
            "↓myList.filter({ $0 % 2 == 0 }).first\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()\n",
            "↓myList.filter(someFunction).first\n",
            "↓myList.filter({ $0 % 2 == 0 })\n.first\n",
            "(↓myList.filter { $0 == 1 }).first\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validate(
            file: file,
            pattern: "[\\}\\)]\\s*\\.first",
            patternSyntaxKinds: [.identifier],
            callNameSuffix: ".filter",
            severity: configuration.severity
        ) { dictionary in
            if
                !dictionary.substructure.isEmpty &&
                dictionary.substructure.last?.kind.flatMap(SwiftExpressionKind.init) != .argument &&
                dictionary.substructure.last?.name != "NSPredicate"
            {
                return true // has a substructure, like a closure
            }

            guard let bodyOffset = dictionary.bodyOffset, let bodyLength = dictionary.bodyLength else {
                return true
            }

            let syntaxKinds = file.syntaxMap.kinds(inByteRange: NSRange(location: bodyOffset, length: bodyLength))
            return !syntaxKinds.contains(.string)
        }
    }
}
