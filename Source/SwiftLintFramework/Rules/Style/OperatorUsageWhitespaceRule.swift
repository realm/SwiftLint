import Foundation
import SourceKittenFramework
import SwiftSyntax

public struct OperatorUsageWhitespaceRule: OptInRule, CorrectableRule, ConfigurationProviderRule,
                                           AutomaticTestableRule {
    public var configuration = OperatorUsageWhitespaceConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "operator_usage_whitespace",
        name: "Operator Usage Whitespace",
        description: "Operators should be surrounded by a single whitespace " + "when they are being used.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = 1 + 2\n"),
            Example("let foo = 1 > 2\n"),
            Example("let foo = !false\n"),
            Example("let foo: Int?\n"),
            Example("let foo: Array<String>\n"),
            Example("let model = CustomView<Container<Button>, NSAttributedString>()\n"),
            Example("let foo: [String]\n"),
            Example("let foo = 1 + \n  2\n"),
            Example("let range = 1...3\n"),
            Example("let range = 1 ... 3\n"),
            Example("let range = 1..<3\n"),
            Example("#if swift(>=3.0)\n    foo()\n#endif\n"),
            Example("array.removeAtIndex(-200)\n"),
            Example("let name = \"image-1\"\n"),
            Example("button.setImage(#imageLiteral(resourceName: \"image-1\"), for: .normal)\n"),
            Example("let doubleValue = -9e-11\n"),
            Example("let foo = GenericType<(UIViewController) -> Void>()\n"),
            Example("let foo = Foo<Bar<T>, Baz>()\n"),
            Example("let foo = SignalProducer<Signal<Value, Error>, Error>([ self.signal, next ]).flatten(.concat)\n"),
            Example("\"let foo =  1\""),
            Example("""
              enum Enum {
              case hello   = 1
              case hello2  = 1
              }
            """),
            Example("""
            let something = Something<GenericParameter1,
                                      GenericParameter2>()
            """ ),
            Example("""
            return path.flatMap { path in
                return compileCommands[path] ??
                    compileCommands[path.path(relativeTo: FileManager.default.currentDirectoryPath)]
            }
            """),
            Example("""
            internal static func == (lhs: Vertix, rhs: Vertix) -> Bool {
                return lhs.filePath == rhs.filePath
                    && lhs.originalRemoteString == rhs.originalRemoteString
                    && lhs.rootDirectory == rhs.rootDirectory
            }
            """),
            Example("""
            internal static func == (lhs: Vertix, rhs: Vertix) -> Bool {
                return lhs.filePath == rhs.filePath &&
                    lhs.originalRemoteString == rhs.originalRemoteString &&
                    lhs.rootDirectory == rhs.rootDirectory
            }
            """),
            Example(#"""
            private static let pattern =
                "\\S\(mainPatternGroups)" + // Regexp will match if expression not begin with comma
                "|" +                       // or
                "\(mainPatternGroups)"      // Regexp will match if expression begins with comma
            """#),
            Example(#"""
            private static let pattern =
                "\\S\(mainPatternGroups)" + // Regexp will match if expression not begin with comma
                "|"                       + // or
                "\(mainPatternGroups)"      // Regexp will match if expression begins with comma
            """#)
        ],
        triggeringExamples: [
            Example("let foo = 1↓+2\n"),
            Example("let foo = 1↓   + 2\n"),
            Example("let foo = 1↓   +    2\n"),
            Example("let foo = 1↓ +    2\n"),
            Example("let foo↓=1↓+2\n"),
            Example("let foo↓=1 + 2\n"),
            Example("let foo↓=bar\n"),
            Example("let range = 1↓ ..<  3\n"),
            Example("let foo = bar↓   ?? 0\n"),
            Example("let foo = bar↓ !=  0\n"),
            Example("let foo = bar↓ !==  bar2\n"),
            Example("let v8 = Int8(1)↓  << 6\n"),
            Example("let v8 = 1↓ <<  (6)\n"),
            Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2\n"),
            Example("let foo↓  = [1]\n"),
            Example("let foo↓  = \"1\"\n"),
            Example("let foo↓ =  \"1\"\n"),
            Example("""
              enum Enum {
              case one↓  =  1
              case two  = 1
              }
            """),
            Example("""
              enum Enum {
              case one  = 1
              case two↓  =  1
              }
            """),
            Example("""
              enum Enum {
              case one↓   = 1
              case two↓  = 1
              }
            """)
        ],
        corrections: [
            Example("let foo = 1↓+2\n"): Example("let foo = 1 + 2\n"),
            Example("let foo = 1↓   + 2\n"): Example("let foo = 1 + 2\n"),
            Example("let foo = 1↓   +    2\n"): Example("let foo = 1 + 2\n"),
            Example("let foo = 1↓ +    2\n"): Example("let foo = 1 + 2\n"),
            Example("let foo↓=1↓+2\n"): Example("let foo = 1 + 2\n"),
            Example("let foo↓=1 + 2\n"): Example("let foo = 1 + 2\n"),
            Example("let foo↓=bar\n"): Example("let foo = bar\n"),
            Example("let range = 1↓ ..<  3\n"): Example("let range = 1..<3\n"),
            Example("let foo = bar↓   ?? 0\n"): Example("let foo = bar ?? 0\n"),
            Example("let foo = bar↓ !=  0\n"): Example("let foo = bar != 0\n"),
            Example("let foo = bar↓ !==  bar2\n"): Example("let foo = bar !== bar2\n"),
            Example("let v8 = Int8(1)↓  << 6\n"): Example("let v8 = Int8(1) << 6\n"),
            Example("let v8 = 1↓ <<  (6)\n"): Example("let v8 = 1 << (6)\n"),
            Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2\n"): Example("let v8 = 1 << (6)\n let foo = 1 > 2\n"),
            Example("let foo↓  = \"1\"\n"): Example("let foo = \"1\"\n"),
            Example("let foo↓ =  \"1\"\n"): Example("let foo = \"1\"\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(file: file).map { range, _ in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: range.location))
        }
    }

    private func violationRanges(file: SwiftLintFile) -> [(ByteRange, String)] {
        guard let syntaxTree = file.syntaxTree else {
            return []
        }

        let visitor = OperatorUsageWhitespaceVisitor()
        visitor.walk(syntaxTree)
        return visitor.violationRanges.filter { byteRange, _ in
            if configuration.skipAlignedConstants && isAlignedConstant(in: byteRange, file: file) {
                return false
            }

            return true
        }.sorted { lhs, rhs in
            lhs.0.location < rhs.0.location
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = violationRanges(file: file)
            .compactMap { byteRange, correction -> (NSRange, String)? in
                guard let range = file.stringView.byteRangeToNSRange(byteRange) else {
                    return nil
                }

                return (range, correction)
            }
            .filter { range, _ in
                return file.ruleEnabled(violatingRanges: [range], for: self).isNotEmpty
            }

        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for (violatingRange, correction) in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: correction)
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: Self.description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func isAlignedConstant(in byteRange: ByteRange, file: SwiftLintFile) -> Bool {
        // Make sure we have match with assignment operator and with spaces before it
        guard let matchedString = file.stringView.substringWithByteRange(byteRange) else {
            return false
        }
        let equalityOperatorRegex = regex("\\s+=\\s")

        guard let match = equalityOperatorRegex.firstMatch(
            in: matchedString,
            options: [],
            range: matchedString.fullNSRange),
              match.range == matchedString.fullNSRange
        else {
            return false
        }

        guard let (lineNumber, _) = file.stringView.lineAndCharacter(forByteOffset: byteRange.upperBound),
              case let lineIndex = lineNumber - 1, lineIndex >= 0 else {
            return false
        }

        // Find lines above and below with the same location of =
        let currentLine = file.stringView.lines[lineIndex].content
        let index = currentLine.firstIndex(of: "=")
        guard let offset = index.map({ currentLine.distance(from: currentLine.startIndex, to: $0) }) else {
            return false
        }

        // Look around for assignment operator in lines around
        let lineIndexesAround = (1...configuration.linesLookAround)
            .flatMap { [lineIndex + $0, lineIndex - $0] }

        func isValidIndex(_ idx: Int) -> Bool {
            return idx != lineIndex && idx >= 0 && idx < file.stringView.lines.count
        }

        for lineIndex in lineIndexesAround where isValidIndex(lineIndex) {
            let line = file.stringView.lines[lineIndex].content
            guard !line.isEmpty else { continue }
            let index = line.index(line.startIndex,
                                   offsetBy: offset,
                                   limitedBy: line.index(line.endIndex, offsetBy: -1))
            if index.map({ line[$0] }) == "=" {
                return true
            }
        }

        return false
    }
}

private class OperatorUsageWhitespaceVisitor: SyntaxVisitor {
    private(set) var violationRanges: [(ByteRange, String)] = []

    override func visitPost(_ node: BinaryOperatorExprSyntax) {
        guard let previousToken = node.previousToken,
              let nextToken = node.nextToken,
              let violation = violation(previousToken: previousToken,
                                        nextToken: nextToken,
                                        operatorToken: node.operatorToken) else {
            return
        }

        violationRanges.append(violation)
    }

    override func visitPost(_ node: InitializerClauseSyntax) {
        guard let previousToken = node.equal.previousToken,
              let nextToken = node.equal.nextToken,
              let violation = violation(previousToken: previousToken,
                                        nextToken: nextToken,
                                        operatorToken: node.equal) else {
            return
        }

        violationRanges.append(violation)
    }

    private func violation(
        previousToken: TokenSyntax,
        nextToken: TokenSyntax,
        operatorToken: TokenSyntax
    ) -> (ByteRange, String)? {
        let noSpacingBefore = previousToken.trailingTrivia.isEmpty && operatorToken.leadingTrivia.isEmpty
        let noSpacingAfter = operatorToken.trailingTrivia.isEmpty && nextToken.leadingTrivia.isEmpty
        let noSpacing = noSpacingBefore || noSpacingAfter

        let allowedNoSpacingOperators: Set = ["...", "..<"]

        let operatorText = operatorToken.withoutTrivia().text
        if noSpacing && allowedNoSpacingOperators.contains(operatorText) {
            return nil
        }

        let tooMuchSpacingBefore = previousToken.trailingTrivia.containsTooMuchWhitespacing
        let tooMuchSpacingAfter = operatorToken.trailingTrivia.containsTooMuchWhitespacing
        let tooMuchSpacing = (tooMuchSpacingBefore || tooMuchSpacingAfter) &&
                             !nextToken.leadingTrivia.containsComments

        guard noSpacing || tooMuchSpacing else {
            return nil
        }

        let location = ByteCount(previousToken.endPositionBeforeTrailingTrivia)
        let endPosition = ByteCount(nextToken.positionAfterSkippingLeadingTrivia)
        let range = ByteRange(
            location: location,
            length: endPosition - location
        )

        let correction = allowedNoSpacingOperators.contains(operatorText) ? operatorText : " \(operatorText) "
        return (range, correction)
    }
}

private extension Trivia {
    var containsTooMuchWhitespacing: Bool {
        return contains { element in
            guard case let .spaces(spaces) = element, spaces > 1 else {
                return false
            }

            return true
        }
    }

    var containsComments: Bool {
        return contains { element in
            switch element {
            case .blockComment, .docLineComment, .docBlockComment, .lineComment:
                return true
            case .carriageReturnLineFeeds, .carriageReturns, .formfeeds,
                 .garbageText, .newlines, .spaces, .verticalTabs, .tabs:
                return false
            }
        }
    }
}
