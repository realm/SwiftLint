import Foundation
import SourceKittenFramework

public struct HashValueOverflowRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "hash_value_overflow",
        name: "HashValue Overflow",
        description: "This computation might trigger an overflow. " +
        "Consider using `func hash(into hasher: inout Hasher)` instead.",
        kind: .lint,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            """
            struct Foo: Hashable {
                let bar: Int = 10
                let baz: String = "baz"
                let xyz = 100

                func hash(into hasher: inout Hasher) {
                    hasher.combine(bar)
                    hasher.combine(baz)
                    hasher.combine(xyz)
                  }
            }
            """
        ],
        triggeringExamples: [
            """
            struct Foo: Hashable {
                let bar: Int = 10
                let baz: String = "baz"
                let xyz = 100

                public ↓var hashValue: Int {
                    return bar + baz.hashValue * bar - xyz
                }
            }
            """
        ]
    )

    // MARK: - ASTRule

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance,
            dictionary.name == "hashValue",
            let offset = dictionary.offset else {
            return []
        }

        func makeViolation() -> StyleViolation {
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }

        return [makeViolation()]
    }
}
