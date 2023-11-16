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
                if let text = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                    let name = text.strippingLeadingUnderscore(ifPrivate: node.modifiers.contains(keyword: .private))
                    let staticKeyword = node.modifiers.first { $0.name.text == "static" }
                    if let violation = violates(name, type: .variable(isStatic: staticKeyword != nil)) {
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

        override func visitPost(_ node: FunctionDeclSyntax) {
            let name = node.name.text
            if node.modifiers.contains(keyword: .override) || name.isOperator {
                return
            }
            if let violation = violates(name, type: .function(isStatic: node.modifiers.contains(keyword: .static))) {
                violations.append(ReasonedRuleViolation(
                    position: node.funcKeyword.positionAfterSkippingLeadingTrivia,
                    reason: violation.reason,
                    severity: violation.severity
                ))
            }
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            let name = node.name.text
            if let violation = violates(name, type: .enumElement) {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: violation.reason,
                    severity: violation.severity
                ))
            }
        }

        private func violates(_ name: String?, type: DeclType) -> (reason: String, severity: ViolationSeverity)? {
            guard let name = name?.trimmingCharacters(in: CharacterSet(charactersIn: "`")),
                  !configuration.shouldExclude(name: name), let firstCharacter = name.first else {
                return nil
            }
            if !type.isFunction {
                if !configuration.allowedSymbolsAndAlphanumerics.isSuperset(of: CharacterSet(charactersIn: name)) {
                    let reason = """
                        \(type) name '\(name)' should only contain alphanumeric and other \
                        allowed characters
                        """
                    return (reason, configuration.unallowedSymbolsSeverity.severity)
                }

                if let severity = configuration.severity(forLength: name.count) {
                    let reason = """
                        \(type) name '\(name)' should be between \
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
               !type.isStatic, name.isViolatingCase, !name.isOperator {
                let reason = "\(type) name '\(name)' should start with a lowercase character"
                return (reason, caseCheckSeverity)
            }
            return nil
        }
    }
}

private enum DeclType: CustomStringConvertible {
    case function(isStatic: Bool)
    case enumElement
    case variable(isStatic: Bool)

    var description: String {
        switch self {
        case .function: "Function"
        case .enumElement: "Enum element"
        case .variable: "Variable"
        }
    }

    var isStatic: Bool {
        switch self {
        case let .function(isStatic): isStatic
        case .enumElement: false
        case let .variable(isStatic): isStatic
        }
    }

    var isFunction: Bool {
        if case .function = self {
            return true
        }
        return false
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

    func strippingLeadingUnderscore(ifPrivate isPrivate: Bool) -> String {
        if isPrivate, first == "_" {
            return String(self[index(after: startIndex)...])
        }
        return self
    }
}
