import SwiftLintCore
import SwiftSyntax

struct LocalDocCommentRule: SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "local_doc_comment",
        name: "Local Doc Comment",
        description: "Prefer regular comments over doc comments in local scopes",
        kind: .lint,
        nonTriggeringExamples: #examples([
            """
            func foo() {
              // Local scope documentation should use normal comments.
              print("foo")
            }
            """,
            """
            /// My great property
            var myGreatProperty: String!
            """,
            """
            /// Look here for more info: https://github.com.
            var myGreatProperty: String!
            """,
            """
            /// Look here for more info:
            /// https://github.com.
            var myGreatProperty: String!
            """,
        ]),
        triggeringExamples: #examples([
            """
            func foo() {
              ↓/// Docstring inside a function declaration
              print("foo")
            }
            """,
        ])
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(
            configuration: configuration,
            file: file,
            docCommentRanges: DocCommentRangesVisitor.docCommentRanges(in: file)
        )
    }
}

private extension LocalDocCommentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private let docCommentRanges: [Range<AbsolutePosition>]

        init(configuration: ConfigurationType,
             file: SwiftLintFile,
             docCommentRanges: [Range<AbsolutePosition>]) {
            self.docCommentRanges = docCommentRanges
            super.init(configuration: configuration, file: file)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }

            let violatingRange = docCommentRanges.first { $0.overlaps(body.range) }
            if let violatingRange {
                violations.append(AbsolutePosition(utf8Offset: violatingRange.lowerBound.utf8Offset))
            }
        }
    }
}

/// Collects the source ranges of every doc comment (`///` and `/** */`) in a file, in source order.
///
/// Doc comments are read straight off token trivia rather than via `syntaxClassifications`, which
/// reaches the same ranges only after running SwiftSyntax's general-purpose classifier — keyword,
/// identifier, type and literal classification, resolved through key path comparisons — over every
/// token in the file, all of which this rule discards. Byte positions are tracked incrementally
/// during the walk because `SyntaxProtocol.position` climbs the tree on every call.
private final class DocCommentRangesVisitor: SyntaxVisitor {
    private enum DocCommentKind {
        case line, block
    }

    private var ranges = [Range<AbsolutePosition>]()
    private var position = 0
    private var lastKind: DocCommentKind?
    private var lastEnd = 0

    static func docCommentRanges(in file: SwiftLintFile) -> [Range<AbsolutePosition>] {
        let visitor = DocCommentRangesVisitor(viewMode: .sourceAccurate)
        visitor.walk(file.syntaxTree)
        return visitor.ranges
    }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        // Materializing trivia re-lexes it, so only do so for tokens that actually have some.
        if token.leadingTriviaLength.utf8Length > 0 {
            appendDocCommentRanges(in: token.leadingTrivia)
        }
        position += token.trimmedLength.utf8Length
        if token.trailingTriviaLength.utf8Length > 0 {
            appendDocCommentRanges(in: token.trailingTrivia)
        }
        return .skipChildren
    }

    private func appendDocCommentRanges(in trivia: Trivia) {
        for piece in trivia {
            let length = piece.sourceLength.utf8Length
            let kind: DocCommentKind? =
                switch piece {
                case .docLineComment: .line
                case .docBlockComment: .block
                default: nil
                }
            if let kind {
                append(kind: kind, start: position, end: position + length)
            }
            position += length
        }
    }

    private func append(kind: DocCommentKind, start: Int, end: Int) {
        // The classifier this replaces coalesces directly adjacent ranges of the same kind, which
        // `/** a *//** b */` produces, so do the same to report identical ranges.
        if kind == lastKind, start == lastEnd, ranges.isNotEmpty {
            ranges[ranges.count - 1] = ranges[ranges.count - 1].lowerBound..<AbsolutePosition(utf8Offset: end)
        } else {
            ranges.append(AbsolutePosition(utf8Offset: start)..<AbsolutePosition(utf8Offset: end))
        }
        lastKind = kind
        lastEnd = end
    }
}
