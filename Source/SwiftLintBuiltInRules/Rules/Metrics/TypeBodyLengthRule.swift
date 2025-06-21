import SwiftSyntax

@SwiftSyntaxRule
struct TypeBodyLengthRule: Rule {
    var configuration = TypeBodyLengthConfiguration()

    private static let testConfig = ["warning": 2] as [String: any Sendable]
    private static let testConfigWithAllTypes = testConfig.merging(
        ["excluded_types": [] as [String]],
        uniquingKeysWith: { $1 }
    )

    static let description = RuleDescription(
        identifier: "type_body_length",
        name: "Type Body Length",
        description: "Type bodies should not span too many lines",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("actor A {}", configuration: testConfig),
            Example("class C {}", configuration: testConfig),
            Example("enum E {}", configuration: testConfig),
            Example("extension E {}", configuration: testConfigWithAllTypes),
            Example("protocol P {}", configuration: testConfigWithAllTypes),
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
            Example("""
                protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
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
                """, configuration: testConfigWithAllTypes),
            Example("""
                ↓protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: testConfigWithAllTypes),
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
    final class Visitor: BodyLengthVisitor<ConfigurationType> {
        override func visitPost(_ node: ActorDeclSyntax) {
            if !configuration.excludedTypes.contains(.actor) {
                collectViolation(node)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if !configuration.excludedTypes.contains(.class) {
                collectViolation(node)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if !configuration.excludedTypes.contains(.enum) {
                collectViolation(node)
            }
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if !configuration.excludedTypes.contains(.extension) {
                collectViolation(node)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if !configuration.excludedTypes.contains(.protocol) {
                collectViolation(node)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if !configuration.excludedTypes.contains(.struct) {
                collectViolation(node)
            }
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
