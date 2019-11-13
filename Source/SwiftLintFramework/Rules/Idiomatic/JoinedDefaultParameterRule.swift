import Foundation
import SourceKittenFramework

public struct JoinedDefaultParameterRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule, OptInRule,
                                          AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "joined_default_parameter",
        name: "Joined Default Parameter",
        description: "Discouraged explicit usage of the default separator.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "let foo = bar.joined()",
            "let foo = bar.joined(separator: \",\")",
            "let foo = bar.joined(separator: toto)"
        ],
        triggeringExamples: [
            "let foo = bar.joined(↓separator: \"\")",
            """
            let foo = bar.filter(toto)
                         .joined(↓separator: ""),
            """,
            """
            func foo() -> String {
              return ["1", "2"].joined(↓separator: "")
            }
            """
        ],
        corrections: [
            "let foo = bar.joined(↓separator: \"\")": "let foo = bar.joined()",
            "let foo = bar.filter(toto)\n.joined(↓separator: \"\")": "let foo = bar.filter(toto)\n.joined()",
            "func foo() -> String {\n   return [\"1\", \"2\"].joined(↓separator: \"\")\n}":
                "func foo() -> String {\n   return [\"1\", \"2\"].joined()\n}",
            "class C {\n#if true\nlet foo = bar.joined(↓separator: \"\")\n#endif\n}":
                "class C {\n#if true\nlet foo = bar.joined()\n#endif\n}"
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableASTRule

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
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
            let offset = argument.offset,
            let length = argument.length,
            argument.name == "separator"
            else { return [] }

        guard
            // is this single argument the default parameter?
            let bodyOffset = argument.bodyOffset,
            let bodyLength = argument.bodyLength,
            let body = file.linesContainer.substringWithByteRange(start: bodyOffset, length: bodyLength),
            body == "\"\""
            else { return [] }

        guard
            let range = file.linesContainer.byteRangeToNSRange(start: offset, length: length)
            else { return [] }

        return [range]
    }
}
