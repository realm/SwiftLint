import SwiftSyntax

struct DiscardedNotificationCenterObserverRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "discarded_notification_center_observer",
        name: "Discarded Notification Center Observer",
        description: "When registering for a notification using a block, the opaque observer that is " +
                     "returned should be stored so it can be removed later.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n"),
            Example("""
            let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            """),
            Example("func foo() -> Any {\n" +
            "   return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n" +
            "}\n"),
            Example("var obs: [Any?] = []\n" +
            "obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n"),
            Example("""
            var obs: [String: Any?] = []
            obs["foo"] = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            """),
            Example("var obs: [Any?] = []\n" +
            "obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n"),
            Example("func foo(_ notif: Any) {\n" +
            "   obs.append(notif)\n" +
            "}\n" +
            "foo(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n"),
            Example("""
            var obs: [NSObjectProtocol] = [
               nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }),
               nc.addObserver(forName: .CKAccountChanged, object: nil, queue: nil, using: { })
            ]
            """)
        ],
        triggeringExamples: [
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n"),
            Example("_ = ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n"),
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n"),
            Example("""
            @discardableResult func foo() -> Any {
               return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DiscardedNotificationCenterObserverRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                case .identifier("addObserver") = calledExpression.name.tokenKind,
                case let argumentLabels = node.argumentList.map({ $0.label?.text }),
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
                fifthParent.attributes?.hasDiscardableResultAttribute != true
            {
                return // result is returned from a function
            } else if node.parent?.is(TupleExprElementSyntax.self) == true {
                return // result is passed as an argument to a function
            } else if node.parent?.is(ArrayElementSyntax.self) == true {
                return // result is an array literal element
            } else if
                let previousToken = node.previousToken,
                case .equal = previousToken.tokenKind,
                previousToken.previousToken?.tokenKind != .wildcardKeyword
            {
                return // result is assigned to something other than the wildcard keyword (`_`)
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension AttributeListSyntax {
    var hasDiscardableResultAttribute: Bool {
        contains { $0.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("discardableResult") } == true
    }
}
