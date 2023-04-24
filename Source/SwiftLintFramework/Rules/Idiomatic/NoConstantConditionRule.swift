// swiftlint:disable file_length
import SwiftSyntax

struct NoConstantConditionRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "no_constant_condition",
        name: "No Constant Condition",
        description: "Branching statements with constant conditions should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("if foo() {}"),
            Example("if foo != nil {}"),
            Example("if foo == nil {}"),
            Example("if foo == \"bar\" {}"),
            Example("if foo() != \"bar\" {}"),
            Example("if foo < 10 {}"),
            Example("if foo < bar {}"),
            Example("if foo() < bar() {}"),
            Example("if foo() || true {}"),
            Example("if foo() && true {}"),
            Example("if foo() || false {}"),
            Example("if foo() == false {}"),
            Example("if foo() == (bar() < 10 && false) {}"),
            Example("if foo(), true {}"),
            Example("if !(false, true) {}"),
            Example("if foo == nil {}"),
            Example("if foo < 10 && 1 < 5 {}"),
            Example("if foo < 10 && bar < 5 {}"),
            Example("if 0...10 ~= foo {}"),
            Example("if a+1 < 1+1 {}"),
            Example("if foo(), bar() {}"),
            Example("if foo(), 1 < 2 {}"),
            Example("if \"\\(fn())\" == \"\\(fn())\""),
            Example("if foo() && -5 == -5 {}"),
            Example("if foo() && -5 < -3 {}"),
            Example("if foo() && -5 < bar {}"),
            Example("let x = foo() ? \"a\" : \"b\""),
            Example("guard foo() {} else {}"),
            Example("switch foo() { default: break }")
        ],
        triggeringExamples: [
            Example("if ↓true {}"),
            Example("if ↓!true {}"),
            Example("if ↓false {}"),
            Example("if ↓!false {}"),
            Example("if ↓!((false)) {}"),
            Example("if ↓!(!(false)) {}"),
            Example("if ↓!(false) {}"),
            Example("if ↓0 < 1 {}"),
            Example("if ↓0.1 < 1.1 {}"),
            Example("if ↓\"a\" < \"b\" {}"),
            Example("if ↓true == false {}"),
            Example("if ↓nil != nil {}"),
            Example("if ↓1 < 2 && 2 < 3 {}"),
            Example("if ↓0...10 ~= 5 {}"),
            Example("if ↓!(0 < 1) {}"),
            Example("if ↓1 < 0 {}"),
            Example("if ↓1+1 < 1+2 {}"),
            Example("if ↓1+1 > 1+2 {}"),
            Example("if ↓1+1 == 1+2 {}"),
            Example("if ↓1+1 == 1+2 && true {}"),
            Example("if ↓1+1 == 1+2 && false {}"),
            Example("if ↓1 < 2 && (2 < 3 || 3 < 4) {}"),
            Example("if ↓\"foo\" == \"foo\" {}"),
            Example("if ↓\"foo\" != \"foo\" {}"),
            Example("if ↓true, false {}"),
            Example("if ↓true, true {}"),
            Example("if ↓foo(), false {}"),
            Example("if ↓foo < 2, false {}"),
            Example("if ↓foo(), 1 > 2 {}"),
            Example("if ↓1 < 2, true {}"),
            Example("if ↓1 < 2, false {}"),
            Example("if ↓foo() && false {}"),
            Example("if ↓foo() && !true {}"),
            Example("if ↓foo() && !(true) {}"),
            Example("if ↓foo() && !(!false) {}"),
            Example("if ↓foo() && -5 == -4 {}"),
            Example("if ↓foo() && -5 > -4 {}"),
            Example("if ↓foo() && (2+1 != 4-1) {}"),
            Example("if ↓foo() < bar && (x == nil && (!a && false)) {}"),
            Example("if ↓foo() < bar && (true == false) {}"),
            Example("if ↓!(foo() && false) {}"),
            Example("if ↓!!(foo() && false) {}"),
            Example("if ↓!!!(foo() && false) {}"),
            Example("if ↓foo(), false {}"),
            Example("if foo() {} else if ↓false {}"),
            Example("let x = ↓true ? \"a\" : \"b\""),
            Example("let x = ↓(foo() && false) ? \"a\" : \"b\""),
            Example("let x = (↓(foo() && false) ? \"a\" : \"b\")"),
            Example("guard ↓true {} else {}"),
            Example("guard ↓foo() && false {} else {}"),
            Example("guard ↓2 < 3 {} else {}"),
            Example("switch ↓2 < 3 { default: break }"),
            Example("switch ↓\"foo\" { default: break }"),
            Example("switch ↓foo() && false { default: break }")
        ]
    )

    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
        return file.foldedSyntaxTree
    }

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        return NoConstantConditionViolationsVisitor(viewMode: .fixedUp)
    }
}

private enum ConstantValue: Equatable {
    case booleanValue(_ value: Bool)
    case integerValue(_ value: Int)
    case floatValue(_ value: Float)
    case stringValue(_ value: String)
    case nilValue
}

private enum ConstantEvaluationResult: Equatable {
    case evaluated(_ value: ConstantValue)
    case notEvaluated
}

private enum ExpressionResult: Equatable {
    case alwaysEvaluatesToFalse
    case evaluatedConstant(_ value: ConstantValue)
    case nonEvaluatedButConstant
    case dynamic
}

private enum StringLiteralResult {
    case constant(_ value: String)
    case dynamic
}

private extension StringLiteralExprSyntax {
    func analyze() -> StringLiteralResult {
        var value = ""

        for literalSegment in self.segments {
            switch literalSegment {
            case .expressionSegment:
                return .dynamic
            case let .stringSegment(stringSegment):
                value += stringSegment.content.text
            }
        }

        return .constant(value)
    }
}

private extension ExprSyntax {
    func analyzePrimitiveLiteralExpression() -> ExpressionResult {
        if let booleanExpression = self.as(BooleanLiteralExprSyntax.self) {
            let value = booleanExpression.booleanLiteral.text
            return .evaluatedConstant(.booleanValue(value == "true"))
        }

        if let integerExpression = self.as(IntegerLiteralExprSyntax.self) {
            let value = integerExpression.digits.text
            return .evaluatedConstant(.integerValue(Int(value) ?? 0))
        }

        if let floatExpression = self.as(FloatLiteralExprSyntax.self) {
            let value = floatExpression.floatingDigits.text
            return .evaluatedConstant(.floatValue(Float(value) ?? 0.0))
        }

        if let stringExpression = self.as(StringLiteralExprSyntax.self) {
            let stringLiteralResult = stringExpression.analyze()
            switch stringLiteralResult {
            case let .constant(value):
                return .evaluatedConstant(.stringValue(value))
            case .dynamic:
                return .dynamic
            }
        }

        if self.is(NilLiteralExprSyntax.self) {
            return .evaluatedConstant(.nilValue)
        }

        return .dynamic
    }

    func isBinaryOperator(_ expectedOperator: String) -> Bool {
        if let binaryOperator = self.as(BinaryOperatorExprSyntax.self) {
            let operatorText = binaryOperator.operatorToken.text

            return operatorText == expectedOperator
        }

        return false
    }

    func isLogicalAndOperator() -> Bool {
        return self.isBinaryOperator("&&")
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func evaluateConstantInfixExpression(
        leftOperandValue: ConstantValue,
        rightOperandValue: ConstantValue) -> ConstantEvaluationResult {
        if self.isLogicalAndOperator() {
            if case let .booleanValue(leftBooleanValue) = leftOperandValue,
               case let .booleanValue(rightBooleanValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftBooleanValue && rightBooleanValue))
            }
        }

        if self.isBinaryOperator("||") {
            if case let .booleanValue(leftBooleanValue) = leftOperandValue,
               case let .booleanValue(rightBooleanValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftBooleanValue || rightBooleanValue))
            }
        }

        if self.isBinaryOperator("+") {
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.stringValue(leftStringValue + rightStringValue))
            }
        }

        if self.isBinaryOperator("==") {
            if case let .booleanValue(leftBooleanValue) = leftOperandValue,
               case let .booleanValue(rightBooleanValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftBooleanValue == rightBooleanValue))
            }
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftStringValue == rightStringValue))
            }
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftIntValue == rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftFloatValue == rightFloatValue))
            }
            if case .nilValue = leftOperandValue, case .nilValue = rightOperandValue {
                return .evaluated(.booleanValue(true))
            }
        }

        if self.isBinaryOperator("!=") {
            if case let .booleanValue(leftBooleanValue) = leftOperandValue,
               case let .booleanValue(rightBooleanValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftBooleanValue != rightBooleanValue))
            }
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftStringValue != rightStringValue))
            }
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftIntValue != rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftFloatValue != rightFloatValue))
            }
            if case .nilValue = leftOperandValue, case .nilValue = rightOperandValue {
                return .evaluated(.booleanValue(false))
            }
        }

        if self.isBinaryOperator("<") {
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftStringValue < rightStringValue))
            }
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftIntValue < rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftFloatValue < rightFloatValue))
            }
        }

        if self.isBinaryOperator(">") {
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftStringValue > rightStringValue))
            }
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftIntValue > rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftFloatValue > rightFloatValue))
            }
        }

        if self.isBinaryOperator("<=") {
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftStringValue <= rightStringValue))
            }
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftIntValue <= rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftFloatValue <= rightFloatValue))
            }
        }

        if self.isBinaryOperator(">=") {
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftStringValue >= rightStringValue))
            }
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftIntValue >= rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.booleanValue(leftFloatValue >= rightFloatValue))
            }
        }

        if self.isBinaryOperator("+") {
            if case let .stringValue(leftStringValue) = leftOperandValue,
               case let .stringValue(rightStringValue) = rightOperandValue {
                return .evaluated(.stringValue(leftStringValue + rightStringValue))
            }
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.integerValue(leftIntValue + rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.floatValue(leftFloatValue + rightFloatValue))
            }
        }

        if self.isBinaryOperator("-") {
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.integerValue(leftIntValue - rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.floatValue(leftFloatValue - rightFloatValue))
            }
        }

        if self.isBinaryOperator("*") {
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.integerValue(leftIntValue * rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.floatValue(leftFloatValue * rightFloatValue))
            }
        }

        if self.isBinaryOperator("/") {
            if case let .integerValue(leftIntValue) = leftOperandValue,
               case let .integerValue(rightIntValue) = rightOperandValue {
                return .evaluated(.integerValue(leftIntValue / rightIntValue))
            }
            if case let .floatValue(leftFloatValue) = leftOperandValue,
               case let .floatValue(rightFloatValue) = rightOperandValue {
                return .evaluated(.floatValue(leftFloatValue / rightFloatValue))
            }
        }

        return .notEvaluated
    }

    func analyzeGenericExpression() -> ExpressionResult {
        let literalResult = self.analyzePrimitiveLiteralExpression()

       if literalResult == .dynamic {
           if let infixExpression = self.as(InfixOperatorExprSyntax.self) {
               return infixExpression.analyze()
           }

           if let tupleExpression = self.as(TupleExprSyntax.self) {
               if let unwrappedExpression = tupleExpression.elementList.onlyElement?.expression {
                   return unwrappedExpression.analyzeGenericExpression()
               }
           }

           if let prefixExpression = self.as(PrefixOperatorExprSyntax.self) {
               return prefixExpression.analyze()
           }
       }

       return literalResult
   }
}

private func evaluatesToFalse(_ result: ExpressionResult) -> Bool {
    if result == .alwaysEvaluatesToFalse {
        return true
    }

    if case let .evaluatedConstant(value) = result {
        if case let .booleanValue(booleanValue) = value {
            return booleanValue == false
        }
    }

    return false
}

private func evaluateConstantPrefixExpression(
    operatorText: String,
    operand: ConstantValue) -> ConstantEvaluationResult {
    if operatorText == "!" {
        if case let .booleanValue(booleanValue) = operand {
            return .evaluated(.booleanValue(!booleanValue))
        }
    }

    if operatorText == "-" {
        if case let .integerValue(integerValue) = operand {
            return .evaluated(.integerValue(-integerValue))
        }
        if case let .floatValue(floatValue) = operand {
            return .evaluated(.floatValue(-floatValue))
        }
    }

    if operatorText == "+" {
        if case let .integerValue(integerValue) = operand {
            return .evaluated(.integerValue(integerValue))
        }
        if case let .floatValue(floatValue) = operand {
            return .evaluated(.floatValue(floatValue))
        }
    }

    return .notEvaluated
}

private extension PrefixOperatorExprSyntax {
    func analyze() -> ExpressionResult {
        let operandStatus = self.postfixExpression.analyzeGenericExpression()

        if case let .evaluatedConstant(value) = operandStatus {
            if let operatorText = self.operatorToken?.text {
                let result = evaluateConstantPrefixExpression(operatorText: operatorText, operand: value)

                switch result {
                case let .evaluated(value):
                    return .evaluatedConstant(value)
                case .notEvaluated:
                    return .nonEvaluatedButConstant
                }
            }
        }

        if operandStatus == .alwaysEvaluatesToFalse || operandStatus == .nonEvaluatedButConstant {
            return .nonEvaluatedButConstant
        }

        return .dynamic
    }
}

private extension InfixOperatorExprSyntax {
    func analyze() -> ExpressionResult {
        let leftOperandStatus = self.leftOperand.analyzeGenericExpression()
        let rightOperandStatus = self.rightOperand.analyzeGenericExpression()

        if case let .evaluatedConstant(leftOperandValue) = leftOperandStatus,
           case let .evaluatedConstant(rightOperandValue) = rightOperandStatus {
            let result = self.operatorOperand.evaluateConstantInfixExpression(
                leftOperandValue: leftOperandValue,
                rightOperandValue: rightOperandValue)

            switch result {
            case let .evaluated(value):
                return .evaluatedConstant(value)
            case .notEvaluated:
                return .nonEvaluatedButConstant
            }
        }

        if self.operatorOperand.isLogicalAndOperator() {
            if evaluatesToFalse(leftOperandStatus) {
                return .alwaysEvaluatesToFalse
            }

            if evaluatesToFalse(rightOperandStatus) {
                return .alwaysEvaluatesToFalse
            }
        }

        if leftOperandStatus != .dynamic && rightOperandStatus != .dynamic {
            return .nonEvaluatedButConstant
        }

        return .dynamic
    }
}

private func analyzeCondition(_ condition: ConditionElementSyntax.Condition) -> ExpressionResult {
    switch condition {
    case let .expression(expression):
        return expression.analyzeGenericExpression()
    default:
        return .dynamic
    }
}

private func isConstantConditionList(_ conditions: ConditionElementListSyntax) -> Bool {
    var hasDynamicCondition = false

    for element in conditions {
        let result = analyzeCondition(element.condition)

        if evaluatesToFalse(result) {
            return true
        }

        if result == .dynamic {
            hasDynamicCondition = true
        }
    }

    return !hasDynamicCondition
}

private func isConstantConditionExpression(_ condition: ExprSyntax) -> Bool {
    let result = condition.analyzeGenericExpression()

    return result != .dynamic
}

private final class NoConstantConditionViolationsVisitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: IfExprSyntax) {
        if isConstantConditionList(node.conditions) {
            self.violations.append(node.conditions.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: TernaryExprSyntax) {
        if isConstantConditionExpression(node.conditionExpression) {
            self.violations.append(node.conditionExpression.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: GuardStmtSyntax) {
        if isConstantConditionList(node.conditions) {
            self.violations.append(node.conditions.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: SwitchExprSyntax) {
        if isConstantConditionExpression(node.expression) {
            self.violations.append(node.expression.positionAfterSkippingLeadingTrivia)
        }
    }
}
