import Foundation
import SourceKittenFramework
import SwiftSyntax

struct CommaRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
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
            Example("#imageLiteral(resourceName: \"foo,bar,baz\")"),
            Example("""
                kvcStringBuffer.advanced(by: rootKVCLength)
                  .storeBytes(of: 0x2E /* '.' */, as: CChar.self)
                """),
            Example("""
                public indirect enum ExpectationMessage {
                  /// appends after an existing message ("<expectation> (use beNil() to match nils)")
                  case appends(ExpectationMessage, /* Appended Message */ String)
                }
                """, excludeFromDocumentation: true)
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
            """),
            Example(#"Logger.logError("Hat is too large"↓,  info: [])"#)
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
                """),
            Example(#"Logger.logError("Hat is too large"↓,  info: [])"#):
                Example(#"Logger.logError("Hat is too large", info: [])"#)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0.0.location))
        }
    }

    private func violationRanges(in file: SwiftLintFile) -> [(ByteRange, shouldAddSpace: Bool)] {
        let syntaxTree = file.syntaxTree

        return syntaxTree
            .windowsOfThreeTokens()
            .compactMap { previous, current, next -> (ByteRange, shouldAddSpace: Bool)? in
                if current.tokenKind != .comma {
                    return nil
                } else if !previous.trailingTrivia.isEmpty && !previous.trailingTrivia.containsBlockComments() {
                    let start = ByteCount(previous.endPositionBeforeTrailingTrivia)
                    let end = ByteCount(current.endPosition)
                    let nextIsNewline = next.leadingTrivia.containsNewlines()
                    return (ByteRange(location: start, length: end - start), shouldAddSpace: !nextIsNewline)
                } else if !current.trailingTrivia.starts(with: [.spaces(1)]), !next.leadingTrivia.containsNewlines() {
                    let start = ByteCount(current.position)
                    let end = ByteCount(next.positionAfterSkippingLeadingTrivia)
                    return (ByteRange(location: start, length: end - start), shouldAddSpace: true)
                } else {
                    return nil
                }
            }
    }

    func correct(file: SwiftLintFile) -> [Correction] {
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
    func containsBlockComments() -> Bool {
        contains { piece in
            if case .blockComment = piece {
                return true
            } else {
                return false
            }
        }
    }
}
