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
        // Doc comment ranges come from the file's shared comment trivia pass, which several other
        // rules already force, rather than from `syntaxClassifications`, which would additionally
        // run SwiftSyntax's general-purpose classifier over every token in the file.
        Visitor(
            configuration: configuration,
            file: file,
            docCommentRanges: file.docCommentRanges()
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
