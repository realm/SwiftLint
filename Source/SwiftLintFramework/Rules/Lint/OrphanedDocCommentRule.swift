import IDEUtils
import SwiftSyntax

struct OrphanedDocCommentRule: SourceKitFreeRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "orphaned_doc_comment",
        name: "Orphaned Doc Comment",
        description: "A doc comment should be attached to a declaration.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            /// My great property
            var myGreatProperty: String!
            """),
            Example("""
            //////////////////////////////////////
            //
            // Copyright header.
            //
            //////////////////////////////////////
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
            ↓/// My great property
            // Not a doc string
            var myGreatProperty: String!
            """),
            Example("""
            ↓/// Look here for more info: https://github.com.
            // Not a doc string
            var myGreatProperty: String!
            """),
            Example("""
            func foo() {
              ↓/// Docstring inside a function declaration
              print("foo")
            }
            """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let classifications = file.syntaxClassifications
            .filter { $0.kind != .none }
        let docstringsWithOtherComments = classifications
            .pairs()
            .compactMap { first, second -> Location? in
                let firstByteRange = first.range.toSourceKittenByteRange()
                guard
                    let second = second,
                    first.kind == .docLineComment || first.kind == .docBlockComment,
                    second.kind == .lineComment || second.kind == .blockComment,
                    let firstString = file.stringView.substringWithByteRange(firstByteRange),
                    // These patterns are often used for "file header" style comments
                    !firstString.starts(with: "////") && !firstString.starts(with: "/***")
                else {
                    return nil
                }

                return Location(file: file, byteOffset: firstByteRange.location)
            }

        let docstringsInFunctionDeclarations = Visitor(classifications: classifications)
            .walk(tree: file.syntaxTree, handler: \.violations)
            .map { Location(file: file, position: $0.position) }

        return (docstringsWithOtherComments + docstringsInFunctionDeclarations)
            .sorted()
            .map { location in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: location)
            }
    }
}

private extension OrphanedDocCommentRule {
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

private extension Sequence {
    func pairs() -> Zip2Sequence<Self, [Element?]> {
        return zip(self, Array(dropFirst()) + [nil])
    }
}
