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
            """
            foo(param1: "Param1", param2: "Param2", param3: "Param3")
            """,
            """
            foo(
                param1: "Param1", param2: "Param2", param3: "Param3"
            )
            """,
            """
            func foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"
            )
            """,
            """
            foo { param1, param2 in
                print("hello world")
            }
            """,
            """
            foo(
                bar(
                    x: 5,
                    y: 7
                )
            )
            """,
            """
            AlertViewModel.AlertAction(title: "some title", style: .default) {
                AlertManager.shared.presentNextDebugAlert()
            }
            """
        ],
        triggeringExamples: [
            """
            foo(↓param1: "Param1", param2: "Param2",
                     param3: "Param3"
            )
            """,
            """
            foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"↓)
            """,
            """
            foo(↓bar(
                x: 5,
                y: 7
            )
            )
            """,
            """
            foo(
                bar(
                    x: 5,
                    y: 7
            )↓)
            """
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let range = file.linesContainer.byteRangeToNSRange(start: bodyOffset, length: bodyLength)
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

        var violatingByteOffsets = [Int]()
        if expectedBodyBeginRegex.firstMatch(in: body, options: [], range: body.fullNSRange) == nil {
            violatingByteOffsets.append(bodyOffset)
        }

        if expectedBodyEndRegex.firstMatch(in: body, options: [], range: body.fullNSRange) == nil {
            violatingByteOffsets.append(bodyOffset + bodyLength)
        }

        return violatingByteOffsets.map { byteOffset in
            StyleViolation(
                ruleDescription: type(of: self).description, severity: configuration.severity,
                location: Location(file: file, byteOffset: byteOffset)
            )
        }
    }
}
