import IDEUtils
import SwiftSyntax

struct LocalDocCommentRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "local_doc_comment",
        name: "Local Doc Comment",
        description: "Prefer regular comments over doc comments in local scopes",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            func foo() {
              // Local scope documentation should use normal comments.
              print("foo")
            }
            """),
            Example("""
            /// My great property
            var myGreatProperty: String!
            """),
            Example("""
            /// Look here for more info: https://github.com.
            var myGreatProperty: String!
            """),
            Example("""
            /// Look here for more info:
            /// https://github.com.
            var myGreatProperty: String!
            """)
        ],
        triggeringExamples: [
            Example("""
            func foo() {
              ↓/// Docstring inside a function declaration
              print("foo")
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(classifications: file.syntaxClassifications.filter { $0.kind != .none })
    }
}

private extension LocalDocCommentRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let docCommentRanges: [ByteSourceRange]

        init(classifications: [SyntaxClassifiedRange]) {
            self.docCommentRanges = classifications
                .filter { $0.kind == .docLineComment || $0.kind == .docBlockComment }
                .map(\.range)
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }

            let violatingRange = docCommentRanges.first { $0.intersects(body.byteRange) }
            if let violatingRange {
                violations.append(AbsolutePosition(utf8Offset: violatingRange.offset))
            }
        }
    }
}
