import SwiftSyntax

struct ForceUnwrappingRule: OptInRule, SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            Example("return self")
        ],
        triggeringExamples: [
            Example("let url = NSURL(string: query)↓!"),
            Example("navigationController↓!.pushViewController(viewController, animated: true)"),
            Example("let unwrapped = optional↓!"),
            Example("return cell↓!"),
            Example("let url = NSURL(string: \"http://www.google.com\")↓!"),
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
            Example("map[\"a\"]↓!↓!")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        ForceUnwrappingVisitor(viewMode: .sourceAccurate)
    }
}

private final class ForceUnwrappingVisitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: ForcedValueExprSyntax) {
        violations.append(node.exclamationMark.positionAfterSkippingLeadingTrivia)
    }
}
