import Foundation
import SwiftSyntax

struct GenericTypeNameRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = NameConfiguration<Self>(minLengthWarning: 1,
                                                minLengthError: 0,
                                                maxLengthWarning: 20,
                                                maxLengthError: 1000)

    static let description = RuleDescription(
        identifier: "generic_type_name",
        name: "Generic Type Name",
        description: "Generic type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 1 and 20 characters in length.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "func foo<T>() {}\n",
            "func foo<T>() -> T {}\n",
            "func foo<T, U>(param: U) -> T {}\n",
            "func foo<T: Hashable, U: Rule>(param: U) -> T {}\n",
            "struct Foo<T> {}\n",
            "class Foo<T> {}\n",
            "enum Foo<T> {}\n",
            "func run(_ options: NoOptions<CommandantError<()>>) {}\n",
            "func foo(_ options: Set<type>) {}\n",
            "func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool\n",
            "func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)\n",
            "typealias StringDictionary<T> = Dictionary<String, T>\n",
            "typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)\n",
            "typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>\n"
        ],
        triggeringExamples: [
            "func foo<↓T_Foo>() {}\n",
            "func foo<T, ↓U_Foo>(param: U_Foo) -> T {}\n",
            "func foo<↓\(String(repeating: "T", count: 21))>() {}\n",
            "func foo<↓type>() {}\n",
            "typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>\n",
            "typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)\n",
            "typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T_Foo, String>\n"
        ] + ["class", "struct", "enum"].flatMap { type -> [Example] in
            return [
                "\(type) Foo<↓T_Foo> {}\n",
                "\(type) Foo<T, ↓U_Foo> {}\n",
                "\(type) Foo<↓T_Foo, ↓U_Foo> {}\n",
                "\(type) Foo<↓\(String(repeating: "T", count: 21))> {}\n",
                "\(type) Foo<↓type> {}\n"
            ]
        }
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension GenericTypeNameRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: ConfigurationType

        init(configuration: ConfigurationType) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: GenericParameterSyntax) {
            let name = node.name.text
            guard !name.isEmpty, !configuration.shouldExclude(name: name) else { return }

            if !configuration.allowedSymbolsAndAlphanumerics.isSuperset(of: CharacterSet(charactersIn: name)) {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: """
                            Generic type name '\(name)' should only contain alphanumeric and other allowed characters
                            """,
                        severity: configuration.unallowedSymbolsSeverity.severity
                    )
                )
            } else if let caseCheckSeverity = configuration.validatesStartWithLowercase.severity,
                !String(name[name.startIndex]).isUppercase() {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Generic type name '\(name)' should start with an uppercase character",
                        severity: caseCheckSeverity
                    )
                )
            } else if let severity = configuration.severity(forLength: name.count) {
                let reason = "Generic type name '\(name)' should be between \(configuration.minLengthThreshold) and " +
                             "\(configuration.maxLengthThreshold) characters long"
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
