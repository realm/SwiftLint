import SourceKittenFramework
import SwiftSyntax

// MARK: - SyntaxVisitorRule
/// A rule that uses SwiftSyntax's SyntaxVisitor to
/// validate the rule by traversing the AST produced by the library.
public protocol SyntaxVisitorRule: Rule {
    /// A collection of SyntaxVisitor classes that will traverse the AST
    /// of a Swift souce file and collect the positions of lint violations.
    ///
    /// Annotate this variable with @SyntaxVisitorRuleValidatorBuilder
    /// in order to build the validator in a declarative way.
    /// This provides an abstraction over SyntaxVisitors and creating
    /// them yourselves.
    var validator: SyntaxVisitorRuleValidator { get }
}

public extension SyntaxVisitorRule {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree else {
            return []
        }

        let positions = validator.collectViolations(tree)

        return positions.map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: .error,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}

// MARK: - SyntaxVisitorRuleValidator
/// A collection of SyntaxVisitors to find lint violations
public struct SyntaxVisitorRuleValidator {
    var visitors: [ViolationSyntaxVisiting]

    /// Creates a `SyntaxVisitorRuleValidator`
    ///
    /// - parameter visitors The collection of visitors to run
    public init(visitors: [ViolationSyntaxVisiting]) {
        self.visitors = visitors
    }

    func collectViolations<SyntaxType: SyntaxProtocol>(_ node: SyntaxType) -> [AbsolutePosition] {
        visitors.flatMap { $0.findViolations(node) }
    }
}
