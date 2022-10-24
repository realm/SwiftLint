import Foundation
import SwiftSyntax

public struct IdentifierNameRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = NameConfiguration(minLengthWarning: 3,
                                                 minLengthError: 2,
                                                 maxLengthWarning: 40,
                                                 maxLengthError: 60,
                                                 excluded: ["id"])

    public init() {}

    public static let description = RuleDescription(
        identifier: "identifier_name",
        name: "Identifier Name",
        description: "Identifier names should only contain alphanumeric characters and " +
            "start with a lowercase character or should only contain capital letters. " +
            "In an exception to the above, variable names may start with a capital letter " +
            "when they are declared static and immutable. Variable names should not be too " +
            "long or too short.",
        kind: .style,
        nonTriggeringExamples: IdentifierNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: IdentifierNameRuleExamples.triggeringExamples,
        deprecatedAliases: ["variable_name"]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension IdentifierNameRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: NameConfiguration

        init(configuration: NameConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: node.modifiers, kind: .function,
                                         violationPosition: node.funcKeyword.positionAfterSkippingLeadingTrivia) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: nil, kind: .enumElement,
                                         violationPosition: node.positionAfterSkippingLeadingTrivia) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            let violationPosition = node.letOrVarKeyword.positionAfterSkippingLeadingTrivia
            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let violation = violation(identifier: pattern.identifier, modifiers: node.modifiers,
                                                kind: .variable, violationPosition: violationPosition) else {
                    continue
                }

                violations.append(violation)
                return
            }
        }

        override func visitPost(_ node: FunctionParameterSyntax) {
            if let name = [node.secondName, node.firstName].compactMap({ $0 }).first,
               let violation = violation(identifier: name, modifiers: node.modifiers, kind: .variable,
                                         violationPosition: name.positionAfterSkippingLeadingTrivia) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ClosureParamSyntax) {
            if let violation = violation(identifier: node.name, modifiers: nil, kind: .variable,
                                         violationPosition: node.positionAfterSkippingLeadingTrivia) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ForInStmtSyntax) {
            if let pattern = node.pattern.as(IdentifierPatternSyntax.self),
                let violation = violation(identifier: pattern.identifier, modifiers: nil, kind: .variable,
                                          violationPosition: pattern.positionAfterSkippingLeadingTrivia) {
                violations.append(violation)
            }
        }

        private func violation(identifier: TokenSyntax,
                               modifiers: ModifierListSyntax?,
                               kind: ViolationKind,
                               violationPosition: AbsolutePosition) -> ReasonedRuleViolation? {
            let name = identifier.text
                .strippingLeadingUnderscoreIfPrivate(modifiers: modifiers)
                .replacingOccurrences(of: "`", with: "")
            guard name != "_",
                  !modifiers.containsOverride,
                  !configuration.excluded.contains(name),
                  let firstCharacter = name.first else {
                return nil
            }

            if kind != .function {
                let allowedSymbols = configuration.allowedSymbols.union(.alphanumerics)
                if !allowedSymbols.isSuperset(of: CharacterSet(charactersIn: name)) {
                    return ReasonedRuleViolation(
                        position: violationPosition,
                        reason: "\(kind.stringValue) name should only contain alphanumeric characters: '\(name)'",
                        severity: .error
                    )
                }

                if let severity = configuration.severity(forLength: name.count) {
                    let reason = "\(kind.stringValue) name should be between " +
                                 "\(configuration.minLengthThreshold) and " +
                                 "\(configuration.maxLengthThreshold) characters long: '\(name)'"

                    return ReasonedRuleViolation(
                        position: violationPosition,
                        reason: reason,
                        severity: severity
                    )
                }
            }

            let firstCharacterIsAllowed = configuration.allowedSymbols
                .isSuperset(of: CharacterSet(charactersIn: String(firstCharacter)))
            guard !firstCharacterIsAllowed else {
                return nil
            }
            let requiresCaseCheck = configuration.validatesStartWithLowercase
            if requiresCaseCheck &&
                !modifiers.containsStaticOrClass && name.isViolatingCase && !name.isOperator {
                let reason = "\(kind.stringValue) name should start with a lowercase character: '\(name)'"
                return ReasonedRuleViolation(
                    position: violationPosition,
                    reason: reason,
                    severity: .error
                )
            }

            return nil
        }
    }

    enum ViolationKind {
        case variable
        case function
        case enumElement

        var stringValue: String {
            switch self {
            case .variable:
                return "Variable"
            case .function:
                return "Function"
            case .enumElement:
                return "Enum element"
            }
        }
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
}
