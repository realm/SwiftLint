import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct LegacyConstructorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_constructor",
        name: "Legacy Constructor",
        description: "Swift constructors are preferred over legacy convenience functions",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "CGPoint(x: 10, y: 10)",
            "CGPoint(x: xValue, y: yValue)",
            "CGSize(width: 10, height: 10)",
            "CGSize(width: aWidth, height: aHeight)",
            "CGRect(x: 0, y: 0, width: 10, height: 10)",
            "CGRect(x: xVal, y: yVal, width: aWidth, height: aHeight)",
            "CGVector(dx: 10, dy: 10)",
            "CGVector(dx: deltaX, dy: deltaY)",
            "NSPoint(x: 10, y: 10)",
            "NSPoint(x: xValue, y: yValue)",
            "NSSize(width: 10, height: 10)",
            "NSSize(width: aWidth, height: aHeight)",
            "NSRect(x: 0, y: 0, width: 10, height: 10)",
            "NSRect(x: xVal, y: yVal, width: aWidth, height: aHeight)",
            "NSRange(location: 10, length: 1)",
            "NSRange(location: loc, length: len)",
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)",
            "NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "NSEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)",
            "UIOffset(horizontal: 0, vertical: 10)",
            "UIOffset(horizontal: horizontal, vertical: vertical)",
        ]),
        triggeringExamples: #examples([
            "↓CGPointMake(10, 10)",
            "↓CGPointMake(xVal, yVal)",
            "↓CGPointMake(calculateX(), 10)",
            "↓CGSizeMake(10, 10)",
            "↓CGSizeMake(aWidth, aHeight)",
            "↓CGRectMake(0, 0, 10, 10)",
            "↓CGRectMake(xVal, yVal, width, height)",
            "↓CGVectorMake(10, 10)",
            "↓CGVectorMake(deltaX, deltaY)",
            "↓NSMakePoint(10, 10)",
            "↓NSMakePoint(xVal, yVal)",
            "↓NSMakeSize(10, 10)",
            "↓NSMakeSize(aWidth, aHeight)",
            "↓NSMakeRect(0, 0, 10, 10)",
            "↓NSMakeRect(xVal, yVal, width, height)",
            "↓NSMakeRange(10, 1)",
            "↓NSMakeRange(loc, len)",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)",
            "↓UIEdgeInsetsMake(top, left, bottom, right)",
            "↓NSEdgeInsetsMake(0, 0, 10, 10)",
            "↓NSEdgeInsetsMake(top, left, bottom, right)",
            "↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)",
            "↓UIOffsetMake(0, 10)",
            "↓UIOffsetMake(horizontal, vertical)",
        ]),
        corrections: #corrections([
            "↓CGPointMake(10,  10)": "CGPoint(x: 10,  y: 10)",
            "↓CGPointMake(xPos,  yPos)": "CGPoint(x: xPos,  y: yPos)",
            "↓CGSizeMake(10, 10)": "CGSize(width: 10, height: 10)",
            "↓CGSizeMake( aWidth, aHeight )": "CGSize( width: aWidth, height: aHeight )",
            "↓CGRectMake(0, 0, 10, 10)": "CGRect(x: 0, y: 0, width: 10, height: 10)",
            "↓CGRectMake(xPos, yPos , width, height)":
                "CGRect(x: xPos, y: yPos , width: width, height: height)",
            "↓CGVectorMake(10, 10)": "CGVector(dx: 10, dy: 10)",
            "↓CGVectorMake(deltaX, deltaY)": "CGVector(dx: deltaX, dy: deltaY)",
            "↓NSMakePoint(10,  10   )": "NSPoint(x: 10,  y: 10   )",
            "↓NSMakePoint(xPos,  yPos   )": "NSPoint(x: xPos,  y: yPos   )",
            "↓NSMakeSize(10, 10)": "NSSize(width: 10, height: 10)",
            "↓NSMakeSize( aWidth, aHeight )": "NSSize( width: aWidth, height: aHeight )",
            "↓NSMakeRect(0, 0, 10, 10)": "NSRect(x: 0, y: 0, width: 10, height: 10)",
            "↓NSMakeRect(xPos, yPos , width, height)":
                "NSRect(x: xPos, y: yPos , width: width, height: height)",
            "↓NSMakeRange(10, 1)": "NSRange(location: 10, length: 1)",
            "↓NSMakeRange(loc, len)": "NSRange(location: loc, length: len)",
            "↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)":
                "CGVector(dx: 10, dy: 10)\nNSRange(location: 10, length: 1)",
            "↓CGVectorMake(dx, dy)\n↓NSMakeRange(loc, len)":
                "CGVector(dx: dx, dy: dy)\nNSRange(location: loc, length: len)",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)":
                "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "↓UIEdgeInsetsMake(top, left, bottom, right)":
                "UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)",
            "↓NSEdgeInsetsMake(0, 0, 10, 10)":
                "NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "↓NSEdgeInsetsMake(top, left, bottom, right)":
                "NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)",
            "↓NSMakeRange(0, attributedString.length)":
                "NSRange(location: 0, length: attributedString.length)",
            "↓CGPointMake(calculateX(), 10)": "CGPoint(x: calculateX(), y: 10)",
            "↓UIOffsetMake(0, 10)": "UIOffset(horizontal: 0, vertical: 10)",
            "↓UIOffsetMake(horizontal, vertical)":
                "UIOffset(horizontal: horizontal, vertical: vertical)",
        ])
    )

    private static let constructorsToArguments = [
        "CGRectMake": ["x", "y", "width", "height"],
        "CGPointMake": ["x", "y"],
        "CGSizeMake": ["width", "height"],
        "CGVectorMake": ["dx", "dy"],
        "NSMakePoint": ["x", "y"],
        "NSMakeSize": ["width", "height"],
        "NSMakeRect": ["x", "y", "width", "height"],
        "NSMakeRange": ["location", "length"],
        "UIEdgeInsetsMake": ["top", "left", "bottom", "right"],
        "NSEdgeInsetsMake": ["top", "left", "bottom", "right"],
        "UIOffsetMake": ["horizontal", "vertical"],
    ]

    private static let constructorsToCorrectedNames = [
        "CGRectMake": "CGRect",
        "CGPointMake": "CGPoint",
        "CGSizeMake": "CGSize",
        "CGVectorMake": "CGVector",
        "NSMakePoint": "NSPoint",
        "NSMakeSize": "NSSize",
        "NSMakeRect": "NSRect",
        "NSMakeRange": "NSRange",
        "UIEdgeInsetsMake": "UIEdgeInsets",
        "NSEdgeInsetsMake": "NSEdgeInsets",
        "UIOffsetMake": "UIOffset",
    ]
}

private extension LegacyConstructorRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
               constructorsToCorrectedNames[identifierExpr.baseName.text] != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
                  case let identifier = identifierExpr.baseName.text,
                  let correctedName = constructorsToCorrectedNames[identifier],
                  let args = constructorsToArguments[identifier] else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let arguments = LabeledExprListSyntax(node.arguments.enumerated().map { index, elem in
                elem
                    .with(\.label, .identifier(args[index]))
                    .with(\.colon, .colonToken(trailingTrivia: .space))
            })
            let newExpression = identifierExpr.with(
                \.baseName,
                .identifier(
                    correctedName,
                    leadingTrivia: identifierExpr.baseName.leadingTrivia,
                    trailingTrivia: identifierExpr.baseName.trailingTrivia
                )
            )
            let newNode = node
                .with(\.calledExpression, ExprSyntax(newExpression))
                .with(\.arguments, arguments)
            return super.visit(newNode)
        }
    }
}
