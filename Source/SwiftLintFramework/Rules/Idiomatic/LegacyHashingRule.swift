import SwiftSyntax

struct LegacyHashingRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

extension LegacyHashingRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: VariableDeclSyntax) {
            guard
                node.parent?.is(MemberDeclListItemSyntax.self) == true,
                node.letOrVarKeyword.tokenKind == .varKeyword,
                let binding = node.bindings.onlyElement,
                let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                identifier.identifier.text == "hashValue",
                let returnType = binding.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self),
                returnType.name.text == "Int"
            else {
                return
            }

            violations.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}
