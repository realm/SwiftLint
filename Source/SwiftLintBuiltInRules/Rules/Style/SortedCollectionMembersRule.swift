import Foundation
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct SortedCollectionMembersRule: Rule {
    var configuration = SortedCollectionMembersConfiguration()

    static let description: RuleDescription = RuleDescription(
        identifier: "sorted_collection_members",
        name: "Sorted Collection Members",
        description: "Please keep the elements of this collection literal sorted",
        kind: .style,
        nonTriggeringExamples: #examples([
            "[1, 2, 3]",
            "[a, b, c]",
            "[]",
            "[1]",
            "[a]",
            """
            ["a", "b", "c"]
            """,
            """
            ["a"]
            """,
            """
            [
              .thingA,
              .thingB,
              // comments are ignored in sort checking
              .thingC,
            ]
            """
        ]),
        triggeringExamples: #examples([
            "[1, ↓3, 2]",
            """
            [↓"b", "c", "a"]
            """,
            """
            [
              ↓.thingBNoComment,
              .thingCNoComment,
              .thingANoComment,
            ]
            """,
            """
            [
              ↓.thingBWithComment,
              // Comments are not counted when evaluating sort order
              .thingCWithComment,
              .thingAWithComment,
            ]
            """,
        ])
    )
}

// TODO: add dictionary literal support
// TODO: support reverse sort
// TODO: support case-insensitive sort?
// TODO: seems like /*>*/ syntax has an off-by-one compared with ↓ syntax
// TODO: see if we can enforce that this rule must be opt-in, and shouldn't be enabled globally.
// TODO: find a way to opt out of visiting nodes that do not apply to us.

private extension SortedCollectionMembersRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
            let sortedNames = node.elements
                .map(\.expression.trimmedDescription)
                .sorted()

            let originalAndSorted = zip(zip(node.elements.indices, node.elements), sortedNames)
            for ((originalIndex, originalElement), sortedName) in originalAndSorted {
                if originalElement.expression.trimmedDescription != sortedName {
                    violations.append(node.elements[originalIndex].positionAfterSkippingLeadingTrivia)
                    // break on the first sorting violation because everything after it is necessarily not sorted
                    break
                }
            }

            return .visitChildren
        }
    }
}
