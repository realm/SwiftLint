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
            func emptyImplementationForRequiredProtocolFunction() {}
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
            override func viewDidLoad() {
                super.viewDidLoad()

                // Do any additional setup after loading the view.
            }
            """,
            """
            override func didReceiveMemoryWarning() {
                super.didReceiveMemoryWarning()
                // Dispose of any resources that can be recreated.
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "."
        return file
            .match(pattern: pattern)
            .map { range, syntaxKinds in
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: range.location)
                )
            }
    }
}
