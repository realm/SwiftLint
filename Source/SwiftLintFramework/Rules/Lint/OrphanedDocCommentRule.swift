import IDEUtils

struct OrphanedDocCommentRule: SourceKitFreeRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "orphaned_doc_comment",
        name: "Orphaned Doc Comment",
        description: "A doc comment should be attached to a declaration",
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
            """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        file.syntaxClassifications
            .filter { $0.kind != .none }
            .pairs()
            .compactMap { first, second in
                let firstByteRange = first.range.toSourceKittenByteRange()
                guard
                    let second,
                    first.kind == .docLineComment || first.kind == .docBlockComment,
                    second.kind == .lineComment || second.kind == .blockComment,
                    let firstString = file.stringView.substringWithByteRange(firstByteRange),
                    // These patterns are often used for "file header" style comments
                    !firstString.starts(with: "////") && !firstString.starts(with: "/***")
                else {
                    return nil
                }

                return StyleViolation(ruleDescription: Self.description,
                                      severity: configuration.severity,
                                      location: Location(file: file, byteOffset: firstByteRange.location))
            }
    }
}

private extension Sequence {
    func pairs() -> Zip2Sequence<Self, [Element?]> {
        return zip(self, Array(dropFirst()) + [nil])
    }
}
