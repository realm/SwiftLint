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
            """),
            Example("""
            SomeType(
              a: 1
            ) { print("completion") }
            """),
            Example("""
            SomeType(
              a: 1
            ) {
              print("completion")
            }
            """),
            Example("""
            SomeType(
              a: .init() { print("completion") }
            )
            """),
            Example("""
            SomeType(
              a: .init() {
                print("completion")
              }
            )
            """),
            Example("""
            SomeType(
              a: 1
            ) {} onError: {}
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
            SomeOtherType(
              a: 1↓) {}
            """),
            Example("""
            SomeOtherType(
              a: 1↓) {
              print("completion")
            }
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

        let trailingClosurePattern = "\\) \\{[^\\}]*\\z"
        let trailingClosureRegex = regex(trailingClosurePattern)

        let expectedBodyBeginRegex = regex("\\A(?:[ \\t]*\\n|[^\\n]*(?:in|\\{)\\n)")
        let expectedBodyEndRegex = regex("\\n[ \\t]*\\z")
        let expectedTrailingClosureBodyEndRegex = regex("\\n[ \\t]*\\) \\{.*\\z")

        // Should only ever be ")" when the call doesn't have a trailing closure, or "}" when it does.
        let followingCharacter = file.contents.substring(from: range.location + range.length, length: 1)

        var violatingByteOffsets = [ByteCount]()
        if expectedBodyBeginRegex.firstMatch(in: callBody, options: [], range: callBody.fullNSRange) == nil {
            violatingByteOffsets.append(bodyRange.location)
        }

        if followingCharacter == ")",
           expectedBodyEndRegex.firstMatch(in: callBody, range: callBody.fullNSRange) == nil {
            violatingByteOffsets.append(bodyRange.upperBound)
        } else if followingCharacter == "}",
                  expectedTrailingClosureBodyEndRegex.firstMatch(in: callBody, range: callBody.fullNSRange) == nil {
            if let match = trailingClosureRegex.firstMatch(in: callBody, range: callBody.fullNSRange) {
                let matchFileLocation = range.location + match.range.location
                let offset = file.stringView.byteOffset(fromLocation: matchFileLocation)
                violatingByteOffsets.append(offset)
            } else {
                violatingByteOffsets.append(bodyRange.upperBound)
            }
        }

        return violatingByteOffsets.map { byteOffset in
            StyleViolation(
                ruleDescription: Self.description, severity: configuration.severity,
                location: Location(file: file, byteOffset: byteOffset)
            )
        }
    }
}
