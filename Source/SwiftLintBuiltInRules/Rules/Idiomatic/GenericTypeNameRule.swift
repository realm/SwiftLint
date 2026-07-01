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
        nonTriggeringExamples: #examples([
            "func foo<T>() {}",
            "func foo<T>() -> T {}",
            "func foo<`func`>() {}".configuration(["excluded": ["`.+`"]]),
            "func foo<T, U>(param: U) -> T {}",
            "func foo<T: Hashable, U: Rule>(param: U) -> T {}",
            "struct Foo<T> {}",
            "class Foo<T> {}",
            "enum Foo<T> {}",
            "func run(_ options: NoOptions<CommandantError<()>>) {}",
            "func foo(_ options: Set<type>) {}",
            "func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool",
            "func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)",
            "typealias StringDictionary<T> = Dictionary<String, T>",
            "typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)",
            "typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>",
            "struct Foo<let count: Int> {}",
            "struct Bar<let size: Int, T> {}",
        ]),
        triggeringExamples: #examples([
            "func foo<↓T_Foo>() {}",
            "func foo<↓`func`>() {}",
            "func foo<T, ↓U_Foo>(param: U_Foo) -> T {}",
            "func foo<↓\(String(repeating: "T", count: 21))>() {}",
            "func foo<↓type>() {}",
            "typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>",
            "typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)",
            "typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T_Foo, String>",
        ]) + ["class", "struct", "enum"].flatMap { type -> [Example] in
            #examples([
                "\(type) Foo<↓T_Foo> {}",
                "\(type) Foo<T, ↓U_Foo> {}",
                "\(type) Foo<↓T_Foo, ↓U_Foo> {}",
                "\(type) Foo<↓\(String(repeating: "T", count: 21))> {}",
                "\(type) Foo<↓type> {}",
            ])
        }
    )
}

private extension GenericTypeNameRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: GenericParameterSyntax) {
            let name = node.name.text
            guard !name.isEmpty,
                  !configuration.shouldExclude(name: name),
                  node.specifier?.tokenKind != .keyword(.let) else {
                return
            }

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
