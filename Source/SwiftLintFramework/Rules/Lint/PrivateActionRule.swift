import SourceKittenFramework

public struct PrivateActionRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_action",
        name: "Private Actions",
        description: "IBActions should be private.",
        kind: .lint,
        nonTriggeringExamples: [
            "class Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "struct Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "class Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "struct Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "private extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "fileprivate extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "struct Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "class Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "struct Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "class Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "struct Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "extension Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "extension Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "public extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n",
            "internal extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            let offset = dictionary.offset,
            kind == .functionMethodInstance,
            dictionary.enclosedSwiftAttributes.contains(.ibaction),
            let controlLevel = dictionary.accessibility.flatMap(AccessControlLevel.init(identifier:)),
            controlLevel.isPrivate == false
            else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
