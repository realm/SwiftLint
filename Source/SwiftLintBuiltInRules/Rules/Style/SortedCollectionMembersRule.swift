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
            "[c, b, a]".asExample(configuration: reverseSort),
            "[]",
            "[1]",
            "[a]",
            """
            ["a", "b", "c"]
            """,
            """
            ["c", "b", "a"]
            """.asExample(configuration: reverseSort),
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
            """,
            """
            [
              .thingC,
              .thingB,
              // comments are ignored in sort checking
              .thingA,
            ]
            """.asExample(configuration: reverseSort)
        ]),
        triggeringExamples: #examples([
            "[1, ↓3, 2]",
            "[↓1, 3, 2]".asExample(configuration: reverseSort),
            "[↓1, 2, 3]".asExample(configuration: reverseSort),
            """
            [↓"b", "c", "a"]
            """,
            """
            [↓"b", "c", "a"]
            """.asExample(configuration: reverseSort),
            """
            [
              ↓.thingBNoComment,
              .thingCNoComment,
              .thingANoComment,
            ]
            """,
            """
            [
              ↓.thingANoComment,
              .thingBNoComment,
              .thingCNoComment,
            ]
            """.asExample(configuration: reverseSort),
            """
            [
              ↓.thingBWithComment,
              // Comments are not counted when evaluating sort order
              .thingCWithComment,
              .thingAWithComment,
            ]
            """,
            """
            [
              ↓.thingAWithComment,
              .thingBWithComment,
              // Comments are not counted when evaluating sort order
              .thingCWithComment,
            ]
            """.asExample(configuration: reverseSort),
            // integration-style test
            """
            let package = Package(
              name: "Packages",
              platforms: [
                ↓.macOS(.v10_15),
                .iOS(.v26),
              ],
              products: [
                ↓.library(name: "Library2", type: type, targets: ["Library2"]),
                .library(name: "Library1", type: type, targets: ["Library1"]),
              ],
              dependencies: [
                ↓.package(
                  url: "https://github.com/qux/quiz",
                  exact: "4.5.6"
                ),
                .package(
                  url: "https://github.com/foo/bar",
                  exact: "1.2.3"
                ),
              ],
              targets: [
                ↓.target(
                  name: "CoolFeatureB",
                  dependencies: [
                    "SomeDependency",
                    .product(name: "AnotherDependency", package: "another-dependency"),
                  ]
                ),
                .target(
                  name: "CoolFeatureA",
                  dependencies: [
                    ↓.dependencyB,
                    .dependencyA,
                  ]
                ),
              ]
            )
            """,
        ])
    )
}

private let reverseSort: [String: any Sendable] = ["reverse": true]

// TODO: add dictionary literal support
// TODO: support case-insensitive sort?
// TODO: seems like /*>*/ syntax has an off-by-one compared with ↓ syntax
// TODO: find a way to opt out of visiting nodes that do not apply to us.
// TODO: test that inline override works, so a file where this is enabled can opt-out for a single array

private extension SortedCollectionMembersRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
            let sortedNames = node.elements
                .map(\.expression.trimmedDescription)
                .sorted(by: configuration.reverse ? (>) : (<))

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
