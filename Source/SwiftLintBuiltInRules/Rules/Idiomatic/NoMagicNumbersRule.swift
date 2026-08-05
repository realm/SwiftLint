// swiftlint:disable file_length

import Foundation
import SwiftLintCore
import SwiftSyntax

private let colorTypeNames: Set<String> = [
    "UIColor", "UIKit.UIColor",
    "NSColor", "AppKit.NSColor",
    "Color", "SwiftUI.Color",
]

/// Argument labels of the color components of a `UIColor`, `NSColor` or SwiftUI `Color` initializer. A numeric
/// literal passed for one of them is a color value rather than a magic number.
///
/// AppKit encodes the color space in the label of the first component, hence variants like `srgbRed`.
private let colorComponentLabels: Set<String> = [
    "white", "calibratedWhite", "deviceWhite", "genericGamma22White",
    "red", "calibratedRed", "deviceRed", "srgbRed", "displayP3Red",
    "green", "blue", "alpha", "opacity",
    "hue", "calibratedHue", "deviceHue", "saturation", "brightness",
    "deviceCyan", "magenta", "yellow", "black",
    "cgColor", "ciColor", "resource", "patternImage",
]

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct NoMagicNumbersRule: Rule {
    var configuration = NoMagicNumbersConfiguration()

    static let description = RuleDescription(
        identifier: "no_magic_numbers",
        name: "No Magic Numbers",
        description: "Magic numbers should be replaced by named constants",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "var foo = 123",
            "static let bar: Double = 0.123",
            "let a = b + 1.0",
            "array[0] + array[1] ",
            "let foo = 1_000.000_01",
            "// array[1337]",
            "baz(\"9999\")",
            """
            func foo() {
                let x: Int = 2
                let y = 3
                let vector = [x, y, -1]
            }
            """,
            """
            class A {
                var foo: Double = 132
                static let bar: Double = 0.98
            }
            """,
            """
            @available(iOS 13, *)
            func version() {
                if #available(iOS 13, OSX 10.10, *) {
                    return
                }
            }
            """,
            """
            enum Example: Int {
                case positive = 2
                case negative = -2
            }
            """,
            """
            class FooTests: XCTestCase {
                let array: [Int] = []
                let bar = array[42]
            }
            """,
            """
            class FooTests: XCTestCase {
                class Bar {
                    let array: [Int] = []
                    let bar = array[42]
                }
            }
            """,
            """
            class MyTest: XCTestCase {}
            extension MyTest {
                let a = Int(3)
            }
            """,
            """
            extension MyTest {
                let a = Int(3)
            }
            class MyTest: XCTestCase {}
            """,
            "let foo = 1 << 2",
            "let foo = 1 >> 2",
            "let foo = 2 >> 2",
            "let foo = 2 << 2",
            "let a = b / 100.0",
            "let range = 2 ..< 12",
            "let range = ...12",
            "let range = 12...",
            "let (lowerBound, upperBound) = (400, 599)",
            "let a = (5, 10)",
            "let notFound = (statusCode: 404, description: \"Not Found\", isError: true)",
            "#Preview { ContentView(value: 5) }",
            "@Test func f() { let _ = 2 + 2 }",
            """
            @Suite struct Test {
                @Test func f() {
                    func g() { let _ = 2 + 2 }
                    let _ = 2 + 2
                }
            }
            """,
            """
            @Suite actor Test {
                private var a: Int { 2 }
                @Test func f() { let _ = 2 + a }
            }
            """,
            """
            class Test { // @Suite implicitly
                private var a: Int { 2 }
                @Test func f() { let _ = 2 + a }
            }
            """,
            """
            #if compiler(<6.0) && compiler(>4.0)
            let a = 1
            #elseif compiler(<3.0)
            let a = 2
            #endif
            """,
            """
            let myColor: UIColor = UIColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 0.52)
            """,
            """
            let colorLiteral = #colorLiteral(red: 0.7019607843, green: 0.7019607843, blue: 0.7019607843, alpha: 1)
            """,
            """
            let yourColor: UIColor = UIColor(hue: 0.9, saturation: 0.6, brightness: 0.333334, alpha: 1.0)
            """.asExample(excludeFromDocumentation: true),
            """
            let systemColor = UIColor(displayP3Red: 0.3, green: 0.8, blue: 0.5, alpha: 0.75)
            """.asExample(excludeFromDocumentation: true),
            """
            func createColor() -> UIColor {
                return UIColor(white: 0.5, alpha: 0.8)
            }
            """.asExample(excludeFromDocumentation: true),
            """
            let memberColor = UIColor.init(red: 0.5, green: 0.3, blue: 0.9, alpha: 1.0)
            """.asExample(excludeFromDocumentation: true),
            """
            func createMemberColor() -> UIColor {
                return UIColor.init(hue: 0.2, saturation: 0.8, brightness: 0.7, alpha: 0.5)
            }
            """.asExample(excludeFromDocumentation: true),
            """
            let swiftUIColor = Color(red: 0.1, green: 0.42, blue: 0.7)
            """.asExample(excludeFromDocumentation: true),
            """
            let opaqueColor = Color(.sRGB, red: 0.1, green: 0.42, blue: 0.7, opacity: 0.5)
            """.asExample(excludeFromDocumentation: true),
            """
            let appKitColor = NSColor(red: 0.1, green: 0.42, blue: 0.7, alpha: 0.5)
            """.asExample(excludeFromDocumentation: true),
            """
            let computedColor = Color(red: 0x19 / 255, green: 0x7A / 255, blue: 0x3C / 255)
            """.asExample(excludeFromDocumentation: true),
            """
            let computedUIColor = UIColor(red: 0x19 / 255, green: 0x7A / 255, blue: 0x3C / 255, alpha: 1)
            """.asExample(excludeFromDocumentation: true),
            """
            let convertedColor = Color(red: Double(0x19) / 255, green: (0x7A - 0x19) / 255, blue: 0)
            """.asExample(excludeFromDocumentation: true),
            """
            let shiftedColor = Color(hue: 0.9, saturation: 0.6, brightness: -0.3 + 1, opacity: 1)
            """.asExample(excludeFromDocumentation: true),
            """
            let calibratedColor = NSColor(calibratedRed: 0.1, green: 0.42, blue: 0.7, alpha: 1)
            """.asExample(excludeFromDocumentation: true),
            """
            let sRGBColor = NSColor(srgbRed: 0x19 / 255, green: 0x7A / 255, blue: 0x3C / 255, alpha: 1)
            """.asExample(excludeFromDocumentation: true),
            """
            let gammaColor = NSColor(genericGamma22White: 0.5, alpha: 0.8)
            """.asExample(excludeFromDocumentation: true),
            """
            let cmykColor = NSColor(deviceCyan: 0.1, magenta: 0.2, yellow: 0.3, black: 0.4, alpha: 1)
            """.asExample(excludeFromDocumentation: true),
            """
            let spacedColor = NSColor(colorSpace: .sRGB, hue: 0.9, saturation: 0.6, brightness: 0.3, alpha: 1)
            """.asExample(excludeFromDocumentation: true),
            """
            let memberAppKitColor = NSColor.init(deviceRed: 0.5, green: 0.3, blue: 0.9, alpha: 1.0)
            """.asExample(excludeFromDocumentation: true),
            """
            let qualifiedSwiftUIColor = SwiftUI.Color(red: 0.1, green: 0.42, blue: 0.7)
            """.asExample(excludeFromDocumentation: true),
            """
            let qualifiedAppKitColor = AppKit.NSColor(srgbRed: 0.1, green: 0.42, blue: 0.7, alpha: 0.5)
            """.asExample(excludeFromDocumentation: true),
            """
            let qualifiedUIKitColor = UIKit.UIColor.init(red: 0.1, green: 0.42, blue: 0.7, alpha: 0.5)
            """.asExample(excludeFromDocumentation: true),
            "let a = b + 2".asExample(configuration: ["allowed_numbers": [2]], excludeFromDocumentation: true),
            "let a = b + 2".asExample(configuration: ["allowed_numbers": [2.0]], excludeFromDocumentation: true),
            "let a = b + 1".asExample(configuration: ["allowed_numbers": [2.0]], excludeFromDocumentation: true),
            "let a = b + 2.5".asExample(configuration: ["allowed_numbers": [2.5]], excludeFromDocumentation: true),
        ]),
        triggeringExamples: #examples([
            "foo(↓321)",
            "bar(↓1_000.005_01)",
            "array[↓42]",
            "let box = array[↓12 + ↓14]",
            "let a = b + ↓2.0",
            "let range = 2 ... ↓12 + 1",
            "let range = ↓2*↓6...",
            "let slice = array[↓2...↓4]",
            "for i in ↓3 ..< ↓8 {}",
            "let n: Int = Int(r * ↓255) << ↓16 | Int(g * ↓255) << ↓8",
            "Color.primary.opacity(isAnimate ? ↓0.1 : ↓1.5)",
            """
                    class MyTest: XCTestCase {}
                    extension NSObject {
                        let a = Int(↓3)
                    }
            """,
            """
            if (fileSize > ↓1000000) {
                return
            }
            """,
            "let imageHeight = (width - ↓24)",
            "return (↓5, ↓10, ↓15)",
            """
            #ExampleMacro {
                ContentView(value: ↓5)
            }
            """,
            """
            #if compiler(<6.0) && compiler(>4.0)
            f(↓6.0)
            #elseif compiler(<3.0)
            f(↓3.0)
            #else
            f(↓4.0)
            #endif
            """,
            "let paint = Paint(red: ↓0.5, green: ↓0.42, blue: ↓0.7)".asExample(excludeFromDocumentation: true),
            """
            let scaled = UIColor(white: 0.5, alpha: 1).cgColor.alpha * ↓2.5
            """.asExample(excludeFromDocumentation: true),
            """
            let faded = Color(red: 0.1, green: 0.42, blue: 0.7).opacity(↓0.42)
            """.asExample(excludeFromDocumentation: true),
            """
            let clamped = Color(red: max(↓0.5, ↓0.2), green: 0, blue: 0)
            """.asExample(excludeFromDocumentation: true),
            """
            let customColor = UIColor(rgb: ↓0x33373A, alpha: 0.16)
            """.asExample(excludeFromDocumentation: true),
            """
            let namespacedColor = DesignSystem.Color(red: ↓0.5, green: ↓0.42, blue: ↓0.7)
            """.asExample(excludeFromDocumentation: true),
            "let a = b + ↓3".asExample(configuration: ["allowed_numbers": [2.0]], excludeFromDocumentation: true),
        ])
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
            guard node.literal.isMagicNumber(configuration.allowedNumbers) else {
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
            guard node.literal.isMagicNumber(configuration.allowedNumbers) else {
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
            if node.isPartOfColorInitializer() {
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
    func isMagicNumber(_ allowedNumbers: Set<Double>) -> Bool {
        guard let number = Double(text.replacingOccurrences(of: "_", with: "")) else {
            return false
        }
        if allowedNumbers.contains(number) {
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

    /// Whether this node is an arithmetic operation a numeric literal may be an operand of.
    var isArithmeticOperation: Bool {
        if let operation = `as`(InfixOperatorExprSyntax.self) {
            guard let operatorSymbol = operation.operator.as(BinaryOperatorExprSyntax.self)?.operator.text else {
                return false
            }
            return ["+", "-", "*", "/", "%"].contains(operatorSymbol)
        }
        return `is`(PrefixOperatorExprSyntax.self)
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

    func isPartOfColorInitializer() -> Bool {
        guard let param = enclosingCallArgument(),
              let label = param.label?.text,
              let arguments = param.parent?.as(LabeledExprListSyntax.self) else {
            return false
        }
        if colorComponentLabels.contains(label),
           let call = arguments.parent?.as(FunctionCallExprSyntax.self),
           call.isColorInitializer {
            return true
        }
        if ["red", "green", "blue", "alpha"].contains(label),
           let call = arguments.parent?.as(MacroExpansionExprSyntax.self),
           call.macroName.text == "colorLiteral" {
            return true
        }
        return false
    }

    /// Searches for the argument of a function call or a macro expansion this expression is part of.
    ///
    /// The expression is not necessarily the argument itself. It may be nested in an arithmetic operation, in
    /// parentheses or in a numeric conversion as in `Color(red: 0x19 / 255, green: 0, blue: 0)`. Every other kind
    /// of parent ends the search so that an exemption granted for an argument cannot leak out of it.
    private func enclosingCallArgument() -> LabeledExprSyntax? {
        var node = Syntax(self)
        while let parent = node.parent {
            guard let argument = parent.as(LabeledExprSyntax.self) else {
                guard parent.isArithmeticOperation else {
                    return nil
                }
                node = parent
                continue
            }
            guard let container = argument.parent?.parent else {
                return nil
            }
            if let call = container.as(FunctionCallExprSyntax.self) {
                // Look through conversions like `CGFloat(0x19)`, but stop at any other call.
                guard argument.label == nil, call.isNumericConversion else {
                    return argument
                }
                node = Syntax(call)
            } else if container.is(MacroExpansionExprSyntax.self) {
                return argument
            } else if argument.label == nil,
                      let tuple = container.as(TupleExprSyntax.self), tuple.elements.count == 1 {
                // A single-element unlabeled tuple is just a parenthesized expression.
                node = Syntax(tuple)
            } else {
                return nil
            }
        }
        return nil
    }
}

private extension FunctionCallExprSyntax {
    /// Whether this is a direct or module-qualified color initializer call.
    var isColorInitializer: Bool {
        var callee = calledExpression.trimmedDescription
        if callee.hasSuffix(".init") {
            callee = String(callee.dropLast(5))
        }
        return colorTypeNames.contains(callee)
    }

    /// Whether this call is a conversion of a single value into another numeric type as in `CGFloat(0x19)`.
    var isNumericConversion: Bool {
        guard let typeName = calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text else {
            return false
        }
        return arguments.count == 1
            && trailingClosure == nil
            && ["CGFloat", "Double", "Float", "Int", "UInt8"].contains(typeName)
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
