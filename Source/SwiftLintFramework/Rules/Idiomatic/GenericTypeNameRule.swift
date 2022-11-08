import Foundation
import SwiftSyntax

struct GenericTypeNameRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = NameConfiguration(minLengthWarning: 1,
                                          minLengthError: 0,
                                          maxLengthWarning: 20,
                                          maxLengthError: 1000)

    init() {}

    static let description = RuleDescription(
        identifier: "generic_type_name",
        name: "Generic Type Name",
        description: "Generic type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 1 and 20 characters in length.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("func foo<T>() {}\n"),
            Example("func foo<T>() -> T {}\n"),
            Example("func foo<T, U>(param: U) -> T {}\n"),
            Example("func foo<T: Hashable, U: Rule>(param: U) -> T {}\n"),
            Example("struct Foo<T> {}\n"),
            Example("class Foo<T> {}\n"),
            Example("enum Foo<T> {}\n"),
            Example("func run(_ options: NoOptions<CommandantError<()>>) {}\n"),
            Example("func foo(_ options: Set<type>) {}\n"),
            Example("func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool\n"),
            Example("func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)\n"),
            Example("typealias StringDictionary<T> = Dictionary<String, T>\n"),
            Example("typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)\n"),
            Example("typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>\n")
        ],
        triggeringExamples: [
            Example("func foo<↓T_Foo>() {}\n"),
            Example("func foo<T, ↓U_Foo>(param: U_Foo) -> T {}\n"),
            Example("func foo<↓\(String(repeating: "T", count: 21))>() {}\n"),
            Example("func foo<↓type>() {}\n"),
            Example("typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>\n"),
            Example("typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)\n"),
            Example("typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T_Foo, String>\n")
        ] + ["class", "struct", "enum"].flatMap { type -> [Example] in
            return [
                Example("\(type) Foo<↓T_Foo> {}\n"),
                Example("\(type) Foo<T, ↓U_Foo> {}\n"),
                Example("\(type) Foo<↓T_Foo, ↓U_Foo> {}\n"),
                Example("\(type) Foo<↓\(String(repeating: "T", count: 21))> {}\n"),
                Example("\(type) Foo<↓type> {}\n")
            ]
        }
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension GenericTypeNameRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: NameConfiguration

        init(configuration: NameConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: GenericParameterSyntax) {
            let name = node.name.text
            guard !configuration.excluded.contains(name) else {
                return
            }

            let allowedSymbols = configuration.allowedSymbols.union(.alphanumerics)
            if !allowedSymbols.isSuperset(of: CharacterSet(charactersIn: name)) {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Generic type name should only contain alphanumeric characters: '\(name)'",
                        severity: .error
                    )
                )
            } else if configuration.validatesStartWithLowercase &&
                !String(name[name.startIndex]).isUppercase() {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Generic type name should start with an uppercase character: '\(name)'",
                        severity: .error
                    )
                )
            } else if let severity = configuration.severity(forLength: name.count) {
                let reason = "Generic type name should be between \(configuration.minLengthThreshold) and " +
                             "\(configuration.maxLengthThreshold) characters long: '\(name)'"
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: reason,
                        severity: severity
                    )
                )
            }
        }
    }
}
