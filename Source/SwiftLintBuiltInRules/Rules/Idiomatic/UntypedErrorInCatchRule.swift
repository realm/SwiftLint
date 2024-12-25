import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct UntypedErrorInCatchRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "untyped_error_in_catch",
        name: "Untyped Error in Catch",
        description: "Catch statements should not declare error variables without type casting",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            do {
              try foo()
            } catch {}
            """),
            Example("""
            do {
              try foo()
            } catch Error.invalidOperation {
            } catch {}
            """),
            Example("""
            do {
              try foo()
            } catch let error as MyError {
            } catch {}
            """),
            Example("""
            do {
              try foo()
            } catch var error as MyError {
            } catch {}
            """),
            Example("""
            do {
                try something()
            } catch let e where e.code == .fileError {
                // can be ignored
            } catch {
                print(error)
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            do {
              try foo()
            } ↓catch var error {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch let error {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch let someError {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch var someError {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch let e {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch(let error) {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch (let error) {}
            """),
        ],
        corrections: [
            Example("do {\n    try foo() \n} ↓catch let error {}"): Example("do {\n    try foo() \n} catch {}"),
            Example("do {\n    try foo() \n} ↓catch(let error) {}"): Example("do {\n    try foo() \n} catch {}"),
            Example("do {\n    try foo() \n} ↓catch (let error) {}"): Example("do {\n    try foo() \n} catch {}"),
        ])
}

private extension CatchItemSyntax {
    var isIdentifierPattern: Bool {
        guard whereClause == nil else {
            return false
        }

        if let pattern = pattern?.as(ValueBindingPatternSyntax.self) {
            return pattern.pattern.is(IdentifierPatternSyntax.self)
        }

        if let pattern = pattern?.as(ExpressionPatternSyntax.self),
           let tupleExpr = pattern.expression.as(TupleExprSyntax.self),
           let tupleElement = tupleExpr.elements.onlyElement,
           let unresolvedPattern = tupleElement.expression.as(PatternExprSyntax.self),
           let valueBindingPattern = unresolvedPattern.pattern.as(ValueBindingPatternSyntax.self) {
            return valueBindingPattern.pattern.is(IdentifierPatternSyntax.self)
        }

        return false
    }
}

private extension UntypedErrorInCatchRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: CatchClauseSyntax) {
            guard let item = node.catchItems.onlyElement, item.isIdentifierPattern else {
                return
            }
            violations.append(node.catchKeyword.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
            guard let item = node.catchItems.onlyElement, item.isIdentifierPattern else {
                return super.visit(node)
            }

            correctionPositions.append(node.catchKeyword.positionAfterSkippingLeadingTrivia)
            return super.visit(
                node
                    .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .spaces(1)))
                    .with(\.catchItems, CatchItemListSyntax([]))
            )
        }
    }
}
