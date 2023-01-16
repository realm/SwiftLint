import SwiftSyntax

struct UnavailableFunctionRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "unavailable_function",
        name: "Unavailable Function",
        description: "Unimplemented functions should be marked as unavailable",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            class ViewController: UIViewController {
              @available(*, unavailable)
              public required init?(coder aDecoder: NSCoder) {
                preconditionFailure("init(coder:) has not been implemented")
              }
            }
            """),
            Example("""
            func jsonValue(_ jsonString: String) -> NSObject {
               let data = jsonString.data(using: .utf8)!
               let result = try! JSONSerialization.jsonObject(with: data, options: [])
               if let dict = (result as? [String: Any])?.bridge() {
                return dict
               } else if let array = (result as? [Any])?.bridge() {
                return array
               }
               fatalError()
            }
            """),
            Example("""
            func resetOnboardingStateAndCrash() -> Never {
                resetUserDefaults()
                // Crash the app to re-start the onboarding flow.
                fatalError("Onboarding re-start crash.")
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class ViewController: UIViewController {
              public required ↓init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
              }
            }
            """),
            Example("""
            class ViewController: UIViewController {
              public required ↓init?(coder aDecoder: NSCoder) {
                let reason = "init(coder:) has not been implemented"
                fatalError(reason)
              }
            }
            """),
            Example("""
            class ViewController: UIViewController {
              public required ↓init?(coder aDecoder: NSCoder) {
                preconditionFailure("init(coder:) has not been implemented")
              }
            }
            """),
            Example("""
            ↓func resetOnboardingStateAndCrash() {
                resetUserDefaults()
                // Crash the app to re-start the onboarding flow.
                fatalError("Onboarding re-start crash.")
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension UnavailableFunctionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard !node.returnsNever,
                  !node.attributes.hasUnavailableAttribute,
                  node.body.containsTerminatingCall,
                  !node.body.containsReturn else {
                return
            }

            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard !node.attributes.hasUnavailableAttribute,
                  node.body.containsTerminatingCall,
                  !node.body.containsReturn else {
                return
            }

            violations.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionDeclSyntax {
    var returnsNever: Bool {
        if let expr = signature.output?.returnType.as(SimpleTypeIdentifierSyntax.self) {
            return expr.name.withoutTrivia().text == "Never"
        }
        return false
    }
}

private extension AttributeListSyntax? {
    var hasUnavailableAttribute: Bool {
        guard let attrs = self else {
            return false
        }

        return attrs.contains { elem in
            guard let attr = elem.as(AttributeSyntax.self),
                    let arguments = attr.argument?.as(AvailabilitySpecListSyntax.self) else {
                return false
            }

            return attr.attributeName.tokenKind == .contextualKeyword("available") && arguments.contains { arg in
                arg.entry.as(TokenSyntax.self)?.tokenKind == .contextualKeyword("unavailable")
            }
        }
    }
}

private extension CodeBlockSyntax? {
    var containsTerminatingCall: Bool {
        guard let statements = self?.statements else {
            return false
        }

        let terminatingFunctions: Set = [
            "abort",
            "fatalError",
            "preconditionFailure"
        ]

        return statements.contains { item in
            guard let function = item.item.as(FunctionCallExprSyntax.self),
                  let identifierExpr = function.calledExpression.as(IdentifierExprSyntax.self) else {
                return false
            }

            return terminatingFunctions.contains(identifierExpr.identifier.withoutTrivia().text)
        }
    }

    var containsReturn: Bool {
        guard let statements = self?.statements else {
            return false
        }

        return ReturnFinderVisitor(viewMode: .sourceAccurate)
            .walk(tree: statements, handler: \.containsReturn)
    }
}

private final class ReturnFinderVisitor: SyntaxVisitor {
    private(set) var containsReturn = false

    override func visitPost(_ node: ReturnStmtSyntax) {
        containsReturn = true
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}
