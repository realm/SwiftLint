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
        override func visitPost(_ node: AccessorParametersSyntax) {
            collectViolations(from: .variable(name: node.name.text, isStatic: false, isPrivate: false), on: node.name)
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
            let staticKeyword = varDecl?.modifiers.staticOrClassModifier
            let position = staticKeyword?.name ?? varDecl?.bindingSpecifier ?? node.identifier
            collectViolations(from: type, on: position)
        }

        override func visitPost(_ node: ClosureShorthandParameterSyntax) {
            collectViolations(
                from: .variable(name: node.name.text.leadingDollarStripped, isStatic: false, isPrivate: false),
                on: node.name
            )
        }

        override func visitPost(_ node: ClosureParameterSyntax) {
            let name = (node.secondName ?? node.firstName).text.leadingDollarStripped
            if node.modifiers.contains(keyword: .override) {
                return
            }
            collectViolations(from: .variable(name: name, isStatic: false, isPrivate: false), on: node.firstName)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            let name = node.name.text
            if node.modifiers.contains(keyword: .override) || name.isOperator {
                return
            }
            let type = NamedDeclType.function(
                name: name,
                resolvedName: node.resolvedName,
                isPrivate: node.modifiers.containsPrivateOrFileprivate()
            )
            let staticKeyword = node.modifiers.staticOrClassModifier
            collectViolations(from: type, on: staticKeyword?.name ?? node.funcKeyword)
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

        override func visitPost(_ node: FunctionParameterSyntax) {
            if !node.modifiers.contains(keyword: .override) {
                let name = (node.secondName ?? node.firstName).text
                collectViolations(from: .variable(name: name, isStatic: false, isPrivate: false), on: node.firstName)
            }
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            collectViolations(from: .enumElement(name: node.name.text), on: node.name)
        }

        override func visitPost(_ node: EnumCaseParameterSyntax) {
            if let param = node.secondName ?? node.firstName, let position = node.firstName {
                collectViolations(from: .variable(name: param.text, isStatic: false, isPrivate: false), on: position)
            }
        }

        private func violates(_ type: NamedDeclType) -> (reason: String, severity: ViolationSeverity)? {
            guard !configuration.shouldExclude(name: type.name), type.name != "_",
                  let firstCharacter = type.name.first else {
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

private extension DeclModifierListSyntax {
    var staticOrClassModifier: DeclModifierSyntax? {
        first { ["static", "class"].contains($0.name.text) }
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

private extension VariableDeclSyntax {
    var allDeclaredNames: [String] {
        bindings
            .map(\.pattern)
            .flatMap { pattern -> [String] in
                if let id = pattern.as(IdentifierPatternSyntax.self) {
                    [id.identifier.text]
                } else if let tuple = pattern.as(TuplePatternSyntax.self) {
                    tuple.elements.compactMap {
                        $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                    }
                } else {
                    []
                }
            }
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

    var isOperator: Bool {
        let operators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", ".", "%", "<", ">", "&"]
        return operators.contains(where: hasPrefix)
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
