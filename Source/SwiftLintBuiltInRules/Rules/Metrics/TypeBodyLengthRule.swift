import Foundation
import SwiftLintCore
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
        nonTriggeringExamples: #examples([
            "actor A {}".configuration(testConfig),
            "class C {}".configuration(testConfig),
            "enum E {}".configuration(testConfig),
            "extension E {}".configuration(testConfigWithAllTypes),
            "protocol P {}".configuration(testConfigWithAllTypes),
            "struct S {}".configuration(testConfig),
            """
                actor A {
                    let x = 0
                }
                """.configuration(testConfig),
            """
                class C {
                    let x = 0
                    // comments
                    // will
                    // be
                    // ignored
                }
                """.configuration(testConfig),
            """
                enum E {
                    let x = 0
                    // empty lines will be ignored


                }
                """.configuration(testConfig),
            """
                protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """.configuration(testConfig),
        ]),
        triggeringExamples: #examples([
            """
                ↓actor A {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """.configuration(testConfig),
            """
                ↓class C {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """.configuration(testConfig),
            """
                ↓enum E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """.configuration(testConfig),
            """
                ↓extension E {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """.configuration(testConfigWithAllTypes),
            """
                ↓protocol P {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """.configuration(testConfigWithAllTypes),
            """
                ↓struct S {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """.configuration(testConfig),
        ])
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
