import SwiftSyntax

struct NoMagicNumbersRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    init() {}

    var configuration = NoMagicNumbersRuleConfiguration()

    static let description = RuleDescription(
        identifier: "no_magic_numbers",
        name: "No Magic Numbers",
        description: "Magic numbers should be replaced by named constants",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var foo = 123"),
            Example("static let bar: Double = 0.123"),
            Example("let a = b + 1.0"),
            Example("array[0] + array[1] "),
            Example("let foo = 1_000.000_01"),
            Example("// array[1337]"),
            Example("baz(\"9999\")"),
            Example("""
            func foo() {
                let x: Int = 2
                let y = 3
                let vector = [x, y, -1]
            }
            """),
            Example("""
            class A {
                var foo: Double = 132
                static let bar: Double = 0.98
            }
            """),
            Example("""
            @available(iOS 13, *)
            func version() {
                if #available(iOS 13, OSX 10.10, *) {
                    return
                }
            }
            """),
            Example("""
            enum Example: Int {
                case positive = 2
                case negative = -2
            }
            """),
            Example("""
            class FooTests: XCTestCase {
                let array: [Int] = []
                let bar = array[42]
            }
            """),
            Example("""
            class FooTests: XCTestCase {
                class Bar {
                    let array: [Int] = []
                    let bar = array[42]
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("foo(↓321)"),
            Example("bar(↓1_000.005_01)"),
            Example("array[↓42]"),
            Example("let box = array[↓12 + ↓14]"),
            Example("let a = b + ↓2.0"),
            Example("Color.primary.opacity(isAnimate ? ↓0.1 : ↓1.5)")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate, testParentClasses: configuration.testParentClasses)
    }
}

private extension NoMagicNumbersRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let testParentClasses: Set<String>

        init(viewMode: SyntaxTreeViewMode, testParentClasses: Set<String>) {
            self.testParentClasses = testParentClasses
            super.init(viewMode: viewMode)
        }

        override func visitPost(_ node: FloatLiteralExprSyntax) {
            if node.isMemberOfATestClass(testParentClasses) == false, node.floatingDigits.isMagicNumber {
                violations.append(node.floatingDigits.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            if node.isMemberOfATestClass(testParentClasses) == false, node.digits.isMagicNumber {
                violations.append(node.digits.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension TokenSyntax {
    var isMagicNumber: Bool {
        guard let number = Double(text.replacingOccurrences(of: "_", with: "")) else {
            return false
        }
        if [0, 1].contains(number) {
            return false
        }
        guard let grandparent = parent?.parent else {
            return true
        }
        return !grandparent.is(InitializerClauseSyntax.self)
            && grandparent.as(PrefixOperatorExprSyntax.self)?.parent?.is(InitializerClauseSyntax.self) != true
    }
}

private extension ExprSyntaxProtocol {
    func isMemberOfATestClass(_ testParentClasses: Set<String>) -> Bool {
        var parent = parent
        while parent != nil {
            if
                let classDecl = parent?.as(ClassDeclSyntax.self),
                classDecl.isTestClass(testParentClasses: testParentClasses)
            {
                return true
            }
            parent = parent?.parent
        }
        return false
    }
}

private extension ClassDeclSyntax {
    func isTestClass(testParentClasses: Set<String>) -> Bool {
        inheritanceClause.containsInheritedType(inheritedTypes: testParentClasses)
    }
}
