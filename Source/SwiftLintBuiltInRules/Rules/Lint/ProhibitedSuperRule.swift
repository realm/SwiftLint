import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ProhibitedSuperRule: Rule {
    var configuration = ProhibitedSuperConfiguration()

    static let description = RuleDescription(
        identifier: "prohibited_super_call",
        name: "Prohibited Calls to Super",
        description: "Some methods should not call super.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class VC: UIViewController {
                override func loadView() {
                }
            }
            """),
            Example("""
            class NSView {
                func updateLayer() {
                    self.method1()
                }
            }
            """),
            Example("""
            public class FileProviderExtension: NSFileProviderExtension {
                override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
                    guard let identifier = persistentIdentifierForItem(at: url) else {
                        completionHandler(NSFileProviderError(.noSuchItem))
                        return
                    }
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            class VC: UIViewController {
                override func loadView() {↓
                    super.loadView()
                }
            }
            """),
            Example("""
            class VC: NSFileProviderExtension {
                override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {↓
                    self.method1()
                    super.providePlaceholder(at:url, completionHandler: completionHandler)
                }
            }
            """),
            Example("""
            class VC: NSView {
                override func updateLayer() {↓
                    self.method1()
                    super.updateLayer()
                    self.method2()
                }
            }
            """),
            Example("""
            class VC: NSView {
                override func updateLayer() {↓
                    defer {
                        super.updateLayer()
                    }
                }
            }
            """),
        ]
    )
}

private extension ProhibitedSuperRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body,
                  node.modifiers.contains(keyword: .override),
                  !node.modifiers.containsStaticOrClass,
                  case let name = node.resolvedName,
                  configuration.resolvedMethodNames.contains(name),
                  node.numberOfCallsToSuper() > 0 else {
                return
            }

            violations.append(ReasonedRuleViolation(
                position: body.leftBrace.endPositionBeforeTrailingTrivia,
                reason: "Method '\(name)' should not call to super function"
            ))
        }
    }
}
