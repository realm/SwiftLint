import SwiftSyntax

struct LegacyConstructorRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "legacy_constructor",
        name: "Legacy Constructor",
        description: "Swift constructors are preferred over legacy convenience functions.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("CGPoint(x: 10, y: 10)"),
            Example("CGPoint(x: xValue, y: yValue)"),
            Example("CGSize(width: 10, height: 10)"),
            Example("CGSize(width: aWidth, height: aHeight)"),
            Example("CGRect(x: 0, y: 0, width: 10, height: 10)"),
            Example("CGRect(x: xVal, y: yVal, width: aWidth, height: aHeight)"),
            Example("CGVector(dx: 10, dy: 10)"),
            Example("CGVector(dx: deltaX, dy: deltaY)"),
            Example("NSPoint(x: 10, y: 10)"),
            Example("NSPoint(x: xValue, y: yValue)"),
            Example("NSSize(width: 10, height: 10)"),
            Example("NSSize(width: aWidth, height: aHeight)"),
            Example("NSRect(x: 0, y: 0, width: 10, height: 10)"),
            Example("NSRect(x: xVal, y: yVal, width: aWidth, height: aHeight)"),
            Example("NSRange(location: 10, length: 1)"),
            Example("NSRange(location: loc, length: len)"),
            Example("UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
            Example("UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)"),
            Example("NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
            Example("NSEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)"),
            Example("UIOffset(horizontal: 0, vertical: 10)"),
            Example("UIOffset(horizontal: horizontal, vertical: vertical)")
        ],
        triggeringExamples: [
            Example("↓CGPointMake(10, 10)"),
            Example("↓CGPointMake(xVal, yVal)"),
            Example("↓CGPointMake(calculateX(), 10)\n"),
            Example("↓CGSizeMake(10, 10)"),
            Example("↓CGSizeMake(aWidth, aHeight)"),
            Example("↓CGRectMake(0, 0, 10, 10)"),
            Example("↓CGRectMake(xVal, yVal, width, height)"),
            Example("↓CGVectorMake(10, 10)"),
            Example("↓CGVectorMake(deltaX, deltaY)"),
            Example("↓NSMakePoint(10, 10)"),
            Example("↓NSMakePoint(xVal, yVal)"),
            Example("↓NSMakeSize(10, 10)"),
            Example("↓NSMakeSize(aWidth, aHeight)"),
            Example("↓NSMakeRect(0, 0, 10, 10)"),
            Example("↓NSMakeRect(xVal, yVal, width, height)"),
            Example("↓NSMakeRange(10, 1)"),
            Example("↓NSMakeRange(loc, len)"),
            Example("↓UIEdgeInsetsMake(0, 0, 10, 10)"),
            Example("↓UIEdgeInsetsMake(top, left, bottom, right)"),
            Example("↓NSEdgeInsetsMake(0, 0, 10, 10)"),
            Example("↓NSEdgeInsetsMake(top, left, bottom, right)"),
            Example("↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)"),
            Example("↓UIOffsetMake(0, 10)"),
            Example("↓UIOffsetMake(horizontal, vertical)")
        ],
        corrections: [
            Example("↓CGPointMake(10,  10)\n"): Example("CGPoint(x: 10,  y: 10)\n"),
            Example("↓CGPointMake(xPos,  yPos)\n"): Example("CGPoint(x: xPos,  y: yPos)\n"),
            Example("↓CGSizeMake(10, 10)\n"): Example("CGSize(width: 10, height: 10)\n"),
            Example("↓CGSizeMake( aWidth, aHeight )\n"): Example("CGSize( width: aWidth, height: aHeight )\n"),
            Example("↓CGRectMake(0, 0, 10, 10)\n"): Example("CGRect(x: 0, y: 0, width: 10, height: 10)\n"),
            Example("↓CGRectMake(xPos, yPos , width, height)\n"):
                Example("CGRect(x: xPos, y: yPos , width: width, height: height)\n"),
            Example("↓CGVectorMake(10, 10)\n"): Example("CGVector(dx: 10, dy: 10)\n"),
            Example("↓CGVectorMake(deltaX, deltaY)\n"): Example("CGVector(dx: deltaX, dy: deltaY)\n"),
            Example("↓NSMakePoint(10,  10   )\n"): Example("NSPoint(x: 10,  y: 10   )\n"),
            Example("↓NSMakePoint(xPos,  yPos   )\n"): Example("NSPoint(x: xPos,  y: yPos   )\n"),
            Example("↓NSMakeSize(10, 10)\n"): Example("NSSize(width: 10, height: 10)\n"),
            Example("↓NSMakeSize( aWidth, aHeight )\n"): Example("NSSize( width: aWidth, height: aHeight )\n"),
            Example("↓NSMakeRect(0, 0, 10, 10)\n"): Example("NSRect(x: 0, y: 0, width: 10, height: 10)\n"),
            Example("↓NSMakeRect(xPos, yPos , width, height)\n"):
                Example("NSRect(x: xPos, y: yPos , width: width, height: height)\n"),
            Example("↓NSMakeRange(10, 1)\n"): Example("NSRange(location: 10, length: 1)\n"),
            Example("↓NSMakeRange(loc, len)\n"): Example("NSRange(location: loc, length: len)\n"),
            Example("↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)\n"):
                Example("CGVector(dx: 10, dy: 10)\nNSRange(location: 10, length: 1)\n"),
            Example("↓CGVectorMake(dx, dy)\n↓NSMakeRange(loc, len)\n"):
                Example("CGVector(dx: dx, dy: dy)\nNSRange(location: loc, length: len)\n"),
            Example("↓UIEdgeInsetsMake(0, 0, 10, 10)\n"):
                Example("UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n"),
            Example("↓UIEdgeInsetsMake(top, left, bottom, right)\n"):
                Example("UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n"),
            Example("↓NSEdgeInsetsMake(0, 0, 10, 10)\n"):
                Example("NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n"),
            Example("↓NSEdgeInsetsMake(top, left, bottom, right)\n"):
                Example("NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n"),
            Example("↓NSMakeRange(0, attributedString.length)\n"):
                Example("NSRange(location: 0, length: attributedString.length)\n"),
            Example("↓CGPointMake(calculateX(), 10)\n"): Example("CGPoint(x: calculateX(), y: 10)\n"),
            Example("↓UIOffsetMake(0, 10)\n"): Example("UIOffset(horizontal: 0, vertical: 10)\n"),
            Example("↓UIOffsetMake(horizontal, vertical)\n"):
                Example("UIOffset(horizontal: horizontal, vertical: vertical)\n")
        ]
    )

    private static let constructorsToArguments = ["CGRectMake": ["x", "y", "width", "height"],
                                                  "CGPointMake": ["x", "y"],
                                                  "CGSizeMake": ["width", "height"],
                                                  "CGVectorMake": ["dx", "dy"],
                                                  "NSMakePoint": ["x", "y"],
                                                  "NSMakeSize": ["width", "height"],
                                                  "NSMakeRect": ["x", "y", "width", "height"],
                                                  "NSMakeRange": ["location", "length"],
                                                  "UIEdgeInsetsMake": ["top", "left", "bottom", "right"],
                                                  "NSEdgeInsetsMake": ["top", "left", "bottom", "right"],
                                                  "UIOffsetMake": ["horizontal", "vertical"]]

    private static let constructorsToCorrectedNames = ["CGRectMake": "CGRect",
                                                       "CGPointMake": "CGPoint",
                                                       "CGSizeMake": "CGSize",
                                                       "CGVectorMake": "CGVector",
                                                       "NSMakePoint": "NSPoint",
                                                       "NSMakeSize": "NSSize",
                                                       "NSMakeRect": "NSRect",
                                                       "NSMakeRange": "NSRange",
                                                       "UIEdgeInsetsMake": "UIEdgeInsets",
                                                       "NSEdgeInsetsMake": "NSEdgeInsets",
                                                       "UIOffsetMake": "UIOffset"]

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension LegacyConstructorRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
               constructorsToCorrectedNames[identifierExpr.identifier.withoutTrivia().text] != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
                  case let identifier = identifierExpr.identifier.withoutTrivia().text,
                  let correctedName = constructorsToCorrectedNames[identifier],
                  let args = constructorsToArguments[identifier],
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let arguments = TupleExprElementListSyntax(node.argumentList.map { elem in
                elem
                    .withLabel(.identifier(args[elem.indexInParent]))
                    .withColon(.colonToken(trailingTrivia: .space))
            })
            let newExpression = identifierExpr.withIdentifier(
                .identifier(
                    correctedName,
                    leadingTrivia: identifierExpr.identifier.leadingTrivia,
                    trailingTrivia: identifierExpr.identifier.trailingTrivia
                )
            )
            let newNode = node
                .withCalledExpression(ExprSyntax(newExpression))
                .withArgumentList(arguments)
            return super.visit(newNode)
        }
    }
}
