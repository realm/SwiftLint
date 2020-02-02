import Foundation
import SourceKittenFramework

public struct MultilineArgumentsBracketsRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_arguments_brackets",
        name: "Multiline Arguments Brackets",
        description: "Multiline arguments should have their surrounding brackets in a new line.",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            foo(param1: "Param1", param2: "Param2", param3: "Param3")
            """),
            Example("""
            foo(
                param1: "Param1", param2: "Param2", param3: "Param3"
            )
            """),
            Example("""
            func foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"
            )
            """),
            Example("""
            foo { param1, param2 in
                print("hello world")
            }
            """),
            Example("""
            foo(
                bar(
                    x: 5,
                    y: 7
                )
            )
            """),
            Example("""
            AlertViewModel.AlertAction(title: "some title", style: .default) {
                AlertManager.shared.presentNextDebugAlert()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            foo(↓param1: "Param1", param2: "Param2",
                     param3: "Param3"
            )
            """),
            Example("""
            foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"↓)
            """),
            Example("""
            foo(↓bar(
                x: 5,
                y: 7
            )
            )
            """),
            Example("""
            foo(
                bar(
                    x: 5,
                    y: 7
            )↓)
            """)
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let bodyRange = dictionary.bodyByteRange,
            let range = file.stringView.byteRangeToNSRange(bodyRange)
        else {
            return []
        }

        let body = file.contents.substring(from: range.location, length: range.length)
        let isMultiline = body.contains("\n")
        guard isMultiline else {
            return []
        }

        let expectedBodyBeginRegex = regex("\\A(?:[ \\t]*\\n|[^\\n]*(?:in|\\{)\\n)")
        let expectedBodyEndRegex = regex("\\n[ \\t]*\\z")

        var violatingByteOffsets = [ByteCount]()
        if expectedBodyBeginRegex.firstMatch(in: body, options: [], range: body.fullNSRange) == nil {
            violatingByteOffsets.append(bodyRange.location)
        }

        if expectedBodyEndRegex.firstMatch(in: body, options: [], range: body.fullNSRange) == nil {
            violatingByteOffsets.append(bodyRange.upperBound)
        }

        return violatingByteOffsets.map { byteOffset in
            StyleViolation(
                ruleDescription: type(of: self).description, severity: configuration.severity,
                location: Location(file: file, byteOffset: byteOffset)
            )
        }
    }
}
