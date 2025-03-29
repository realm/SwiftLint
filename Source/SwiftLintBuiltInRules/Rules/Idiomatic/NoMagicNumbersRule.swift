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
            Example("#Preview { ContentView(value: 5) }"),
            Example("@Test func f() { let _ = 2 + 2 }"),
            Example("""
            @Suite struct Test {
                @Test func f() {
                    func g() { let _ = 2 + 2 }
                    let _ = 2 + 2
                }
            }
            """),
            Example("""
            @Suite actor Test {
                private var a: Int { 2 }
                @Test func f() { let _ = 2 + a }
            }
            """),
            Example("""
            class Test { // @Suite implicitly
                private var a: Int { 2 }
                @Test func f() { let _ = 2 + a }
            }
            """),
            Example("""
            #if compiler(<6.0) && compiler(>4.0)
            let a = 1
            #elseif compiler(<3.0)
            let a = 2
            #endif
            """),
            Example("""
            let myColor: UIColor = UIColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 0.52)
            """),
            Example("""
            let colorLiteral = #colorLiteral(red: 0.7019607843, green: 0.7019607843, blue: 0.7019607843, alpha: 1)
            """),
            Example("""
            let yourColor: UIColor = UIColor(hue: 0.9, saturation: 0.6, brightness: 0.333334, alpha: 1.0)
            """),
            Example("""
            let systemColor = UIColor(displayP3Red: 0.3, green: 0.8, blue: 0.5, alpha: 0.75)
            """),
            Example("""
            func createColor() -> UIColor {
                return UIColor(white: 0.5, alpha: 0.8)
            }
            """),
            Example("""
            let memberColor = UIColor.init(red: 0.5, green: 0.3, blue: 0.9, alpha: 1.0)
            """),

            Example("""
            func createMemberColor() -> UIColor {
                return UIColor.init(hue: 0.2, saturation: 0.8, brightness: 0.7, alpha: 0.5)
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
            Example("""
            #if compiler(<6.0) && compiler(>4.0)
            f(↓6.0)
            #elseif compiler(<3.0)
            f(↓3.0)
            #else
            f(↓4.0)
            #endif
            """),
        ]
    )
}

private extension NoMagicNumbersRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var testClasses: Set<String> = []
        private var nonTestClasses: Set<String> = []
        private var possibleViolations: [String: Set<AbsolutePosition>] = [:]

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isTestSuite ? .skipChildren : .visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isTestSuite ? .skipChildren : .visitChildren
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

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isTestSuite ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: FloatLiteralExprSyntax) {
            guard node.literal.isMagicNumber else {
                return
            }
            collectViolation(forNode: node)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.attributes.contains(attributeNamed: "Test") ? .skipChildren : .visitChildren
        }

        override func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
            if let elements = node.elements {
                walk(elements)
            }
            return .skipChildren
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            guard node.literal.isMagicNumber else {
                return
            }
            collectViolation(forNode: node)
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
            node.macroName.text == "Preview" ? .skipChildren : .visitChildren
        }

        override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
            node.isSimpleTupleAssignment ? .skipChildren : .visitChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isTestSuite ? .skipChildren : .visitChildren
        }

        private func collectViolation(forNode node: some ExprSyntaxProtocol) {
            if node.isMemberOfATestClass(configuration.testParentClasses) {
                return
            }
            if node.isOperandOfFreestandingShiftOperation() {
                return
            }
            if node.isPartOfUIColorInitializer() {
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

private extension DeclGroupSyntax {
    var isTestSuite: Bool {
        if attributes.contains(attributeNamed: "Suite") {
            return true
        }
        return memberBlock.members.contains {
            $0.decl.as(FunctionDeclSyntax.self)?.attributes.contains(attributeNamed: "Test") == true
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
    
    func isPartOfUIColorInitializer() -> Bool {
        guard let param = parent?.as(LabeledExprSyntax.self),
              let label = param.label?.text else {
            return false
        }
        if ["white", "alpha", "red", "displayP3Red", "green", "blue", "hue", "saturation", "brightness","cgColor", "ciColor", "resource", "patternImage"].contains(label),
           let call = param.parent?.as(LabeledExprListSyntax.self)?.parent?.as(FunctionCallExprSyntax.self) {
            if let calledExpr = call.calledExpression.as(DeclReferenceExprSyntax.self),
               calledExpr.baseName.text == "UIColor" {
                return true
            }
            if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self),
               let baseExpr = memberAccess.base?.as(DeclReferenceExprSyntax.self),
               baseExpr.baseName.text == "UIColor" {
                return true
            }
        }
        if ["red", "green", "blue", "alpha"].contains(label),
           let call = param.parent?.as(LabeledExprListSyntax.self)?.parent?.as(MacroExpansionExprSyntax.self),
           call.macroName.text == "colorLiteral" {
            return true
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
