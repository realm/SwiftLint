import SwiftSyntax

@SwiftSyntaxRule
struct LegacyHashingRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_hashing",
        name: "Legacy Hashing",
        description: "Prefer using the `hash(into:)` function instead of overriding `hashValue`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            struct Foo: Hashable {
              let bar: Int = 10

              func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
              }
            }
            """),
            Example("""
            class Foo: Hashable {
              let bar: Int = 10

              func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
              }
            }
            """),
            Example("""
            var hashValue: Int { return 1 }
            class Foo: Hashable { \n }
            """),
            Example("""
            class Foo: Hashable {
              let bar: String = "Foo"

              public var hashValue: String {
                return bar
              }
            }
            """),
            Example("""
            class Foo: Hashable {
              let bar: String = "Foo"

              public var hashValue: String {
                get { return bar }
                set { bar = newValue }
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct Foo: Hashable {
                let bar: Int = 10

                public ↓var hashValue: Int {
                    return bar
                }
            }
            """),
            Example("""
            class Foo: Hashable {
                let bar: Int = 10

                public ↓var hashValue: Int {
                    return bar
                }
            }
            """)
        ]
    )
}

private extension LegacyHashingRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: VariableDeclSyntax) {
            guard
                node.parent?.is(MemberBlockItemSyntax.self) == true,
                node.bindingSpecifier.tokenKind == .keyword(.var),
                let binding = node.bindings.onlyElement,
                let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                identifier.identifier.text == "hashValue",
                let returnType = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self),
                returnType.name.text == "Int"
            else {
                return
            }

            violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
        }
    }
}
