import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ForceUnwrappingRule: Rule {
    var configuration = ForceUnwrappingConfiguration()

    static let description = RuleDescription(
        identifier: "force_unwrapping",
        name: "Force Unwrapping",
        description: "Force unwrapping should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("if let url = NSURL(string: query)"),
            Example("navigationController?.pushViewController(viewController, animated: true)"),
            Example("let s as! Test"),
            Example("try! canThrowErrors()"),
            Example("let object: Any!"),
            Example("@IBOutlet var constraints: [NSLayoutConstraint]!"),
            Example("setEditing(!editing, animated: true)"),
            Example("navigationController.setNavigationBarHidden(!navigationController." +
                "navigationBarHidden, animated: true)"),
            Example("if addedToPlaylist && (!self.selectedFilters.isEmpty || " +
                "self.searchBar?.text?.isEmpty == false) {}"),
            Example("print(\"\\(xVar)!\")"),
            Example("var test = (!bar)"),
            Example("var a: [Int]!"),
            Example("private var myProperty: (Void -> Void)!"),
            Example("func foo(_ options: [AnyHashable: Any]!) {"),
            Example("func foo() -> [Int]!"),
            Example("func foo() -> [AnyHashable: Any]!"),
            Example("func foo() -> [Int]! { return [] }"),
            Example("return self"),
            Example("let url = URL(string: \"https://www.example.com\")!"),
            Example("let data = Data(hexString: \"AABBCCDD\")!"),
            Example("let image = UIImage(named: \"icon\")!"),
            Example("let url = NSURL(string: \"http://www.google.com\")!"),
            Example("let url = URL.init(string: \"https://www.example.com\")!"),
            Example(
                "let result = someFunction(\"constant\")!",
                configuration: ["ignored_literal_argument_functions": ["someFunction(_:)"]]
            ),
        ],
        triggeringExamples: [
            Example("let url = NSURL(string: query)↓!"),
            Example("navigationController↓!.pushViewController(viewController, animated: true)"),
            Example("let unwrapped = optional↓!"),
            Example("return cell↓!"),
            Example("""
            let dict = ["Boooo": "👻"]
            func bla() -> String {
                return dict["Boooo"]↓!
            }
            """),
            Example("""
            let dict = ["Boooo": "👻"]
            func bla() -> String {
                return dict["Boooo"]↓!.contains("B")
            }
            """),
            Example("let a = dict[\"abc\"]↓!.contains(\"B\")"),
            Example("dict[\"abc\"]↓!.bar(\"B\")"),
            Example("if dict[\"a\"]↓!↓!↓!↓! {}"),
            Example("var foo: [Bool]! = dict[\"abc\"]↓!"),
            Example("realm.objects(SwiftUTF8Object.self).filter(\"%K == %@\", \"柱нǢкƱаم👍\", utf8TestString).first↓!"),
            Example("""
            context("abc") {
              var foo: [Bool]! = dict["abc"]↓!
            }
            """),
            Example("open var computed: String { return foo.bar↓! }"),
            Example("return self↓!"),
            Example("[1, 3, 5, 6].first { $0.isMultiple(of: 2) }↓!"),
            Example("map[\"a\"]↓!↓!"),
            Example("let url = URL(string: variable)↓!"),
            Example("let url = URL(string: \"\\(dynamicValue)\")↓!"),
            Example("let result = someFunction(\"constant\")↓!"),
            Example(
                "let url = URL(string: \"https://www.example.com\")↓!",
                configuration: ["ignored_literal_argument_functions": [String]()]
            ),
        ]
    )
}

private extension ForceUnwrappingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ForceUnwrapExprSyntax) {
            if isIgnoredLiteralArgumentCall(node.expression) {
                return
            }
            violations.append(node.exclamationMark.positionAfterSkippingLeadingTrivia)
        }

        private func isIgnoredLiteralArgumentCall(_ expression: ExprSyntax) -> Bool {
            guard let funcCall = expression.as(FunctionCallExprSyntax.self) else {
                return false
            }
            let arguments = funcCall.arguments
            guard !arguments.isEmpty,
                  arguments.allSatisfy(\.expression.isStaticStringLiteral) else {
                return false
            }
            let resolvedName = funcCall.resolvedFunctionName
            return configuration.ignoredLiteralArgumentFunctions.contains(resolvedName)
        }
    }
}

private extension FunctionCallExprSyntax {
    var resolvedFunctionName: String {
        var callee = calledExpression.trimmedDescription
        // Normalize `Type.init(args)` to `Type(args)` so both forms match the allowlist.
        if callee.hasSuffix(".init") {
            callee = String(callee.dropLast(5))
        }
        let labels = arguments.map { ($0.label?.text ?? "_") + ":" }
        return callee + "(" + labels.joined() + ")"
    }
}

private extension ExprSyntax {
    var isStaticStringLiteral: Bool {
        guard let stringLiteral = `as`(StringLiteralExprSyntax.self) else {
            return false
        }
        return stringLiteral.segments.onlyElement?.is(StringSegmentSyntax.self) == true
    }
}
