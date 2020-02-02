import Foundation
import SourceKittenFramework

public struct UnusedOptionalBindingRule: ASTRule, ConfigurationProviderRule {
    public var configuration = UnusedOptionalBindingConfiguration(ignoreOptionalTry: false)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_optional_binding",
        name: "Unused Optional Binding",
        description: "Prefer `!= nil` over `let _ =`",
        kind: .style,
        nonTriggeringExamples: [
            Example("if let bar = Foo.optionalValue {\n" +
            "}\n"),
            Example("if let (_, second) = getOptionalTuple() {\n" +
            "}\n"),
            Example("if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {\n" +
            "}\n"),
            Example("if foo() { let _ = bar() }\n"),
            Example("if foo() { _ = bar() }\n"),
            Example("if case .some(_) = self {}"),
            Example("if let point = state.find({ _ in true }) {}")
        ],
        triggeringExamples: [
            Example("if let ↓_ = Foo.optionalValue {\n" +
            "}\n"),
            Example("if let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {\n" +
            "}\n"),
            Example("guard let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {\n" +
            "}\n"),
            Example("if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {\n" +
            "}\n"),
            Example("if let (first, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {\n" +
            "}\n"),
            Example("if let (_, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {\n" +
            "}\n"),
            Example("if let ↓(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {\n" +
            "}\n"),
            Example("func foo() {\nif let ↓_ = bar {\n}\n"),
            Example("if case .some(let ↓_) = self {}")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let conditionKind = "source.lang.swift.structure.elem.condition_expr"
        guard kind == .if || kind == .guard else {
            return []
        }

        let elements = dictionary.elements.filter { $0.kind == conditionKind }
        return elements.flatMap { element -> [StyleViolation] in
            guard let byteRange = element.byteRange,
                let range = file.stringView.byteRangeToNSRange(byteRange)
            else {
                return []
            }

            return violations(in: range, of: file, with: kind).map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file, characterOffset: $0.location))
            }
        }
    }

    private func violations(in range: NSRange, of file: SwiftLintFile, with kind: StatementKind) -> [NSRange] {
        let kinds = SyntaxKind.commentAndStringKinds

        let underscorePattern = "(_\\s*[=,)]\\s*(try\\?)?)"
        let underscoreTuplePattern = "(\\((\\s*[_,]\\s*)+\\)\\s*=\\s*(try\\?)?)"
        let letUnderscore = "let\\s+(\(underscorePattern)|\(underscoreTuplePattern))"

        let matches = file.matchesAndSyntaxKinds(matching: letUnderscore, range: range)

        return matches
            .filter { kinds.isDisjoint(with: $0.1) }
            .filter { kind != .guard || !containsOptionalTry(at: $0.0.range, of: file) }
            .map { $0.0.range(at: 1) }
    }

    private func containsOptionalTry(at range: NSRange, of file: SwiftLintFile) -> Bool {
        guard configuration.ignoreOptionalTry else {
            return false
        }

        let matches = file.match(pattern: "try?", with: [.keyword], range: range)
        return !matches.isEmpty
    }
}
