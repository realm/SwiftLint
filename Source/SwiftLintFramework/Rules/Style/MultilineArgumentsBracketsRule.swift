import Foundation
import SourceKittenFramework

public struct MultilineArgumentsBracketsRule: ASTRule, OptInRule, ConfigurationProviderRule {
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
            """),
            Example("""
            views.append(ViewModel(title: "MacBook", subtitle: "M1", action: { [weak self] in
                print("action tapped")
            }))
            """, excludeFromDocumentation: true),
            Example("""
            public final class Logger {
                public static let shared = Logger(outputs: [
                    OSLoggerOutput(),
                    ErrorLoggerOutput()
                ])
            }
            """),
            Example("""
            let errors = try self.download([
                (description: description, priority: priority),
            ])
            """),
            Example("""
            return SignalProducer({ observer, _ in
                observer.sendCompleted()
            }).onMainQueue()
            """),
            Example("""
            SomeType(a: [
                1, 2, 3
            ], b: [1, 2])
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
            foo(↓param1: "Param1",
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
            """),
            Example("""
            SomeOtherType(↓a: [
                    1, 2, 3
                ],
                b: "two"↓)
            """),
            Example("""
            views.append(ViewModel(
                title: "MacBook", subtitle: "M1", action: { [weak self] in
                print("action tapped")
            }↓))
            """, excludeFromDocumentation: true)
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

        let callBody = file.contents.substring(from: range.location, length: range.length)

        let parameters = dictionary.substructure.filter {
            // Argument expression types that can contain newlines
            [.argument, .array, .dictionary, .closure, .call].contains($0.expressionKind)
        }
        let parameterBodies = parameters.compactMap { $0.content(in: file) }
        let parametersNewlineCount = parameterBodies.map { body in
            return body.countOccurrences(of: "\n")
        }.reduce(0, +)
        let callNewlineCount = callBody.countOccurrences(of: "\n")
        let isMultiline = callNewlineCount > parametersNewlineCount

        guard isMultiline else {
            return []
        }

        let expectedBodyBeginRegex = regex("\\A(?:[ \\t]*\\n|[^\\n]*(?:in|\\{)\\n)")
        let expectedBodyEndRegex = regex("\\n[ \\t]*\\z")

        var violatingByteOffsets = [ByteCount]()
        if expectedBodyBeginRegex.firstMatch(in: callBody, options: [], range: callBody.fullNSRange) == nil {
            violatingByteOffsets.append(bodyRange.location)
        }

        if expectedBodyEndRegex.firstMatch(in: callBody, options: [], range: callBody.fullNSRange) == nil {
            violatingByteOffsets.append(bodyRange.upperBound)
        }

        return violatingByteOffsets.map { byteOffset in
            StyleViolation(
                ruleDescription: Self.description, severity: configuration.severity,
                location: Location(file: file, byteOffset: byteOffset)
            )
        }
    }
}
