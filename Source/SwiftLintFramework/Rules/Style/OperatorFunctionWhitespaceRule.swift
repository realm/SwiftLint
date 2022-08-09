import SourceKittenFramework

public struct OperatorFunctionWhitespaceRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "operator_whitespace",
        name: "Operator Function Whitespace",
        description: "Operators should be surrounded by a single whitespace when defining them.",
        kind: .style,
        nonTriggeringExamples: [
            Example("func <| (lhs: Int, rhs: Int) -> Int {}\n"),
            Example("func <|< <A>(lhs: A, rhs: A) -> A {}\n"),
            Example("func abc(lhs: Int, rhs: Int) -> Int {}\n")
        ],
        triggeringExamples: [
            Example("↓func <|(lhs: Int, rhs: Int) -> Int {}\n"),   // no spaces after
            Example("↓func <|<<A>(lhs: A, rhs: A) -> A {}\n"),     // no spaces after
            Example("↓func <|  (lhs: Int, rhs: Int) -> Int {}\n"), // 2 spaces after
            Example("↓func <|<  <A>(lhs: A, rhs: A) -> A {}\n"),   // 2 spaces after
            Example("↓func  <| (lhs: Int, rhs: Int) -> Int {}\n"), // 2 spaces before
            Example("↓func  <|< <A>(lhs: A, rhs: A) -> A {}\n")    // 2 spaces before
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let escapedOperators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", "."]
            .map({ "\\\($0)" }).joined()
        let operators = "\(escapedOperators)%<>&"
        let zeroOrManySpaces = "(\\s{0}|\\s{2,})"
        let pattern1 = "func\\s+[\(operators)]+\(zeroOrManySpaces)(<[A-Z]+>)?\\("
        let pattern2 = "func\(zeroOrManySpaces)[\(operators)]+\\s+(<[A-Z]+>)?\\("
        return file.match(pattern: "(\(pattern1)|\(pattern2))").filter { _, syntaxKinds in
            return syntaxKinds.first == .keyword
        }.map { range, _ in
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }
}
