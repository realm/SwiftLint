import SwiftSyntax

struct StrictFilePrivateRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "strict_fileprivate",
        name: "Strict fileprivate",
        description: "`fileprivate` should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("extension String {}"),
            Example("private extension String {}"),
            Example("""
            public
            extension String {}
            """),
            Example("""
            open extension
              String {}
            """),
            Example("internal extension String {}")
        ],
        triggeringExamples: [
            Example("↓fileprivate extension String {}"),
            Example("""
            ↓fileprivate
              extension String {}
            """),
            Example("""
            ↓fileprivate extension
              String {}
            """),
            Example("""
            extension String {
              ↓fileprivate func Something(){}
            }
            """),
            Example("""
            class MyClass {
              ↓fileprivate let myInt = 4
            }
            """),
            Example("""
            class MyClass {
              ↓fileprivate(set) var myInt = 4
            }
            """),
            Example("""
            struct Outter {
              struct Inter {
                ↓fileprivate struct Inner {}
              }
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension StrictFilePrivateRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: DeclModifierSyntax) {
            if node.name.tokenKind == .fileprivateKeyword {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
