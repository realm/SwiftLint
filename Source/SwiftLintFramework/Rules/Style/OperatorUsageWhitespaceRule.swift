import Foundation
import SourceKittenFramework

public struct OperatorUsageWhitespaceRule: OptInRule, CorrectableRule, ConfigurationProviderRule,
                                           AutomaticTestableRule {
    public var configuration = OperatorUsageWhitespaceConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "operator_usage_whitespace",
        name: "Operator Usage Whitespace",
        description: "Operators should be surrounded by a single whitespace " +
                     "when they are being used.",
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
            """)
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
            Example("let foo = bar↓??0\n"),
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
            Example("let foo = bar↓??0\n"): Example("let foo = bar ?? 0\n"),
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
                           location: Location(file: file, characterOffset: range.location))
        }
    }

    private func violationRanges(file: SwiftLintFile) -> [(NSRange, String)] {
        let rangePattern = "\\.\\.(?:\\.|<)" // ... or ..<
        let notEqualsPattern = "\\!\\=\\=?" // != or !==
        let coalescingPattern = "\\?{2}"

        let operators = "(?:[%<>&=*+|^/~-]+|\(rangePattern)|\(coalescingPattern)|" + "\(notEqualsPattern))"

        let oneSpace = "[^\\S\\r\\n]" // to allow lines ending with operators to be valid
        let zeroSpaces = oneSpace + "{0}"
        let manySpaces = oneSpace + "{2,}"
        let leadingExpression = "(?:\\b|\\)|\\]|\")"
        let trailingExpression = "(?:\\b|\\(|\\[|\")"

        let spaces = [(zeroSpaces, zeroSpaces), (oneSpace, manySpaces),
                      (manySpaces, oneSpace), (manySpaces, manySpaces)]
        let patterns = spaces.map { first, second in
            leadingExpression + first + operators + second + trailingExpression
        }
        let pattern = "(?:\(patterns.joined(separator: "|")))"

        let genericPattern = "<(?:\(oneSpace)|\\S)*>" // not using dot to avoid matching new line
        let validRangePattern = leadingExpression + zeroSpaces + rangePattern + zeroSpaces + trailingExpression
        let excludingPattern = "(?:\(genericPattern)|\(validRangePattern))"

        let excludingKinds = SyntaxKind.commentKinds.union([.objectLiteral])

        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds,
                          excludingPattern: excludingPattern).compactMap { range in
            // if it's only a number (i.e. -9e-11), it shouldn't trigger
            guard kinds(in: range, file: file) != [.number] else {
                return nil
            }

            let spacesPattern = oneSpace + "*"
            let rangeRegex = regex(spacesPattern + rangePattern + spacesPattern)

            // if it's a range operator, the correction shouldn't have spaces
            if let matchRange = rangeRegex.firstMatch(in: file.contents, options: [], range: range)?.range {
                let correction = operatorInRange(file: file, range: matchRange)
                // Make sure that the match is not within the string i.e `let a = "12...123"`
                guard kinds(in: matchRange, file: file) != [.string] else {
                    return nil
                }
                return (matchRange, correction)
            }

            let operatorsRegex = regex(spacesPattern + operators + spacesPattern)

            guard let matchRange = operatorsRegex.firstMatch(in: file.contents,
                                                             options: [], range: range)?.range else {
                return nil
            }

            // Make sure that the match is not within the string i.e `let a = "12 == 123"`
            guard kinds(in: matchRange, file: file) != [.string] else {
                return nil
            }

            let operatorContent = operatorInRange(file: file, range: matchRange)
            let correction = " " + operatorContent + " "

            if configuration.skipAlignedConstants && isAlignedConstant(in: matchRange, file: file) {
                return nil
            }

            return (matchRange, correction)
        }
    }

    private func kinds(in range: NSRange, file: SwiftLintFile) -> [SyntaxKind] {
        let contents = file.stringView
        guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length) else {
            return []
        }

        return file.syntaxMap.kinds(inByteRange: byteRange)
    }

    private func operatorInRange(file: SwiftLintFile, range: NSRange) -> String {
        return file.stringView.substring(with: range).trimmingCharacters(in: .whitespaces)
    }

    private func isAlignedConstant(in range: NSRange, file: SwiftLintFile) -> Bool {
        /// Make sure we have match with assignment operator and with spaces before it
        let matchedString = file.stringView.substring(with: range)
        let equalityOperatorRegex = regex("\\s+=\\s")

        let fullRange = NSRange(location: 0, length: range.length)
        guard let match = equalityOperatorRegex.firstMatch(
                in: matchedString,
                options: [],
                range: fullRange),
              match.range == fullRange
        else {
            return false
        }

        guard let (lineNumber, _) = file.stringView.lineAndCharacter(forCharacterOffset: NSMaxRange(range)),
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

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = violationRanges(file: file).filter { range, _ in
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
}
