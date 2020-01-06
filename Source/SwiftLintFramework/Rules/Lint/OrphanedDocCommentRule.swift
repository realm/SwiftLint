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
            """,
            """
            //////////////////////////////////////
            //
            // Copyright header.
            //
            //////////////////////////////////////
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

    private static let characterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/"))

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let docStringsTokens = file.syntaxMap.tokens.filter { token in
            return token.kind == .docComment || token.kind == .docCommentField
        }

        let docummentedDeclsRanges = file.structureDictionary.traverseDepthFirst { dictionary -> [NSRange]? in
            guard let docOffset = dictionary.docOffset, let docLength = dictionary.docLength else {
                return nil
            }

            return [NSRange(location: docOffset, length: docLength)]
        }.sorted { $0.location < $1.location }

        return docStringsTokens
            .filter { token in
                guard docummentedDeclsRanges.firstIndexAssumingSorted(where: token.range.intersects) == nil,
                    let contents = file.contents(for: token) else {
                        return false
                }

                return !contents.trimmingCharacters(in: type(of: self).characterSet).isEmpty
            }.map { token in
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: Location(file: file, byteOffset: token.offset))
            }
    }
}
