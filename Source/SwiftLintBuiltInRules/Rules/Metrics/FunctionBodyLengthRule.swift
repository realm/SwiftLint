import SwiftSyntax

@SwiftSyntaxRule
struct FunctionBodyLengthRule: Rule {
    var configuration = SeverityLevelsConfiguration<Self>(warning: 50, error: 100)

    private static let testConfig = ["warning": 2]

    static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Function bodies should not span too many lines",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("func f() {}", configuration: Self.testConfig),
            Example("""
                func f() {
                    let x = 0
                }
                """, configuration: Self.testConfig),
            Example("""
                func f() {
                    let x = 0
                    let y = 1
                }
                """, configuration: Self.testConfig),
            Example("""
                func f() {
                    let x = 0
                    // comments
                    // will
                    // be
                    // ignored
                }
                """, configuration: Self.testConfig),
            Example("""
                func f() {
                    let x = 0
                    // empty lines will be ignored


                }
            """, configuration: Self.testConfig),
        ],

        triggeringExamples: [
            Example("""
                ↓func f() {
                    let x = 0
                    let y = 1
                    let z = 2
                }
                """, configuration: Self.testConfig),
            Example("""
            class C {
                ↓deinit {
                    let x = 0
                    let y = 1
                    let z = 2
                }
            }
            """, configuration: Self.testConfig),
            Example("""
            class C {
                ↓init() {
                    let x = 0
                    let y = 1
                    let z = 2
                }
            }
            """, configuration: Self.testConfig),
            Example("""
            class C {
                ↓subscript() -> Int {
                    let x = 0
                    let y = 1
                    return x + y
                }
            }
            """, configuration: Self.testConfig),
            Example("""
            struct S {
                subscript() -> Int {
                    ↓get {
                        let x = 0
                        let y = 1
                        return x + y
                    }
                    ↓set {
                        let x = 0
                        let y = 1
                        let z = 2
                    }
                    ↓willSet {
                        let x = 0
                        let y = 1
                        let z = 2
                    }
                }
            }
            """, configuration: Self.testConfig),
        ]
    )
}

private extension FunctionBodyLengthRule {
    final class Visitor: BodyLengthVisitor<ConfigurationType> {
        override func visitPost(_ node: DeinitializerDeclSyntax) {
            if let body = node.body {
                registerViolations(
                    leftBrace: body.leftBrace,
                    rightBrace: body.rightBrace,
                    violationNode: node.deinitKeyword,
                    objectName: "Deinitializer"
                )
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let body = node.body {
                registerViolations(
                    leftBrace: body.leftBrace,
                    rightBrace: body.rightBrace,
                    violationNode: node.funcKeyword,
                    objectName: "Function"
                )
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if let body = node.body {
                registerViolations(
                    leftBrace: body.leftBrace,
                    rightBrace: body.rightBrace,
                    violationNode: node.initKeyword,
                    objectName: "Initializer"
                )
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            guard let body = node.accessorBlock else {
                return
            }
            if case .getter = body.accessors {
                registerViolations(
                    leftBrace: body.leftBrace,
                    rightBrace: body.rightBrace,
                    violationNode: node.subscriptKeyword,
                    objectName: "Subscript"
                )
            }
            if case let .accessors(accessors) = body.accessors {
                for accessor in accessors {
                    guard let body = accessor.body else {
                        continue
                    }
                    registerViolations(
                        leftBrace: body.leftBrace,
                        rightBrace: body.rightBrace,
                        violationNode: accessor.accessorSpecifier,
                        objectName: "Accessor"
                    )
                }
            }
        }
    }
}
