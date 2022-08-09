import Foundation
import SourceKittenFramework

public struct JoinedDefaultParameterRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "joined_default_parameter",
        name: "Joined Default Parameter",
        description: "Discouraged explicit usage of the default separator.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let foo = bar.joined()"),
            Example("let foo = bar.joined(separator: \",\")"),
            Example("let foo = bar.joined(separator: toto)")
        ],
        triggeringExamples: [
            Example("let foo = bar.joined(↓separator: \"\")"),
            Example("""
            let foo = bar.filter(toto)
                         .joined(↓separator: ""),
            """),
            Example("""
            func foo() -> String {
              return ["1", "2"].joined(↓separator: "")
            }
            """)
        ],
        corrections: [
            Example("let foo = bar.joined(↓separator: \"\")"): Example("let foo = bar.joined()"),
            Example("let foo = bar.filter(toto)\n.joined(↓separator: \"\")"):
                Example("let foo = bar.filter(toto)\n.joined()"),
            Example("func foo() -> String {\n   return [\"1\", \"2\"].joined(↓separator: \"\")\n}"):
                Example("func foo() -> String {\n   return [\"1\", \"2\"].joined()\n}"),
            Example("class C {\n#if true\nlet foo = bar.joined(↓separator: \"\")\n#endif\n}"):
                Example("class C {\n#if true\nlet foo = bar.joined()\n#endif\n}")
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableASTRule

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard
            // is it calling a method '.joined' and passing a single argument?
            kind == .call,
            dictionary.name?.hasSuffix(".joined") == true,
            dictionary.enclosedArguments.count == 1
            else { return [] }

        guard
            // is this single argument called 'separator'?
            let argument = dictionary.enclosedArguments.first,
            let argumentByteRange = argument.byteRange,
            argument.name == "separator",
            let argumentNSRange = file.stringView.byteRangeToNSRange(argumentByteRange)
            else { return [] }

        guard
            // is this single argument the default parameter?
            let bodyRange = argument.bodyByteRange,
            let body = file.stringView.substringWithByteRange(bodyRange),
            body == "\"\""
            else { return [] }

        return [argumentNSRange]
    }
}
