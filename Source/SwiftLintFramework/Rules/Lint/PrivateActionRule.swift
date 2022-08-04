import SourceKittenFramework

public struct PrivateActionRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_action",
        name: "Private Actions",
        description: "IBActions should be private.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("class Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("private extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("fileprivate extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}\n")
        ],
        triggeringExamples: [
            Example("class Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("class Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("class Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("extension Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("extension Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("public extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("internal extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            let offset = dictionary.offset,
            kind == .functionMethodInstance,
            dictionary.enclosedSwiftAttributes.contains(.ibaction),
            dictionary.accessibility?.isPrivate != true
            else {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
