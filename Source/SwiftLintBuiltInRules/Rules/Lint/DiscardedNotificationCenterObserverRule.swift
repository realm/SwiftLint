import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DiscardedNotificationCenterObserverRule: Rule {
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
            func foo() -> Any {
                nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
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
            func foo(_ notify: Any) {
               obs.append(notify)
            }
            foo(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
            """),
            Example("""
            var obs: [NSObjectProtocol] = [
               nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }),
               nc.addObserver(forName: .CKAccountChanged, object: nil, queue: nil, using: { })
            ]
            """),
            Example("""
            names.map { self.notificationCenter.addObserver(forName: $0, object: object, queue: queue, using: block) }
            """),
            Example("""
            f { return nc.addObserver(forName: $0, object: object, queue: queue, using: block) }
            """),
        ],
        triggeringExamples: [
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }"),
            Example("_ = ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }"),
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })"),
            Example("""
            @discardableResult func foo() -> Any {
               return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            }
            """),
            Example("""
            class C {
                var i: Int {
                    set { ↓notificationCenter.addObserver(forName: $0, object: object, queue: queue, using: block) }
                    get {
                        ↓notificationCenter.addObserver(forName: $0, object: object, queue: queue, using: block)
                        return 2
                    }
                }
            }
            """),
            Example("""
            f {
                ↓nc.addObserver(forName: $0, object: object, queue: queue) {}
                return 2
            }
            """),
            Example("""
            func foo() -> Any {
                if cond {
                    ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
                }
            }
            """),
        ]
    )
}

private enum CodeBlockScope: Equatable {
    case file
    case function(decl: FunctionDeclSyntax)
    case getter(block: CodeBlockItemListSyntax)
    case setter
    case closure(block: CodeBlockItemListSyntax)
}

private extension DiscardedNotificationCenterObserverRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        var scopes = Stack<CodeBlockScope>()

        override func visit(_: SourceFileSyntax) -> SyntaxVisitorContinueKind {
            scopes.push(.file)
            return .visitChildren
        }

        override func visitPost(_: SourceFileSyntax) {
            scopes.pop()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            scopes.push(.function(decl: node))
            return .visitChildren
        }

        override func visitPost(_: FunctionDeclSyntax) {
            scopes.pop()
        }

        override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
            if case let .getter(block) = node.accessors {
                scopes.push(.getter(block: block))
            }
            return .visitChildren
        }

        override func visitPost(_: AccessorBlockSyntax) {
            scopes.pop()
        }

        override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.accessorSpecifier.text == "get", let block = node.body?.statements {
                scopes.push(.getter(block: block))
            } else if node.accessorSpecifier.text == "set" {
                scopes.push(.setter)
            }
            return .visitChildren
        }

        override func visitPost(_: AccessorDeclSyntax) {
            scopes.pop()
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            scopes.push(.closure(block: node.statements))
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            scopes.pop()
        }

        // swiftlint:disable:next cyclomatic_complexity
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                  case .identifier("addObserver") = calledExpression.declName.baseName.tokenKind,
                  case let argumentLabels = node.arguments.map({ $0.label?.text }),
                  argumentLabels.starts(with: ["forName", "object", "queue"]),
                  let parent = node.parent else {
                return
            }
            if let funcBlock = parent.as(CodeBlockItemSyntax.self)?.parent?.as(CodeBlockItemListSyntax.self) {
                switch scopes.peek() {
                case let .closure(block) where funcBlock.count == 1 && block == funcBlock: return
                case let .getter(block) where funcBlock.count == 1 && block == funcBlock: return
                case let .function(functionDecl) where funcBlock.count == 1 &&
                                                       functionDecl.body?.statements == funcBlock &&
                                                       functionDecl.signature.returnClause != nil &&
                                                       !functionDecl.hasDiscardableResultAttribute: return
                default: break
                }
            } else if parent.is(ReturnStmtSyntax.self) {
                switch scopes.peek() {
                case .closure, .getter: return
                case let .function(decl: functionDecl) where !functionDecl.hasDiscardableResultAttribute: return
                default: break
                }
            } else if parent.is(LabeledExprSyntax.self) {
                return // result is passed as an argument to a function
            } else if parent.is(ArrayElementSyntax.self) {
                return // result is an array literal element
            } else if
                let previousToken = node.previousToken(viewMode: .sourceAccurate),
                case .equal = previousToken.tokenKind,
                previousToken.previousToken(viewMode: .sourceAccurate)?.tokenKind != .wildcard {
                return // result is assigned to something other than the wildcard keyword (`_`)
            }
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionDeclSyntax {
    var hasDiscardableResultAttribute: Bool {
        attributes.contains(attributeNamed: "discardableResult")
    }
}
