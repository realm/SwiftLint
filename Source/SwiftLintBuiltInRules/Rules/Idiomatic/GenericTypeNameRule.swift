import Foundation
import SwiftSyntax

@SwiftSyntaxRule
struct GenericTypeNameRule: Rule {
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
            Example("func foo<T>() {}"),
            Example("func foo<T>() -> T {}"),
            Example("func foo<T, U>(param: U) -> T {}"),
            Example("func foo<T: Hashable, U: Rule>(param: U) -> T {}"),
            Example("struct Foo<T> {}"),
            Example("class Foo<T> {}"),
            Example("enum Foo<T> {}"),
            Example("func run(_ options: NoOptions<CommandantError<()>>) {}"),
            Example("func foo(_ options: Set<type>) {}"),
            Example("func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool"),
            Example("func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)"),
            Example("typealias StringDictionary<T> = Dictionary<String, T>"),
            Example("typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)"),
            Example("typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>"),
        ],
        triggeringExamples: [
            Example("func foo<↓T_Foo>() {}"),
            Example("func foo<T, ↓U_Foo>(param: U_Foo) -> T {}"),
            Example("func foo<↓\(String(repeating: "T", count: 21))>() {}"),
            Example("func foo<↓type>() {}"),
            Example("typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>"),
            Example("typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)"),
            Example("typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T_Foo, String>"),
        ] + ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                Example("\(type) Foo<↓T_Foo> {}"),
                Example("\(type) Foo<T, ↓U_Foo> {}"),
                Example("\(type) Foo<↓T_Foo, ↓U_Foo> {}"),
                Example("\(type) Foo<↓\(String(repeating: "T", count: 21))> {}"),
                Example("\(type) Foo<↓type> {}"),
            ]
        }
    )
}

private extension GenericTypeNameRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: GenericParameterSyntax) {
            let name = node.name.text
            guard !name.isEmpty, !configuration.shouldExclude(name: name) else { return }

            if !configuration.containsOnlyAllowedCharacters(name: name) {
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
