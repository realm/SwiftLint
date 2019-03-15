import SourceKittenFramework

public struct CallSuperOnlyRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "call_super_only",
        name: "Call Super Only",
        description: "Methods that don't do anything but call `super` can be removed",
        kind: .lint,
        nonTriggeringExamples: [
            """
            override func viewDidDisappear(_ animated: Bool) {
                childViewController.viewDidDisappear(animated)
            }
            """,
            """
            override func viewDidDisappear(_ animated: Bool) {
                super.viewDidDisappear(animated)
                print("View controller did disappear")
            }
            """,
            """
            public override init() {
                super.init()
            }
            """,
            """
            override func setUp() {
                super.setUp()
                urlString = "https://httpbin.org/basic-auth"
            }
            """
        ].map(wrapInClass),
        triggeringExamples: [
            """
            override ↓func a(){/*comment*/super.a()}
            """,
            """
            override ↓func viewDidLoad() {
                super.viewDidLoad()

                // Do any additional setup after loading the view.
            }
            """,
            """
            override ↓func didReceiveMemoryWarning() {
                super.didReceiveMemoryWarning()
                // Dispose of any resources that can be recreated.
            }
            """,
            """
            override ↓func becomeFirstResponder() -> Bool {
                return super.becomeFirstResponder()
            }
            """
        ].map(wrapInClass)
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .functionMethodInstance,
            dictionary.enclosedSwiftAttributes.contains(.override),
            !dictionary.enclosedSwiftAttributes.contains(.public),
            file.onlyCallsSuper(dictionary),
            let offset = dictionary.offset
            else { return [] }

        return [StyleViolation(
            ruleDescription: type(of: self).description,
            severity: configuration.severity,
            location: Location(file: file, byteOffset: offset)
        )]
    }
}

private extension File {
    func onlyCallsSuper(_ dictionary: [String: SourceKitRepresentable]) -> Bool {
        if let name = dictionary.name?.split(separator: "(").first,
            dictionary.substructure.count == 1,
            let methodCall = dictionary.substructure.first,
            methodCall.name == "super.\(name)",
            !hasAssignmentInBody(dictionary) {
            return true
        } else {
            return false
        }
    }

    private func hasAssignmentInBody(_ dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength
            else { return false }

        let body = contents.substring(from: bodyOffset, length: bodyLength)
        let assignmentOperators = ["=", "*=", "/=", "%=", "+=", "-=",
                                   "<<=", ">>=", "&=", "|=", "^="]

        return assignmentOperators.first(where: body.contains) != nil
    }
}

private func wrapInClass(_ string: String) -> String {
    return """
    class ViewController: UIViewController {
    \(string
        .split(separator: "\n")
        .map { "    " + $0 }
        .joined(separator: "\n")
    )
    }
    """
}
