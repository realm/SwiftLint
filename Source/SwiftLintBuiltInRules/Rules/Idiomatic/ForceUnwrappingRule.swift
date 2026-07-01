import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ForceUnwrappingRule: Rule {
    var configuration = ForceUnwrappingConfiguration()

    static let description = RuleDescription(
        identifier: "force_unwrapping",
        name: "Force Unwrapping",
        description: "Force unwrapping should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "if let url = NSURL(string: query)",
            "navigationController?.pushViewController(viewController, animated: true)",
            "let s as! Test",
            "try! canThrowErrors()",
            "let object: Any!",
            "@IBOutlet var constraints: [NSLayoutConstraint]!",
            "setEditing(!editing, animated: true)",
            "navigationController.setNavigationBarHidden(!navigationController." +
                "navigationBarHidden, animated: true)",
            "if addedToPlaylist && (!self.selectedFilters.isEmpty || " +
                "self.searchBar?.text?.isEmpty == false) {}",
            "print(\"\\(xVar)!\")",
            "var test = (!bar)",
            "var a: [Int]!",
            "private var myProperty: (Void -> Void)!",
            "func foo(_ options: [AnyHashable: Any]!) {",
            "func foo() -> [Int]!",
            "func foo() -> [AnyHashable: Any]!",
            "func foo() -> [Int]! { return [] }",
            "return self",
            "let url = URL(string: \"https://www.example.com\")!",
            "let data = Data(hexString: \"AABBCCDD\")!",
            "let image = UIImage(named: \"icon\")!",
            "let url = NSURL(string: \"http://www.google.com\")!",
            "let url = URL.init(string: \"https://www.example.com\")!",
            "let result = someFunction(\"constant\")!"
                .configuration(["ignored_literal_argument_functions": ["someFunction(_:)"]]),
        ]),
        triggeringExamples: #examples([
            "let url = NSURL(string: query)↓!",
            "navigationController↓!.pushViewController(viewController, animated: true)",
            "let unwrapped = optional↓!",
            "return cell↓!",
            """
            let dict = ["Boooo": "👻"]
            func bla() -> String {
                return dict["Boooo"]↓!
            }
            """,
            """
            let dict = ["Boooo": "👻"]
            func bla() -> String {
                return dict["Boooo"]↓!.contains("B")
            }
            """,
            "let a = dict[\"abc\"]↓!.contains(\"B\")",
            "dict[\"abc\"]↓!.bar(\"B\")",
            "if dict[\"a\"]↓!↓!↓!↓! {}",
            "var foo: [Bool]! = dict[\"abc\"]↓!",
            "realm.objects(SwiftUTF8Object.self).filter(\"%K == %@\", \"柱нǢкƱаم👍\", utf8TestString).first↓!",
            """
            context("abc") {
              var foo: [Bool]! = dict["abc"]↓!
            }
            """,
            "open var computed: String { return foo.bar↓! }",
            "return self↓!",
            "[1, 3, 5, 6].first { $0.isMultiple(of: 2) }↓!",
            "map[\"a\"]↓!↓!",
            "let url = URL(string: variable)↓!",
            "let url = URL(string: \"\\(dynamicValue)\")↓!",
            "let result = someFunction(\"constant\")↓!",
            "let url = URL(string: \"https://www.example.com\")↓!"
                .configuration(["ignored_literal_argument_functions": [String]()]),
        ])
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
