import Foundation
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct IdentifierNameRule: Rule {
    var configuration = IdentifierNameConfiguration()

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
        private lazy var nameConfiguration = configuration.nameConfiguration

        override func visitPost(_ node: AccessorParametersSyntax) {
            collectViolations(from: .variable(name: node.name.text, isStatic: false, isPrivate: false), on: node.name)
        }

        override func visitPost(_ node: ClosureParameterSyntax) {
            if node.modifiers.contains(keyword: .override) {
                return
            }
            let name = node.secondName ?? node.firstName
            collectViolations(
                from: .variable(name: name.text.leadingDollarStripped, isStatic: false, isPrivate: false),
                on: name
            )
        }

        override func visitPost(_ node: ClosureShorthandParameterSyntax) {
            collectViolations(
                from: .variable(name: node.name.text.leadingDollarStripped, isStatic: false, isPrivate: false),
                on: node.name
            )
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            collectViolations(from: .enumElement(name: node.name.text), on: node.name)
        }

        override func visitPost(_ node: EnumCaseParameterSyntax) {
            if let name = node.secondName ?? node.firstName {
                collectViolations(from: .variable(name: name.text, isStatic: false, isPrivate: false), on: name)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            let name = node.name.text
            if node.modifiers.contains(keyword: .override) || isOperator(name: name) {
                return
            }
            let type = NamedDeclType.function(
                name: name,
                resolvedName: node.resolvedName,
                isPrivate: node.modifiers.containsPrivateOrFileprivate()
            )
            collectViolations(from: type, on: node.name)
        }

        override func visitPost(_ node: FunctionParameterSyntax) {
            if node.modifiers.contains(keyword: .override) {
                return
            }
            let name = (node.secondName ?? node.firstName)
            collectViolations(
                from: .variable(name: name.text, isStatic: false, isPrivate: false),
                on: name
            )
        }

        override func visitPost(_ node: IdentifierPatternSyntax) {
            let varDecl = node.enclosingVarDecl
            if varDecl?.modifiers.contains(keyword: .override) ?? false {
                return
            }
            let type = NamedDeclType.variable(
                name: node.identifier.text,
                isStatic: varDecl?.modifiers.contains(keyword: .static) ?? false,
                isPrivate: varDecl?.modifiers.containsPrivateOrFileprivate() ?? false
            )
            collectViolations(from: type, on: node.identifier)
        }

        private func collectViolations(from type: NamedDeclType, on token: TokenSyntax) {
            if let violation = violates(type) {
                violations.append(ReasonedRuleViolation(
                    position: token.positionAfterSkippingLeadingTrivia,
                    reason: violation.reason,
                    severity: violation.severity
                ))
            }
        }

        private func violates(_ type: NamedDeclType) -> (reason: String, severity: ViolationSeverity)? {
            guard !nameConfiguration.shouldExclude(name: type.name), type.name != "_",
                  let firstCharacter = type.name.first else {
                return nil
            }
            if case .function = type {
                // Do not perform additional checks.
            } else {
                if !nameConfiguration.containsOnlyAllowedCharacters(name: type.name) {
                    let reason = """
                        \(type) should only contain alphanumeric and other \
                        allowed characters
                        """
                    return (reason, nameConfiguration.unallowedSymbolsSeverity.severity)
                }

                if let severity = nameConfiguration.severity(forLength: type.name.count) {
                    let reason = """
                        \(type) should be between \
                        \(nameConfiguration.minLengthThreshold) and \
                        \(nameConfiguration.maxLengthThreshold) characters long
                        """
                    return (reason, severity)
                }
            }
            if nameConfiguration.allowedSymbols.contains(String(firstCharacter)) {
                return nil
            }
            if let caseCheckSeverity = nameConfiguration.validatesStartWithLowercase.severity,
               !type.isStatic, type.name.isViolatingCase, !isOperator(name: type.name) {
                let reason = "\(type) should start with a lowercase character"
                return (reason, caseCheckSeverity)
            }
            return nil
        }

        private func isOperator(name: String) -> Bool {
            configuration.additionalOperators.contains { name.hasPrefix($0) }
        }
    }
}

private extension IdentifierPatternSyntax {
    var enclosingVarDecl: VariableDeclSyntax? {
        let identifierDecl =
             parent?.as(PatternBindingSyntax.self)?
            .parent?.as(PatternBindingListSyntax.self)?
            .parent?.as(VariableDeclSyntax.self)
        if identifierDecl != nil {
            return identifierDecl
        }
        return
             parent?.as(TuplePatternElementSyntax.self)?
            .parent?.as(TuplePatternElementListSyntax.self)?
            .parent?.as(TuplePatternSyntax.self)?
            .parent?.as(PatternBindingSyntax.self)?
            .parent?.as(PatternBindingListSyntax.self)?
            .parent?.as(VariableDeclSyntax.self)
    }
}

private enum NamedDeclType: CustomStringConvertible {
    case function(name: String, resolvedName: String, isPrivate: Bool)
    case enumElement(name: String)
    case variable(name: String, isStatic: Bool, isPrivate: Bool)

    var description: String {
        switch self {
        case let .function(_, resolvedName, _): "Function name '\(resolvedName)'"
        case let .enumElement(name): "Enum element name '\(name)'"
        case let .variable(name, _, _): "Variable name '\(name)'"
        }
    }

    var isStatic: Bool {
        switch self {
        case .function, .enumElement: false
        case let .variable(_, isStatic, _): isStatic
        }
    }

    var isPrivate: Bool {
        switch self {
        case let .function(_, _, isPrivate): isPrivate
        case .enumElement: false
        case let .variable(_, _, isPrivate): isPrivate
        }
    }

    var name: String {
        let name = switch self {
        case let .function(name, _, _): name
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

    func strippingLeadingUnderscore(if isPrivate: Bool) -> Self {
        isPrivate && first == "_" ? allButFirstCharacter : self
    }

    var leadingDollarStripped: Self {
        first == "$" ? allButFirstCharacter : self
    }

    private var allButFirstCharacter: String {
        String(self[index(after: startIndex)...])
    }
}
