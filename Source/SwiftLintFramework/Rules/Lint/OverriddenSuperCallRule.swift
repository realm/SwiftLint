import SwiftSyntax

struct OverriddenSuperCallRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    var configuration = OverriddenSuperCallConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "overridden_super_call",
        name: "Overridden methods call super",
        description: "Some overridden methods should always call super",
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
            """)
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
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(resolvedMethodNames: configuration.resolvedMethodNames)
    }
}

private extension OverriddenSuperCallRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let resolvedMethodNames: [String]

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            [ProtocolDeclSyntax.self]
        }

        init(resolvedMethodNames: [String]) {
            self.resolvedMethodNames = resolvedMethodNames
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body,
                  node.modifiers.containsOverride,
                  !node.modifiers.containsStaticOrClass,
                  case let name = node.resolvedName(),
                  resolvedMethodNames.contains(name) else {
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
