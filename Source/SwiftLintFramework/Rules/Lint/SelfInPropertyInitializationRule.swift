import SwiftSyntax

struct SelfInPropertyInitializationRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "self_in_property_initialization",
        name: "Self in Property Initialization",
        description: "`self` refers to the unapplied `NSObject.self()` method, which is likely not expected; " +
            "make the variable `lazy` to be able to refer to the current instance or use `ClassName.self`",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class View: UIView {
                let button: UIButton = {
                    return UIButton()
                }()
            }
            """),
            Example("""
            class View: UIView {
                lazy var button: UIButton = {
                    let button = UIButton()
                    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """),
            Example("""
            class View: UIView {
                var button: UIButton = {
                    let button = UIButton()
                    button.addTarget(otherObject, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """),
            Example("""
            class View: UIView {
                private let collectionView: UICollectionView = {
                    let layout = UICollectionViewFlowLayout()
                    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
                    collectionView.registerReusable(Cell.self)

                    return collectionView
                }()
            }
            """),
            Example("""
            class Foo {
                var bar: Bool = false {
                    didSet {
                        value = {
                            if bar {
                                return self.calculateA()
                            } else {
                                return self.calculateB()
                            }
                        }()
                        print(value)
                    }
                }

                var value: String?

                func calculateA() -> String { "A" }
                func calculateB() -> String { "B" }
            }
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("""
            class View: UIView {
                ↓var button: UIButton = {
                    let button = UIButton()
                    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """),
            Example("""
            class View: UIView {
                ↓let button: UIButton = {
                    let button = UIButton()
                    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension SelfInPropertyInitializationRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: VariableDeclSyntax) {
            guard !node.modifiers.containsLazy,
                  !node.modifiers.containsStaticOrClass,
                  let closestDecl = node.closestDecl(),
                  closestDecl.is(ClassDeclSyntax.self) else {
                return
            }

            let visitor = IdentifierUsageVisitor(identifier: .selfKeyword)
            for binding in node.bindings {
                guard let initializer = binding.initializer,
                      visitor.walk(tree: initializer.value, handler: \.isTokenUsed) else {
                    continue
                }

                violations.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class IdentifierUsageVisitor: SyntaxVisitor {
        let identifier: TokenKind
        private(set) var isTokenUsed = false

        init(identifier: TokenKind) {
            self.identifier = identifier
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: IdentifierExprSyntax) {
            if node.identifier.tokenKind == identifier {
                isTokenUsed = true
            }
        }
    }
}

private extension SyntaxProtocol {
    func closestDecl() -> DeclSyntax? {
        if let decl = self.parent?.as(DeclSyntax.self) {
            return decl
        }

        return parent?.closestDecl()
    }
}
