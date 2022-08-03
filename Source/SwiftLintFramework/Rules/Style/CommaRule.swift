import Foundation
import SourceKittenFramework
import SwiftSyntax

public struct CommaRule: CorrectableRule, ConfigurationProviderRule, AutomaticTestableRule, SourceKitFreeRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "comma",
        name: "Comma Spacing",
        description: "There should be no space before and one after any comma.",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc(a: String, b: String) { }"),
            Example("abc(a: \"string\", b: \"string\""),
            Example("enum a { case a, b, c }"),
            Example("func abc(\n  a: String,  // comment\n  bcd: String // comment\n) {\n}\n"),
            Example("func abc(\n  a: String,\n  bcd: String\n) {\n}\n"),
            Example("#imageLiteral(resourceName: \"foo,bar,baz\")")
        ],
        triggeringExamples: [
            Example("func abc(a: String↓ ,b: String) { }"),
            Example("func abc(a: String↓ ,b: String↓ ,c: String↓ ,d: String) { }"),
            Example("abc(a: \"string\"↓,b: \"string\""),
            Example("enum a { case a↓ ,b }"),
            Example("let result = plus(\n    first: 3↓ , // #683\n    second: 4\n)\n"),
            Example("""
            Foo(
              parameter: a.b.c,
              tag: a.d,
              value: a.identifier.flatMap { Int64($0) }↓ ,
              reason: Self.abcd()
            )
            """),
            Example("""
            return Foo(bar: .baz, title: fuzz,
                      message: My.Custom.message↓ ,
                      another: parameter, doIt: true,
                      alignment: .center)
            """)
        ],
        corrections: [
            Example("func abc(a: String↓,b: String) {}\n"): Example("func abc(a: String, b: String) {}\n"),
            Example("abc(a: \"string\"↓,b: \"string\"\n"): Example("abc(a: \"string\", b: \"string\"\n"),
            Example("abc(a: \"string\"↓  ,  b: \"string\"\n"): Example("abc(a: \"string\", b: \"string\"\n"),
            Example("enum a { case a↓  ,b }\n"): Example("enum a { case a, b }\n"),
            Example("let a = [1↓,1]\nlet b = 1\nf(1, b)\n"): Example("let a = [1, 1]\nlet b = 1\nf(1, b)\n"),
            Example("let a = [1↓,1↓,1↓,1]\n"): Example("let a = [1, 1, 1, 1]\n"),
            Example("""
            Foo(
              parameter: a.b.c,
              tag: a.d,
              value: a.identifier.flatMap { Int64($0) }↓ ,
              reason: Self.abcd()
            )
            """): Example("""
                Foo(
                  parameter: a.b.c,
                  tag: a.d,
                  value: a.identifier.flatMap { Int64($0) },
                  reason: Self.abcd()
                )
                """),
            Example("""
            return Foo(bar: .baz, title: fuzz,
                      message: My.Custom.message↓ ,
                      another: parameter, doIt: true,
                      alignment: .center)
            """): Example("""
                return Foo(bar: .baz, title: fuzz,
                          message: My.Custom.message,
                          another: parameter, doIt: true,
                          alignment: .center)
                """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0.0.location))
        }
    }

    private func violationRanges(in file: SwiftLintFile) -> [(ByteRange, shouldAddSpace: Bool)] {
        guard let syntaxTree = file.syntaxTree else {
            return []
        }

        return Array(syntaxTree.tokens)
            .windows(ofCount: 3)
            .compactMap { subsequence -> (ByteRange, shouldAddSpace: Bool)? in
                let previous = subsequence[subsequence.startIndex]
                let current = subsequence[subsequence.startIndex + 1]
                let next = subsequence[subsequence.startIndex + 2]

                if current.tokenKind != .comma {
                    return nil
                } else if !previous.trailingTrivia.isEmpty {
                    let start = ByteCount(previous.endPositionBeforeTrailingTrivia)
                    let end = ByteCount(current.endPosition)
                    let nextIsNewline = next.leadingTrivia.containsNewlines()
                    return (ByteRange(location: start, length: end - start), shouldAddSpace: !nextIsNewline)
                } else if current.trailingTrivia != [.spaces(1)] && !next.leadingTrivia.containsNewlines() {
                    return (ByteRange(location: ByteCount(current.position), length: 1), shouldAddSpace: true)
                } else {
                    return nil
                }
            }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let initialNSRanges = Dictionary(
            uniqueKeysWithValues: violationRanges(in: file)
                .compactMap { byteRange, shouldAddSpace in
                    file.stringView
                        .byteRangeToNSRange(byteRange)
                        .flatMap { ($0, shouldAddSpace) }
                }
        )

        let violatingRanges = file.ruleEnabled(violatingRanges: Array(initialNSRanges.keys), for: self)
        guard violatingRanges.isNotEmpty else { return [] }

        let description = Self.description
        var corrections = [Correction]()
        var contents = file.contents
        for range in violatingRanges.sorted(by: { $0.location > $1.location }) {
            let contentsNSString = contents.bridge()
            let shouldAddSpace = initialNSRanges[range] ?? true
            contents = contentsNSString.replacingCharacters(in: range, with: ",\(shouldAddSpace ? " " : "")")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}

private extension Trivia {
    func containsNewlines() -> Bool {
        contains { piece in
            switch piece {
            case .newlines:
                return true
            default:
                return false
            }
        }
    }
}
