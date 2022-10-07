import SwiftSyntax

public struct StrictFilePrivateRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension StrictFilePrivateRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: DeclModifierSyntax) {
            if node.name.tokenKind == .fileprivateKeyword {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
