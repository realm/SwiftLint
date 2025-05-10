/// A detailed description for a SwiftLint rule. Used for both documentation and testing purposes.
public struct RuleDescription: Equatable, Sendable {
    /// The rule's unique identifier, to be used in configuration files and SwiftLint commands.
    /// Should be short and only comprised of lowercase latin alphabet letters and underscores formatted in snake case.
    public let identifier: String

    /// The rule's human-readable name. Should be short, descriptive and formatted in Title Case. May contain spaces.
    public let name: String

    /// The rule's verbose description. Should read as a sentence or short paragraph. Good things to include are an
    /// explanation of the rule's purpose and rationale.
    public let description: String

    /// A longer explanation of the rule's purpose and rationale. Typically defined as a multiline string, long text 
    /// lines should be wrapped. Markdown formatting is supported. Multiline code blocks will be formatted as
    /// `swift` code unless otherwise specified, and will automatically be indented by four spaces when printed
    /// to the console.
    public let rationale: String?

    /// The `RuleKind` that best categorizes this rule.
    public let kind: RuleKind

    /// Swift source examples that do not trigger a violation for this rule. Used for documentation purposes to inform
    /// users of various samples of code that are considered valid by this rule. Should be valid Swift syntax but is not
    /// required to compile.
    ///
    /// These examples are also used for automatic testing purposes. Tests will validate that the rule does not trigger
    /// any violations for these examples.
    public let nonTriggeringExamples: [Example]

    /// Swift source examples that do trigger one or more violations for this rule. Used for documentation purposes to
    /// inform users of various samples of code that are considered invalid by this rule. Should be valid Swift syntax
    /// but is not required to compile.
    ///
    /// Violations should occur where `↓` markers are located.
    ///
    /// These examples are also used for automatic testing purposes. Tests will validate that the rule triggers
    /// violations for these examples wherever `↓` markers are located.
    public let triggeringExamples: [Example]

    /// Pairs of Swift source examples, where keys are examples that trigger violations for this rule, and the values
    /// are the expected value after applying corrections with the rule.
    ///
    /// Rules that aren't correctable (conforming to the `CorrectableRule` protocol) should leave property empty.
    ///
    /// These examples are used for testing purposes if the rule conforms to `AutomaticTestableRule`. Tests will
    /// validate that the rule corrects all keys to their corresponding values.
    public let corrections: [Example: Example]

    /// Any previous iteration of the rule's identifier that was previously shipped with SwiftLint.
    public let deprecatedAliases: Set<String>

    /// The oldest version of the Swift compiler supported by this rule.
    public let minSwiftVersion: SwiftVersion

    /// Whether or not this rule can only be executed on a file physically on-disk. Typically necessary for rules
    /// conforming to `AnalyzerRule`.
    public let requiresFileOnDisk: Bool

    /// The console-printable string for this description.
    public var consoleDescription: String { "\(name) (\(identifier)): \(description)" }

    /// The console-printable rationale for this description.
    public var consoleRationale: String? {
        rationale?.consoleRationale
    }

    /// The rationale for this description, with Markdown formatting.
    public var formattedRationale: String? {
        rationale?.formattedRationale
    }

    /// All identifiers that have been used to uniquely identify this rule in past and current SwiftLint versions.
    public var allIdentifiers: [String] {
        Array(deprecatedAliases) + [identifier]
    }

    /// Creates a `RuleDescription` by specifying all its properties directly.
    ///
    /// - parameter identifier:            Sets the description's `identifier` property.
    /// - parameter name:                  Sets the description's `name` property.
    /// - parameter description:           Sets the description's `description` property.
    /// - parameter kind:                  Sets the description's `kind` property.
    /// - parameter minSwiftVersion:       Sets the description's `minSwiftVersion` property.
    /// - parameter nonTriggeringExamples: Sets the description's `nonTriggeringExamples` property.
    /// - parameter triggeringExamples:    Sets the description's `triggeringExamples` property.
    /// - parameter corrections:           Sets the description's `corrections` property.
    /// - parameter deprecatedAliases:     Sets the description's `deprecatedAliases` property.
    /// - parameter requiresFileOnDisk:    Sets the description's `requiresFileOnDisk` property.
    public init(identifier: String,
                name: String,
                description: String,
                rationale: String? = nil,
                kind: RuleKind,
                minSwiftVersion: SwiftVersion = .five,
                nonTriggeringExamples: [Example] = [],
                triggeringExamples: [Example] = [],
                corrections: [Example: Example] = [:],
                deprecatedAliases: Set<String> = [],
                requiresFileOnDisk: Bool = false) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.rationale = rationale
        self.kind = kind
        self.nonTriggeringExamples = nonTriggeringExamples
        self.triggeringExamples = triggeringExamples
        self.corrections = corrections
        self.deprecatedAliases = deprecatedAliases
        self.minSwiftVersion = minSwiftVersion
        self.requiresFileOnDisk = requiresFileOnDisk
    }

    // MARK: Equatable

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

private extension String {
    var formattedRationale: String {
        formattedRationale(forConsole: false)
    }

    var consoleRationale: String {
        formattedRationale(forConsole: true)
    }

    private func formattedRationale(forConsole: Bool) -> String {
        var insideMultilineString = false
        return components(separatedBy: "\n").compactMap { line -> String? in
            if line.contains("```") {
                if insideMultilineString {
                    insideMultilineString = false
                    return forConsole ? nil : line
                }
                insideMultilineString = true
                if line.hasSuffix("```") {
                    return forConsole ? nil : (line + "swift")
                }
            }
            return line.indent(by: (insideMultilineString && forConsole) ? 4 : 0)
        }.joined(separator: "\n")
    }
}
