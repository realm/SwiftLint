import SourceKittenFramework
import SwiftSyntax

public struct ReturnValueFromVoidFunctionRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_value_from_void_function",
        name: "Return Value from Void Function",
        description: "Returning values from Void functions should be avoided.",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: ReturnValueFromVoidFunctionRuleExamples.nonTriggeringExamples,
        triggeringExamples: ReturnValueFromVoidFunctionRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let visitor = ReturnValueFromVoidFunctionVisitor()
        return visitor.walk(file: file) { visitor in
            visitor.violations(for: self, in: file)
        }
    }
}

private final class ReturnValueFromVoidFunctionVisitor: SyntaxVisitor {
    private var positions = [AbsolutePosition]()

    override func visitPost(_ node: ReturnStmtSyntax) {
        if node.expression != nil,
           let functionNode = Syntax(node).enclosingFunction(),
            functionNode.returnsVoid {
            positions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }

    func violations(for rule: ReturnValueFromVoidFunctionRule, in file: SwiftLintFile) -> [StyleViolation] {
        return positions.map { position in
            StyleViolation(ruleDescription: type(of: rule).description,
                           severity: rule.configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}

private extension Syntax {
    func enclosingFunction() -> FunctionDeclSyntax? {
        if let node = self.as(FunctionDeclSyntax.self) {
            return node
        }

        if self.is(ClosureExprSyntax.self) || self.is(VariableDeclSyntax.self) {
            return nil
        }

        return parent?.enclosingFunction()
    }
}

private extension FunctionDeclSyntax {
    var returnsVoid: Bool {
        if let type = signature.output?.returnType.as(SimpleTypeIdentifierSyntax.self) {
            return type.name.text == "Void"
        }

        return signature.output?.returnType == nil
    }
}
