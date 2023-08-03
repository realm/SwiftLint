import SwiftSyntax

struct EmptyCollectionLiteralRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "empty_collection_literal",
        name: "Empty Collection Literal",
        description: "Prefer checking `isEmpty` over comparing collection to an empty array or dictionary literal",
        kind: .performance,
        nonTriggeringExamples: [
            "myArray = []",
            "myArray.isEmpty",
            "!myArray.isEmpty",
            "myDict = [:]"
        ],
        triggeringExamples: [
            "myArray↓ == []",
            "myArray↓ != []",
            "myArray↓ == [ ]",
            "myDict↓ == [:]",
            "myDict↓ != [:]",
            "myDict↓ == [: ]",
            "myDict↓ == [ :]",
            "myDict↓ == [ : ]"
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension EmptyCollectionLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TokenSyntax) {
            guard
                node.tokenKind.isEqualityComparison,
                let violationPosition = node.previousToken(viewMode: .sourceAccurate)?.endPositionBeforeTrailingTrivia,
                let expectedLeftSquareBracketToken = node.nextToken(viewMode: .sourceAccurate),
                expectedLeftSquareBracketToken.tokenKind == .leftSquareBracket,
                let expectedColonToken = expectedLeftSquareBracketToken.nextToken(viewMode: .sourceAccurate),
                expectedColonToken.tokenKind == .colon || expectedColonToken.tokenKind == .rightSquareBracket
            else {
                return
            }

            violations.append(violationPosition)
        }
    }
}
