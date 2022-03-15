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
        guard let tree = file.syntaxTree else {
            warnSyntaxParserFailureOnce()
            return []
        }

        let visitor = ReturnVisitor()
        visitor.walk(tree)
        return visitor.violations(for: self, in: file)
    }
}

private final class ReturnVisitor: SyntaxVisitor {
    private var positions = [AbsolutePosition]()

    override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.expression != nil,
           let functionNode = Syntax(node).enclosingFunction(),
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

private let warnSyntaxParserFailureOnceImpl: Void = {
    queuedPrintError("The return_value_from_void_function rule is disabled because the Swift Syntax tree could not be parsed")
}()

private func warnSyntaxParserFailureOnce() {
    _ = warnSyntaxParserFailureOnceImpl
}
