import Foundation
import SourceKittenFramework

public struct OrphanedDocCommentRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "orphaned_doc_comment",
        name: "Orphaned Doc Comment",
        description: "A doc comment should be attached to a declaration.",
        kind: .lint,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            """
            /// My great property
            var myGreatProperty: String!
            """
        ],
        triggeringExamples: [
            """
            ↓/// My great property
            // Not a doc string
            var myGreatProperty: String!
            """
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let docStringsTokens = file.syntaxMap.tokens.compactMap { token -> NSRange? in
            guard token.kind == .docComment || token.kind == .docCommentField else {
                return nil
            }

            return token.range
        }

        let docummentedDeclsRanges = file.structureDictionary.traverseDepthFirst { dictionary -> [NSRange]? in
            guard let docOffset = dictionary.docOffset, let docLength = dictionary.docLength else {
                return nil
            }

            return [NSRange(location: docOffset, length: docLength)]
        }.sorted { $0.location < $1.location }

        return docStringsTokens
            .filter { tokenRange in
                return docummentedDeclsRanges.firstIndexAssumingSorted(where: tokenRange.intersects) == nil
            }.map { range in
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: Location(file: file, byteOffset: range.location))
            }
    }
}
