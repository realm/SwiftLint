import SwiftSyntax

struct NoMagicNumbersRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = NoMagicNumbersConfiguration()

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
            """),
            Example("""
            class FooTests: XCTestCase {
                let baz: [Int] = Array(repeating: 0, count: 10)
            }

            extension FooTests {
                class Bar {
                   let baz: [Int] = Array(repeating: 0, count: 10)
                }
            }
            """),
            Example("""
            extension FooTests {
                class Bar {
                   let baz: [Int] = Array(repeating: 0, count: 10)
                }
            }

            class FooTests: XCTestCase {
                let baz: [Int] = Array(repeating: 0, count: 10)
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
        private var testClasses: Set<String> = []
        private var nonTestClasses: Set<String> = []
        private var possibleViolations: [String: [ReasonedRuleViolation]] = [:]

        init(viewMode: SyntaxTreeViewMode, testParentClasses: Set<String>) {
            self.testParentClasses = testParentClasses
            super.init(viewMode: viewMode)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            let className = node.trimmedDescription
            if node.isXCTestCase(testParentClasses) {
                testClasses.insert(className)
            } else {
                nonTestClasses.insert(className)
            }
            processPossibleViolations(forClassName: className)
        }

        override func visitPost(_ node: FloatLiteralExprSyntax) {
            guard node.floatingDigits.isMagicNumber else {
                return
            }
            let violation = node.floatingDigits.positionAfterSkippingLeadingTrivia
            process(violation: violation, forNode: node)
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            guard node.digits.isMagicNumber else {
                return
            }
            let violation = node.digits.positionAfterSkippingLeadingTrivia
            process(violation: violation, forNode: node)
        }

        private func process(violation: AbsolutePosition, forNode node: ExprSyntaxProtocol) {
            guard !node.isMemberOfATestClass(testParentClasses) else {
                return
            }
            if let extendedTypeName = node.extendedClassname() {
                if testClasses.contains(extendedTypeName) {
                    violations.append(violation)
                } else if nonTestClasses.contains(extendedTypeName) == false {
                    var possibleViolationsForClass = possibleViolations[extendedTypeName] ?? []
                    possibleViolationsForClass.append(violation)
                    possibleViolations[extendedTypeName] = possibleViolationsForClass
                }
            } else {
                violations.append(violation)
            }
        }

        private func processPossibleViolations(forClassName className: String) {
            guard let possibleViolationsForClass = possibleViolations[className] else {
                return
            }
            violations.append(contentsOf: possibleViolationsForClass)
            violations.sort(by: { $0.position < $1.position })
            possibleViolations[className] = nil
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
                classDecl.isXCTestCase(testParentClasses)
            {
                return true
            }
            parent = parent?.parent
        }
        return false
    }

    func extendedClassname() -> String? {
        var parent = parent
        while parent != nil {
            if let extensionDecl = parent?.as(ExtensionDeclSyntax.self) {
                return extensionDecl.extendedType.trimmedDescription
            }
            parent = parent?.parent
        }
        return nil
    }
}
