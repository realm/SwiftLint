import SourceKittenFramework

struct VerticalParameterAlignmentOnCallRule: ASTRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "vertical_parameter_alignment_on_call",
        name: "Vertical Parameter Alignment on Call",
        description: "Function parameters should be aligned vertically if they're in multiple lines in a method call.",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            foo(param1: 1, param2: bar
                param3: false, param4: true)
            """),
            Example("""
            foo(param1: 1, param2: bar)
            """),
            Example("""
            foo(param1: 1, param2: bar
                param3: false,
                param4: true)
            """),
            Example("""
            foo(
               param1: 1
            ) { _ in }
            """),
            Example("""
            UIView.animate(withDuration: 0.4, animations: {
                blurredImageView.alpha = 1
            }, completion: { _ in
                self.hideLoading()
            })
            """),
            Example("""
            UIView.animate(withDuration: 0.4, animations: {
                blurredImageView.alpha = 1
            },
            completion: { _ in
                self.hideLoading()
            })
            """),
            Example("""
            foo(param1: 1, param2: { _ in },
                param3: false, param4: true)
            """),
            Example("""
            foo({ _ in
                   bar()
               },
               completion: { _ in
                   baz()
               }
            )
            """),
            Example("""
            foo(param1: 1, param2: [
               0,
               1
            ], param3: 0)
            """),
            Example("""
            myFunc(foo: 0,
                   bar: baz == 0)
            """)
        ],
        triggeringExamples: [
            Example("""
            foo(param1: 1, param2: bar
                            ↓param3: false, param4: true)
            """),
            Example("""
            foo(param1: 1, param2: bar
             ↓param3: false, param4: true)
            """),
            Example("""
            foo(param1: 1, param2: bar
                   ↓param3: false,
                   ↓param4: true)
            """),
            Example("""
            foo(param1: 1,
                   ↓param2: { _ in })
            """),
            Example("""
            foo(param1: 1,
                param2: { _ in
            }, param3: 2,
             ↓param4: 0)
            """),
            Example("""
            foo(param1: 1, param2: { _ in },
                   ↓param3: false, param4: true)
            """),
            Example("""
            myFunc(foo: 0,
                    ↓bar: baz == 0)
            """)
        ]
    )

    func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call,
            case let arguments = dictionary.enclosedArguments,
            arguments.count > 1,
            let firstArgumentOffset = arguments.first?.offset,
            case let contents = file.stringView,
            var firstArgumentPosition = contents.lineAndCharacter(forByteOffset: firstArgumentOffset) else {
                return []
        }

        var visitedLines = Set<Int>()
        var previousArgumentWasMultiline = false

        let lastIndex = arguments.count - 1
        let violatingOffsets: [ByteCount] = arguments.enumerated().compactMap { idx, argument in
            defer {
                previousArgumentWasMultiline = isMultiline(argument: argument, file: file)
            }

            guard let offset = argument.offset,
                let (line, character) = contents.lineAndCharacter(forByteOffset: offset),
                line > firstArgumentPosition.line else {
                    return nil
            }

            let (firstVisit, _) = visitedLines.insert(line)
            guard character != firstArgumentPosition.character && firstVisit else {
                return nil
            }

            // if this is the first element on a new line after a closure with multiple lines,
            // we reset the reference position
            if previousArgumentWasMultiline && firstVisit {
                firstArgumentPosition = (line, character)
                return nil
            }

            // never trigger on a trailing closure
            if idx == lastIndex, isTrailingClosure(dictionary: dictionary, file: file) {
                return nil
            }

            return offset
        }

        return violatingOffsets.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func isMultiline(argument: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let offset = argument.bodyOffset,
            let length = argument.bodyLength,
            case let contents = file.stringView,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: offset),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: offset + length)
        else {
            return false
        }

        return endLine > startLine
    }

    private func isTrailingClosure(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            case let start = min(offset, offset + length - 1),
            case let byteRange = ByteRange(location: start, length: length),
            let text = file.stringView.substringWithByteRange(byteRange)
        else {
            return false
        }

        return !text.hasSuffix(")")
    }
}
