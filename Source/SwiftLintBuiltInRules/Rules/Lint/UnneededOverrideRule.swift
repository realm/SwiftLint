import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule
struct UnneededOverrideRule: SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_override",
        name: "Unneeded Overridden Functions",
        description: "Remove overridden functions that don't do anything except call their super",
        kind: .lint,
        nonTriggeringExamples: UnneededOverrideRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnneededOverrideRuleExamples.triggeringExamples,
        corrections: UnneededOverrideRuleExamples.corrections
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private func simplify(_ node: some SyntaxProtocol) -> (any ExprSyntaxProtocol)? {
    if let expr = node.as(AwaitExprSyntax.self) {
        return expr.expression
    } else if let expr = node.as(TryExprSyntax.self) {
        // Assume using try! / try? changes behavior
        if expr.questionOrExclamationMark != nil {
            return nil
        }

        return expr.expression
    } else if let expr = node.as(FunctionCallExprSyntax.self) {
        return expr
    } else if let stmt = node.as(ReturnStmtSyntax.self) {
        return stmt.expression
    }

    return nil
}

private func extractFunctionCallSyntax(_ node: some SyntaxProtocol) -> FunctionCallExprSyntax? {
    // Extract the function call from other expressions like try / await / return.
    // If this returns a non-super calling function that will get filtered out later
    var syntax = simplify(node)
    while let nestedSyntax = syntax {
        if nestedSyntax.as(FunctionCallExprSyntax.self) != nil {
            break
        }

        syntax = simplify(nestedSyntax)
    }

    return syntax?.as(FunctionCallExprSyntax.self)
}

private extension UnneededOverrideRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionDeclSyntax) {
            if isUnneededOverride(node) {
                self.violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            if isUnneededOverride(node) &&
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) {
                correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
                let expr: DeclSyntax = ""
                return expr
                    .with(\.leadingTrivia, node.leadingTrivia)
                    .with(\.trailingTrivia, node.trailingTrivia)
            }

            return super.visit(node)
        }
    }
}

private func isUnneededOverride(_ node: FunctionDeclSyntax) -> Bool {
    guard node.modifiers.contains(keyword: .override), let statement = node.body?.statements.onlyElement else {
        return false
    }

    // Assume having @available changes behavior
    if node.attributes.contains(attributeNamed: "available") {
        return false
    }

    let overridenFunctionName = node.name.text
    guard let call = extractFunctionCallSyntax(statement.item),
        let member = call.calledExpression.as(MemberAccessExprSyntax.self),
          member.base?.is(SuperExprSyntax.self) == true,
          member.declName.baseName.text == overridenFunctionName else {
        return false
    }

    // Assume any change in arguments passed means behavior was changed
    let expectedArguments = node.signature.parameterClause.parameters.map {
        ($0.firstName.text == "_" ? "" : $0.firstName.text, $0.secondName?.text ?? $0.firstName.text)
    }
    let actualArguments = call.arguments.map {
        ($0.label?.text ?? "", $0.expression.as(DeclReferenceExprSyntax.self)?.baseName.text ?? "")
    }

    guard expectedArguments.count == actualArguments.count else {
        return false
    }

    for (lhs, rhs) in zip(expectedArguments, actualArguments) where lhs != rhs {
        return false
    }

    return true
}
