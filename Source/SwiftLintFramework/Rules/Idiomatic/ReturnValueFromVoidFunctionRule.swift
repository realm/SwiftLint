import SourceKittenFramework
import SwiftSyntax

public struct ReturnValueFromVoidFunctionRule: ConfigurationProviderRule, OptInRule, SyntaxRule,
                                               AutomaticTestableRule {
    public typealias Visitor = ReturnVisitor
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
}

public final class ReturnVisitor: SyntaxVisitor, SyntaxRuleVisitor {
    private var positions = [AbsolutePosition]()

    override public func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.expression != nil,
           let functionNode = Syntax(node).enclosingFunction(),
            functionNode.returnsVoid {
            positions.append(node.positionAfterSkippingLeadingTrivia)
        }
        return .visitChildren
    }

    public func violations(for rule: ReturnValueFromVoidFunctionRule, in file: SwiftLintFile) -> [StyleViolation] {
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
