import Foundation
import SourceKittenFramework

public struct LastWhereRule: CallPairRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "last_where",
        name: "Last Where",
        description: "Prefer using `.last(where:)` over `.filter { }.last` in collections.",
        kind: .performance,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "kinds.filter(excludingKinds.contains).isEmpty && kinds.last == .identifier\n",
            "myList.last(where: { $0 % 2 == 0 })\n",
            "match(pattern: pattern).filter { $0.last == .identifier }\n",
            "(myList.filter { $0 == 1 }.suffix(2)).last\n",
            "collection.filter(\"stringCol = '3'\").last"
        ],
        triggeringExamples: [
            "↓myList.filter { $0 % 2 == 0 }.last\n",
            "↓myList.filter({ $0 % 2 == 0 }).last\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last?.something()\n",
            "↓myList.filter(someFunction).last\n",
            "↓myList.filter({ $0 % 2 == 0 })\n.last\n",
            "(↓myList.filter { $0 == 1 }).last\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file,
                        pattern: "[\\}\\)]\\s*\\.last",
                        patternSyntaxKinds: [.identifier],
                        callNameSuffix: ".filter",
                        severity: configuration.severity) { dictionary in
            if !dictionary.substructure.isEmpty {
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
