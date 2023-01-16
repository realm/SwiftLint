import SwiftSyntax

struct WeakDelegateRule: OptInRule, SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "weak_delegate",
        name: "Weak Delegate",
        description: "Delegates should be weak to avoid reference cycles",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo {\n  weak var delegate: SomeProtocol?\n}\n"),
            Example("class Foo {\n  weak var someDelegate: SomeDelegateProtocol?\n}\n"),
            Example("class Foo {\n  weak var delegateScroll: ScrollDelegate?\n}\n"),
            // We only consider properties to be a delegate if it has "delegate" in its name
            Example("class Foo {\n  var scrollHandler: ScrollDelegate?\n}\n"),
            // Only trigger on instance variables, not local variables
            Example("func foo() {\n  var delegate: SomeDelegate\n}\n"),
            // Only trigger when variable has the suffix "-delegate" to avoid false positives
            Example("class Foo {\n  var delegateNotified: Bool?\n}\n"),
            // There's no way to declare a property weak in a protocol
            Example("protocol P {\n var delegate: AnyObject? { get set }\n}\n"),
            Example("class Foo {\n protocol P {\n var delegate: AnyObject? { get set }\n}\n}\n"),
            Example("class Foo {\n var computedDelegate: ComputedDelegate {\n return bar() \n} \n}"),
            Example("""
            class Foo {
                var computedDelegate: ComputedDelegate {
                    get {
                        return bar()
                    }
               }
            """),
            Example("struct Foo {\n @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate \n}"),
            Example("struct Foo {\n @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate \n}"),
            Example("struct Foo {\n @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate \n}"),
            Example("""
            class Foo {
                func makeDelegate() -> SomeDelegate {
                    let delegate = SomeDelegate()
                    return delegate
                }
            }
            """),
            Example("""
            class Foo {
                var bar: Bool {
                    let appDelegate = AppDelegate.bar
                    return appDelegate.bar
                }
            }
            """, excludeFromDocumentation: true),
            Example("private var appDelegate: String?", excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("class Foo {\n  ↓var delegate: SomeProtocol?\n}\n"),
            Example("class Foo {\n  ↓var scrollDelegate: ScrollDelegate?\n}\n"),
            Example("""
            class Foo {
                ↓var delegate: SomeProtocol? {
                    didSet {
                        print("Updated delegate")
                    }
               }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension WeakDelegateRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            [
                ProtocolDeclSyntax.self
            ]
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard node.hasDelegateSuffix,
                  node.weakOrUnownedModifier == nil,
                 !node.hasComputedBody,
                 !node.containsIgnoredAttribute,
                  let parent = node.parent,
                  Syntax(parent).enclosingClass() != nil else {
                return
            }

            violations.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension Syntax {
    func enclosingClass() -> ClassDeclSyntax? {
        if let classExpr = self.as(ClassDeclSyntax.self) {
            return classExpr
        } else if self.as(DeclSyntax.self) != nil {
            return nil
        }

        return parent?.enclosingClass()
    }
}

private extension VariableDeclSyntax {
    var hasDelegateSuffix: Bool {
        bindings.allSatisfy { binding in
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                return false
            }

            return pattern.identifier.withoutTrivia().text.lowercased().hasSuffix("delegate")
        }
    }

    var hasComputedBody: Bool {
        bindings.allSatisfy { binding in
            guard let accessor = binding.accessor else {
                return false
            }

            if accessor.is(CodeBlockSyntax.self) {
                return true
            } else if accessor.as(AccessorBlockSyntax.self)?.getAccessor != nil {
                return true
            }

            return false
        }
    }

    var containsIgnoredAttribute: Bool {
        let ignoredAttributes: Set = [
            "UIApplicationDelegateAdaptor",
            "NSApplicationDelegateAdaptor",
            "WKExtensionDelegateAdaptor"
        ]

        return attributes?.contains { attr in
            guard let customAttr = attr.as(CustomAttributeSyntax.self),
                  let typeIdentifier = customAttr.attributeName.as(SimpleTypeIdentifierSyntax.self) else {
                return false
            }

            return ignoredAttributes.contains(typeIdentifier.name.withoutTrivia().text)
        } ?? false
    }
}
