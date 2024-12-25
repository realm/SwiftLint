import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct OverriddenSuperCallRule: Rule {
    var configuration = OverriddenSuperCallConfiguration()

    static let description = RuleDescription(
        identifier: "overridden_super_call",
        name: "Overridden Method Calls Super",
        description: "Some overridden methods should always call super.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {
                    super.viewWillAppear(animated)
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {
                    self.method1()
                    super.viewWillAppear(animated)
                    self.method2()
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func loadView() {
                }
            }
            """),
            Example("""
            class Some {
                func viewWillAppear(_ animated: Bool) {
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func viewDidLoad() {
                defer {
                    super.viewDidLoad()
                    }
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {↓
                    //Not calling to super
                    self.method()
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func viewWillAppear(_ animated: Bool) {↓
                    super.viewWillAppear(animated)
                    //Other code
                    super.viewWillAppear(animated)
                }
            }
            """),
            Example("""
            class VC: UIViewController {
                override func didReceiveMemoryWarning() {↓
                }
            }
            """),
        ]
    )
}

private extension OverriddenSuperCallRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body,
                  node.modifiers.contains(keyword: .override),
                  !node.modifiers.containsStaticOrClass,
                  case let name = node.resolvedName,
                  configuration.resolvedMethodNames.contains(name) else {
                return
            }

            let superCallsCount = node.numberOfCallsToSuper()
            if superCallsCount == 0 {
                violations.append(ReasonedRuleViolation(
                    position: body.leftBrace.endPositionBeforeTrailingTrivia,
                    reason: "Method '\(name)' should call to super function"
                ))
            } else if superCallsCount > 1 {
                violations.append(ReasonedRuleViolation(
                    position: body.leftBrace.endPositionBeforeTrailingTrivia,
                    reason: "Method '\(name)' should call to super only once"
                ))
            }
        }
    }
}
