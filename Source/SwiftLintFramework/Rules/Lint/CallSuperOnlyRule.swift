import SourceKittenFramework

public struct CallSuperOnlyRule: Rule, ConfigurationProviderRule, AutomaticTestableRule {
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
            """
        ],
        triggeringExamples: [
            """
            ↓override func a(){/*comment*/super.a()}
            """,
            """
            ↓override func viewDidLoad() {
                super.viewDidLoad()

                // Do any additional setup after loading the view.
            }
            """,
            """
            ↓override func didReceiveMemoryWarning() {
                super.didReceiveMemoryWarning()
                // Dispose of any resources that can be recreated.
            }
            """,
            """
            ↓override func becomeFirstResponder() -> Bool {
                return super.becomeFirstResponder()
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let paramsOrArguments = "(\\([\\w\\s,:_()=?\\->]*\\))"
        let whitespaceOrComments = "(\\s|//[^\\n\\r]*|/\\*[^\\n\\r]*\\*/)*+"
        let signature = "override[\\w,\\s]*func\\s(\\w+)\(paramsOrArguments)[\\w\\s\\->]*"
        let body = "\\{\(whitespaceOrComments)(return\\s)?super\\.\\1\(paramsOrArguments)\(whitespaceOrComments)\\}"

        let pattern = signature + body

        return file
            .match(pattern: pattern)
            .compactMap { range, syntaxKinds in
                // Skip matches that occur in strings and comments
                guard syntaxKinds != [.string],
                    syntaxKinds != [.comment]
                    else { return nil }

                return StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: range.location)
                )
            }
    }
}
