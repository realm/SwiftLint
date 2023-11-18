import Foundation
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct IdentifierNameRule: Rule {
    var configuration = NameConfiguration<Self>(minLengthWarning: 3,
                                                minLengthError: 2,
                                                maxLengthWarning: 40,
                                                maxLengthError: 60,
                                                excluded: ["id"])

    static let description = RuleDescription(
        identifier: "identifier_name",
        name: "Identifier Name",
        description: "Identifier names should only contain alphanumeric characters and " +
            "start with a lowercase character or should only contain capital letters. " +
            "In an exception to the above, variable names may start with a capital letter " +
            "when they are declared as static. Variable names should not be too " +
            "long or too short.",
        kind: .style,
        nonTriggeringExamples: IdentifierNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: IdentifierNameRuleExamples.triggeringExamples,
        deprecatedAliases: ["variable_name"]
    )
}

private extension IdentifierNameRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            if node.modifiers.contains(keyword: .override) {
                return
            }
            for binding in node.bindings {
                if let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                    let staticKeyword = node.modifiers.first { $0.name.text == "static" }
                    let type = NamedDeclType.variable(
                        name: name,
                        isStatic: staticKeyword != nil,
                        isPrivate: node.modifiers.containsPrivateOrFileprivate()
                    )
                    if let violation = violates(type) {
                        let position = staticKeyword?.name ?? node.bindingSpecifier
                        violations.append(ReasonedRuleViolation(
                            position: position.positionAfterSkippingLeadingTrivia,
                            reason: violation.reason,
                            severity: violation.severity
                        ))
                    }
                }
            }
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            if let name = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                if let violation = violates(.variable(name: name, isStatic: false, isPrivate: false)) {
                    violations.append(ReasonedRuleViolation(
                        position: node.pattern.positionAfterSkippingLeadingTrivia,
                        reason: violation.reason,
                        severity: violation.severity
                    ))
                }
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            let name = node.name.text
            if node.modifiers.contains(keyword: .override) || name.isOperator {
                return
            }
            let type = NamedDeclType.function(
                name: name,
                resolvedName: node.resolvedName,
                isStatic: node.modifiers.contains(keyword: .static),
                isPrivate: node.modifiers.containsPrivateOrFileprivate()
            )
            if let violation = violates(type) {
                violations.append(ReasonedRuleViolation(
                    position: node.funcKeyword.positionAfterSkippingLeadingTrivia,
                    reason: violation.reason,
                    severity: violation.severity
                ))
            }
        }

        override func visitPost(_ node: FunctionParameterSyntax) {
            let name = (node.secondName ?? node.firstName).text
            if node.modifiers.contains(keyword: .override) || name == "_" {
                return
            }
            if let violation = violates(.variable(name: name, isStatic: false, isPrivate: false)) {
                violations.append(ReasonedRuleViolation(
                    position: node.firstName.positionAfterSkippingLeadingTrivia,
                    reason: violation.reason,
                    severity: violation.severity
                ))
            }
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            if let violation = violates(.enumElement(name: node.name.text)) {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: violation.reason,
                    severity: violation.severity
                ))
            }
        }

        private func violates(_ type: NamedDeclType) -> (reason: String, severity: ViolationSeverity)? {
            guard !configuration.shouldExclude(name: type.name), let firstCharacter = type.name.first else {
                return nil
            }
            if case .function = type {
                // Do not perform additional checks.
            } else {
                if !configuration.allowedSymbolsAndAlphanumerics.isSuperset(of: CharacterSet(charactersIn: type.name)) {
                    let reason = """
                        \(type) should only contain alphanumeric and other \
                        allowed characters
                        """
                    return (reason, configuration.unallowedSymbolsSeverity.severity)
                }

                if let severity = configuration.severity(forLength: type.name.count) {
                    let reason = """
                        \(type) should be between \
                        \(configuration.minLengthThreshold) and \
                        \(configuration.maxLengthThreshold) characters long
                        """
                    return (reason, severity)
                }
            }
            if configuration.allowedSymbols.contains(String(firstCharacter)) {
                return nil
            }
            if let caseCheckSeverity = configuration.validatesStartWithLowercase.severity,
               !type.isStatic, type.name.isViolatingCase, !type.name.isOperator {
                let reason = "\(type) should start with a lowercase character"
                return (reason, caseCheckSeverity)
            }
            return nil
        }
    }
}

private enum NamedDeclType: CustomStringConvertible {
    case function(name: String, resolvedName: String, isStatic: Bool, isPrivate: Bool)
    case enumElement(name: String)
    case variable(name: String, isStatic: Bool, isPrivate: Bool)

    var description: String {
        switch self {
        case let .function(_, resolvedName, _, _): "Function name '\(resolvedName)'"
        case let .enumElement(name): "Enum element name '\(name)'"
        case let .variable(name, _, _): "Variable name '\(name)'"
        }
    }

    var isStatic: Bool {
        switch self {
        case let .function(_, _, isStatic, _): isStatic
        case .enumElement: false
        case let .variable(_, isStatic, _): isStatic
        }
    }

    var isPrivate: Bool {
        switch self {
        case let .function(_, _, _, isPrivate): isPrivate
        case .enumElement: false
        case let .variable(_, _, isPrivate): isPrivate
        }
    }

    var name: String {
        let name = switch self {
        case let .function(name, _, _, _): name
        case let .enumElement(name): name
        case let .variable(name, _, _): name
        }
        return name
            .trimmingCharacters(in: CharacterSet(charactersIn: "`"))
            .strippingLeadingUnderscore(if: isPrivate)
    }
}

private extension String {
    var isViolatingCase: Bool {
        let firstCharacter = String(self[startIndex])
        guard firstCharacter.isUppercase() else {
            return false
        }
        guard count > 1 else {
            return true
        }
        let secondCharacter = String(self[index(after: startIndex)])
        return secondCharacter.isLowercase()
    }

    var isOperator: Bool {
        let operators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", ".", "%", "<", ">", "&"]
        return operators.contains(where: hasPrefix)
    }

    func strippingLeadingUnderscore(if isPrivate: Bool) -> String {
        if isPrivate, first == "_" {
            return String(self[index(after: startIndex)...])
        }
        return self
    }
}
