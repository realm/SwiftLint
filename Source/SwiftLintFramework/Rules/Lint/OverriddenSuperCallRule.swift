import SwiftSyntax

public struct OverriddenSuperCallRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    public var configuration = OverriddenSuperCallConfiguration()

    public init() {}

    public static let description = RuleDescription(
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(resolvedMethodNames: configuration.resolvedMethodNames)
    }
}

private extension OverriddenSuperCallRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let resolvedMethodNames: [String]

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

            let superCallsCount = SuperCallVisitor(expectedFunctionName: node.identifier.text)
                .walk(tree: body, handler: \.superCallsCount)

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

    final class SuperCallVisitor: SyntaxVisitor {
        private let expectedFunctionName: String
        private(set) var superCallsCount = 0

        init(expectedFunctionName: String) {
            self.expectedFunctionName = expectedFunctionName
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let expr = node.calledExpression.as(MemberAccessExprSyntax.self),
                  expr.base?.as(SuperRefExprSyntax.self) != nil,
                  expr.name.text == expectedFunctionName else {
                return
            }

            superCallsCount += 1
        }
    }
}

private extension FunctionDeclSyntax {
    func resolvedName() -> String {
        var name = self.identifier.text
        name += "("

        let params = signature.input.parameterList.compactMap { param in
            (param.firstName ?? param.secondName)?.text.appending(":")
        }

        name += params.joined()
        name += ")"
        return name
    }
}
