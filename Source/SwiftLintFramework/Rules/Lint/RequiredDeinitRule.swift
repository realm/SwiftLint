import SwiftSyntax

/// Rule to require all classes to have a deinit method
///
/// An example of when this is useful is if the project does allocation tracking
/// of objects and the deinit should print a message or remove its instance from a
/// list of allocations. Even having an empty deinit method is useful to provide
/// a place to put a breakpoint when chasing down leaks.
struct RequiredDeinitRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "required_deinit",
        name: "Required Deinit",
        description: "Classes should have an explicit deinit method",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class Apple {
                deinit { }
            }
            """),
            Example("enum Banana { }"),
            Example("protocol Cherry { }"),
            Example("struct Damson { }"),
            Example("""
            class Outer {
                deinit { print("Deinit Outer") }
                class Inner {
                    deinit { print("Deinit Inner") }
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("↓class Apple { }"),
            Example("↓class Banana: NSObject, Equatable { }"),
            Example("""
            ↓class Cherry {
                // deinit { }
            }
            """),
            Example("""
            ↓class Damson {
                func deinitialize() { }
            }
            """),
            Example("""
            class Outer {
                func hello() -> String { return "outer" }
                deinit { }
                ↓class Inner {
                    func hello() -> String { return "inner" }
                }
            }
            """),
            Example("""
            ↓class Outer {
                func hello() -> String { return "outer" }
                class Inner {
                    func hello() -> String { return "inner" }
                    deinit { }
                }
            }
            """)
        ]
    )

    init() {}

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension RequiredDeinitRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ClassDeclSyntax) {
            let visitor = DeinitVisitor(viewMode: .sourceAccurate)
            if !visitor.walk(tree: node.members, handler: \.hasDeinit) {
                violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private class DeinitVisitor: ViolationsSyntaxVisitor {
    private(set) var hasDeinit = false

    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

    override func visitPost(_ node: DeinitializerDeclSyntax) {
        hasDeinit = true
    }
}
