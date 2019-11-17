import Foundation
import SourceKittenFramework

public struct OptionalEnumCaseMatchingRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule,
                                            AutomaticTestableRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "optional_enum_case_matching",
        name: "Optional Enum Case Match",
        description: "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above. ",
        kind: .style,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            """
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """
        ],
        triggeringExamples: [
            """
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """
        ],
        corrections: [
            """
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """: """
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """: """
            switch foo {
             case Foo.bar: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """: """
            switch foo {
             case .bar, .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """: """
            switch foo {
             case .bar where x > 1: break
             case .baz: break
             default: break
            }
            """
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableASTRule

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: StatementKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard SwiftVersion.current >= type(of: self).description.minSwiftVersion, kind == .case else {
            return []
        }

        let contents = file.stringView
        return dictionary.elements
            .filter { $0.kind == "source.lang.swift.structure.elem.pattern" }
            .compactMap { dictionary in
                guard let offset = dictionary.offset, let length = dictionary.length else {
                    return nil
                }

                let tokens = file.syntaxMap
                    .tokens(inByteRange: NSRange(location: offset, length: length))
                    .prefix(while: { $0.kind != .keyword })

                guard let lastToken = tokens.last else {
                    return nil
                }

                let questionMarkByteOffset = lastToken.length + lastToken.offset
                guard contents.substringWithByteRange(start: questionMarkByteOffset, length: 1) == "?",
                    let range = contents.byteRangeToNSRange(start: questionMarkByteOffset, length: 1) else {
                    return nil
                }

                return range
            }
    }
}
