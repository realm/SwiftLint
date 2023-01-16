import SwiftSyntax

struct UntypedErrorInCatchRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            """)
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
            """)
        ],
        corrections: [
            Example("do {\n    try foo() \n} ↓catch let error {}"): Example("do {\n    try foo() \n} catch {}"),
            Example("do {\n    try foo() \n} ↓catch(let error) {}"): Example("do {\n    try foo() \n} catch {}"),
            Example("do {\n    try foo() \n} ↓catch (let error) {}"): Example("do {\n    try foo() \n} catch {}")
        ])

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        UntypedErrorInCatchRuleVisitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        UntypedErrorInCatchRuleRewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension CatchItemSyntax {
    var isIdentifierPattern: Bool {
        guard whereClause == nil else {
            return false
        }

        if let pattern = pattern?.as(ValueBindingPatternSyntax.self) {
            return pattern.valuePattern.is(IdentifierPatternSyntax.self)
        }

        if let pattern = pattern?.as(ExpressionPatternSyntax.self),
           let tupleExpr = pattern.expression.as(TupleExprSyntax.self),
           let tupleElement = tupleExpr.elementList.onlyElement,
           let unresolvedPattern = tupleElement.expression.as(UnresolvedPatternExprSyntax.self),
           let valueBindingPattern = unresolvedPattern.pattern.as(ValueBindingPatternSyntax.self) {
            return valueBindingPattern.valuePattern.is(IdentifierPatternSyntax.self)
        }

        return false
    }
}

private final class UntypedErrorInCatchRuleVisitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: CatchClauseSyntax) {
        guard let item = node.catchItems?.onlyElement,
              item.isIdentifierPattern else {
            return
        }

        violations.append(node.catchKeyword.positionAfterSkippingLeadingTrivia)
    }
}

private final class UntypedErrorInCatchRuleRewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [AbsolutePosition] = []
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
        guard
            let item = node.catchItems?.onlyElement,
            item.isIdentifierPattern,
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        else {
            return super.visit(node)
        }

        correctionPositions.append(node.catchKeyword.positionAfterSkippingLeadingTrivia)
        return super.visit(
            node
                .withCatchKeyword(node.catchKeyword.withTrailingTrivia(.spaces(1)))
                .withCatchItems(CatchItemListSyntax([]))
        )
    }
}
