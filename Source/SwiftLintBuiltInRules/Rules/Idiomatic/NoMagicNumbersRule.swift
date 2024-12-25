import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct NoMagicNumbersRule: Rule {
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
            class MyTest: XCTestCase {}
            extension MyTest {
                let a = Int(3)
            }
            """),
            Example("""
            extension MyTest {
                let a = Int(3)
            }
            class MyTest: XCTestCase {}
            """),
            Example("let foo = 1 << 2"),
            Example("let foo = 1 >> 2"),
            Example("let foo = 2 >> 2"),
            Example("let foo = 2 << 2"),
            Example("let a = b / 100.0"),
            Example("let range = 2 ..< 12"),
            Example("let range = ...12"),
            Example("let range = 12..."),
            Example("let (lowerBound, upperBound) = (400, 599)"),
            Example("let a = (5, 10)"),
            Example("let notFound = (statusCode: 404, description: \"Not Found\", isError: true)"),
            Example("""
            #Preview {
                ContentView(value: 5)
            }
            """),
        ],
        triggeringExamples: [
            Example("foo(↓321)"),
            Example("bar(↓1_000.005_01)"),
            Example("array[↓42]"),
            Example("let box = array[↓12 + ↓14]"),
            Example("let a = b + ↓2.0"),
            Example("let range = 2 ... ↓12 + 1"),
            Example("let range = ↓2*↓6..."),
            Example("let slice = array[↓2...↓4]"),
            Example("for i in ↓3 ..< ↓8 {}"),
            Example("let n: Int = Int(r * ↓255) << ↓16 | Int(g * ↓255) << ↓8"),
            Example("Color.primary.opacity(isAnimate ? ↓0.1 : ↓1.5)"),
            Example("""
                    class MyTest: XCTestCase {}
                    extension NSObject {
                        let a = Int(↓3)
                    }
            """),
            Example("""
            if (fileSize > ↓1000000) {
                return
            }
            """),
            Example("let imageHeight = (width - ↓24)"),
            Example("return (↓5, ↓10, ↓15)"),
            Example("""
            #ExampleMacro {
                ContentView(value: ↓5)
            }
            """),
        ]
    )
}

private extension NoMagicNumbersRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var testClasses: Set<String> = []
        private var nonTestClasses: Set<String> = []
        private var possibleViolations: [String: Set<AbsolutePosition>] = [:]

        override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
            node.isSimpleTupleAssignment ? .skipChildren : .visitChildren
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
            node.macroName.text == "Preview" ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            let className = node.name.text
            if node.isXCTestCase(configuration.testParentClasses) {
                testClasses.insert(className)
                removeViolations(forClassName: className)
            } else {
                nonTestClasses.insert(className)
            }
        }

        override func visitPost(_ node: FloatLiteralExprSyntax) {
            guard node.literal.isMagicNumber else {
                return
            }
            collectViolation(forNode: node)
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            guard node.literal.isMagicNumber else {
                return
            }
            collectViolation(forNode: node)
        }

        private func collectViolation(forNode node: some ExprSyntaxProtocol) {
            if node.isMemberOfATestClass(configuration.testParentClasses) {
                return
            }
            if node.isOperandOfFreestandingShiftOperation() {
                return
            }
            let violation = node.positionAfterSkippingLeadingTrivia
            if let extendedTypeName = node.extendedTypeName() {
                if !testClasses.contains(extendedTypeName) {
                    violations.append(violation)
                    if !nonTestClasses.contains(extendedTypeName) {
                        possibleViolations[extendedTypeName, default: []].insert(violation)
                    }
                }
            } else {
                violations.append(violation)
            }
        }

        private func removeViolations(forClassName className: String) {
            guard let possibleViolationsForClass = possibleViolations[className] else {
                return
            }
            let violationsToRemove = Set(possibleViolationsForClass.map { ReasonedRuleViolation(position: $0) })
            violations.removeAll { violationsToRemove.contains($0) }
            possibleViolations.removeValue(forKey: className)
        }
    }
}

private extension TokenSyntax {
    var isMagicNumber: Bool {
        guard let number = Double(text.replacingOccurrences(of: "_", with: "")) else {
            return false
        }
        if [0, 1, 100].contains(number) {
            return false
        }
        guard let grandparent = parent?.parent else {
            return true
        }
        if grandparent.is(InitializerClauseSyntax.self) {
            return false
        }
        let operatorParent = grandparent.as(PrefixOperatorExprSyntax.self)?.parent
                          ?? grandparent.as(PostfixOperatorExprSyntax.self)?.parent
                          ?? grandparent.asAcceptedInfixOperator?.parent
        return operatorParent?.is(InitializerClauseSyntax.self) != true
    }
}

private extension Syntax {
    var asAcceptedInfixOperator: InfixOperatorExprSyntax? {
        if let infixOp = `as`(InfixOperatorExprSyntax.self),
           let operatorSymbol = infixOp.operator.as(BinaryOperatorExprSyntax.self)?.operator.tokenKind,
           [.binaryOperator("..."), .binaryOperator("..<")].contains(operatorSymbol) {
            return infixOp
        }
        return nil
    }
}

private extension ExprSyntaxProtocol {
    func isMemberOfATestClass(_ testParentClasses: Set<String>) -> Bool {
        var parent = parent
        while parent != nil {
            if
                let classDecl = parent?.as(ClassDeclSyntax.self),
                classDecl.isXCTestCase(testParentClasses) {
                return true
            }
            parent = parent?.parent
        }
        return false
    }

    func extendedTypeName() -> String? {
        var parent = parent
        while parent != nil {
            if let extensionDecl = parent?.as(ExtensionDeclSyntax.self) {
                return extensionDecl.extendedType.trimmedDescription
            }
            parent = parent?.parent
        }
        return nil
    }

    func isOperandOfFreestandingShiftOperation() -> Bool {
        if let operation = parent?.as(InfixOperatorExprSyntax.self),
           let operatorSymbol = operation.operator.as(BinaryOperatorExprSyntax.self)?.operator.tokenKind,
           [.binaryOperator("<<"), .binaryOperator(">>")].contains(operatorSymbol) {
            return operation.parent?.isProtocol((any ExprSyntaxProtocol).self) != true
        }
        return false
    }
}

private extension PatternBindingSyntax {
    var isSimpleTupleAssignment: Bool {
        initializer?.value.as(TupleExprSyntax.self)?.elements.allSatisfy {
            $0.expression.is(IntegerLiteralExprSyntax.self) ||
            $0.expression.is(FloatLiteralExprSyntax.self) ||
            $0.expression.is(StringLiteralExprSyntax.self) ||
            $0.expression.is(BooleanLiteralExprSyntax.self)
        } ?? false
    }
}
