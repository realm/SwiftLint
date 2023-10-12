import SwiftSyntax

@SwiftSyntaxRule
struct DiscardedNotificationCenterObserverRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "discarded_notification_center_observer",
        name: "Discarded Notification Center Observer",
        description: "When registering for a notification using a block, the opaque observer that is " +
                     "returned should be stored so it can be removed later",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }"),
            Example("""
            let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            """),
            Example("""
            func foo() -> Any {
                return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            }
            """),
            Example("""
            var obs: [Any?] = []
            obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
            """),
            Example("""
            var obs: [String: Any?] = []
            obs["foo"] = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            """),
            Example("""
            var obs: [Any?] = []
            obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
            """),
            Example("""
            func foo(_ notif: Any) {
               obs.append(notif)
            }
            foo(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
            """),
            Example("""
            var obs: [NSObjectProtocol] = [
               nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }),
               nc.addObserver(forName: .CKAccountChanged, object: nil, queue: nil, using: { })
            ]
            """)
        ],
        triggeringExamples: [
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }"),
            Example("_ = ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }"),
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })"),
            Example("""
            @discardableResult func foo() -> Any {
               return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            }
            """)
        ]
    )
}

private extension DiscardedNotificationCenterObserverRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                case .identifier("addObserver") = calledExpression.declName.baseName.tokenKind,
                case let argumentLabels = node.arguments.map({ $0.label?.text }),
                argumentLabels.starts(with: ["forName", "object", "queue"])
            else {
                return
            }

            if
                let firstParent = node.parent?.as(ReturnStmtSyntax.self),
                let secondParent = firstParent.parent?.as(CodeBlockItemSyntax.self),
                let thirdParent = secondParent.parent?.as(CodeBlockItemListSyntax.self),
                let fourthParent = thirdParent.parent?.as(CodeBlockSyntax.self),
                let fifthParent = fourthParent.parent?.as(FunctionDeclSyntax.self),
                !fifthParent.attributes.hasDiscardableResultAttribute
            {
                return // result is returned from a function
            } else if node.parent?.is(LabeledExprSyntax.self) == true {
                return // result is passed as an argument to a function
            } else if node.parent?.is(ArrayElementSyntax.self) == true {
                return // result is an array literal element
            } else if
                let previousToken = node.previousToken(viewMode: .sourceAccurate),
                case .equal = previousToken.tokenKind,
                previousToken.previousToken(viewMode: .sourceAccurate)?.tokenKind != .wildcard
            {
                return // result is assigned to something other than the wildcard keyword (`_`)
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension AttributeListSyntax {
    var hasDiscardableResultAttribute: Bool {
        contains(attributeNamed: "discardableResult")
    }
}
