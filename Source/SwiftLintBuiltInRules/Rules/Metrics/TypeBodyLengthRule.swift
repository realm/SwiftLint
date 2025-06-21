import SwiftSyntax

@SwiftSyntaxRule
struct TypeBodyLengthRule: Rule {
    var configuration = SeverityLevelsConfiguration<Self>(warning: 250, error: 350)

    private static let testConfig = ["warning": 2]

    static let description = RuleDescription(
        identifier: "type_body_length",
        name: "Type Body Length",
        description: "Type bodies should not span too many lines",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("actor A {}", configuration: testConfig),
            Example("class C {}", configuration: testConfig),
            Example("enum E {}", configuration: testConfig),
            Example("extension E {}", configuration: testConfig),
            Example("protocol P {}", configuration: testConfig),
            Example("struct S {}", configuration: testConfig),
            Example("""
                actor A {
                    let x = 0
                }
                """, configuration: testConfig),
            Example("""
                class C {
                    let x = 0
                    // comments
                    // will
                    // be
                    // ignored
                }
                """, configuration: testConfig),
            Example("""
                enum E {
                    let x = 0
                    // empty lines will be ignored


                }
                """, configuration: testConfig),
        ],
        triggeringExamples: [
            Example("""
                ↓actor A {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: testConfig),
            Example("""
                ↓class C {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: testConfig),
            Example("""
                ↓enum E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: testConfig),
            Example("""
                ↓extension E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: testConfig),
            Example("""
                ↓protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: testConfig),
            Example("""
                ↓struct S {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: testConfig),
        ]
    )
}

private extension TypeBodyLengthRule {
    final class Visitor: BodyLengthVisitor<TypeBodyLengthRule> {
        override func visitPost(_ node: ActorDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            collectViolation(node)
        }

        private func collectViolation(_ node: some DeclGroupSyntax) {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.introducer,
                objectName: node.introducer.text.capitalized
            )
        }
    }
}
