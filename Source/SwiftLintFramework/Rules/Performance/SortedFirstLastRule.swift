import SourceKittenFramework

public struct SortedFirstLastRule: CallPairRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "sorted_first_last",
        name: "Min or Max over Sorted First or Last",
        description: "Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`",
        kind: .performance,
        nonTriggeringExamples: [
            "let min = myList.min()\n",
            "let min = myList.min(by: { $0 < $1 })\n",
            "let min = myList.min(by: >)\n",
            "let max = myList.max()\n",
            "let max = myList.max(by: { $0 < $1 })\n",
            "let message = messages.sorted(byKeyPath: #keyPath(Message.timestamp)).last",
            "let message = messages.sorted(byKeyPath: \"timestamp\", ascending: false).first"
        ],
        triggeringExamples: [
            "↓myList.sorted().first\n",
            "↓myList.sorted(by: { $0.description < $1.description }).first\n",
            "↓myList.sorted(by: >).first\n",
            "↓myList.map { $0 + 1 }.sorted().first\n",
            "↓myList.sorted(by: someFunction).first\n",
            "↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.first\n",
            "↓myList.sorted().last\n",
            "↓myList.sorted().last?.something()\n",
            "↓myList.sorted(by: { $0.description < $1.description }).last\n",
            "↓myList.map { $0 + 1 }.sorted().last\n",
            "↓myList.sorted(by: someFunction).last\n",
            "↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.last\n",
            "↓myList.map { $0 + 1 }.sorted { $0.first < $1.first }.last\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file,
                        pattern: "[\\}\\)]\\s*\\.(first|last)",
                        patternSyntaxKinds: [.identifier],
                        callNameSuffix: ".sorted",
                        severity: configuration.severity) { dictionary in
            let arguments = dictionary.enclosedArguments.compactMap { $0.name }
            return arguments.isEmpty || arguments == ["by"]
        }
    }
}
