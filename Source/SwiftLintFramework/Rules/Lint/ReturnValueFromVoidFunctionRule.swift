import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

public struct ReturnValueFromVoidFunctionRule: ConfigurationProviderRule, SyntaxRule, OptInRule,
                                               AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_value_from_void_function",
        name: "Return Value from Void Function",
        description: "Returning values from Void functions should be avoided.",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: ReturnValueFromVoidFunctionRuleExamples.nonTriggeringExamples,
        triggeringExamples: ReturnValueFromVoidFunctionRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        #if canImport(SwiftSyntax)
        return validate(file: file, visitor: ReturnVisitor())
        #else
        return []
        #endif
    }
}

#if canImport(SwiftSyntax)
private class ReturnVisitor: SyntaxRuleVisitor {
    private var positions = [AbsolutePosition]()

    func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.expression != nil,
            let functionNode = node.enclosingFunction(),
            functionNode.returnsVoid {
            positions.append(node.positionAfterSkippingLeadingTrivia)
        }
        return .visitChildren
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
        if let node = self as? FunctionDeclSyntax {
            return node
        }

        if self is ClosureExprSyntax || self is VariableDeclSyntax {
            return nil
        }

        return parent?.enclosingFunction()
    }
}

private extension FunctionDeclSyntax {
    var returnsVoid: Bool {
        if let type = signature.output?.returnType as? SimpleTypeIdentifierSyntax {
            return type.name.text == "Void"
        }

        return signature.output?.returnType == nil
    }
}
#endif
