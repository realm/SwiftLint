import Foundation
import SourceKittenFramework

public struct HashValueOverflowRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "hash_value_overflow",
        name: "HashValue Overflow",
        description: "This computation might trigger an overflow. Consider using `&+` or `&*` instead.",
        kind: .lint,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            """
            struct Foo: Hashable {
                let bar: Int = 10
                let baz: String = "baz"
                let xyz = 100

                public var hashValue: Int {
                    return bar &+ baz.hashValue &* bar - xyz
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

                public var ↓hashValue: Int {
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
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - Private

    private func violationRanges(in file: File,
                                 kind: SwiftDeclarationKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .varInstance, dictionary.name == "hashValue",
            let length = dictionary.length,
            let offset = dictionary.offset,
            case let nsstring = file.contents.bridge(),
            let range = nsstring.byteRangeToNSRange(start: offset, length: length)
            else {
                return []
        }
        let pattern = "hashValue\\s*:\\s*Int\\s*\\{([^{}]|[\\n\\r])*" +
        "(\\{([^{}]|[\\n\\r])*\\}([^{}]|[\\n\\r])*)*?[^{}&][+*]"

        return file.match(pattern: pattern, range: range).map { $0.0 }
    }
}
