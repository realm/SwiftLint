import Foundation
import SwiftSyntax

struct TypeNameRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = TypeNameConfiguration()

    static let description = RuleDescription(
        identifier: "type_name",
        name: "Type Name",
        description: """
            Type name should only contain alphanumeric characters, start with an uppercase character and span between \
            3 and 40 characters in length.
            Private types may start with an underscore.
            """,
        kind: .idiomatic,
        nonTriggeringExamples: TypeNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: TypeNameRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension TypeNameRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: TypeNameConfiguration

        init(configuration: TypeNameConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if let violation = violation(identifier: node.name, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypes) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if let violation = violation(identifier: node.name, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypes) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            if let violation = violation(identifier: node.name, modifiers: node.modifiers, inheritedTypes: nil) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            if let violation = violation(identifier: node.name, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypes) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if let violation = violation(identifier: node.name, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypes) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if let violation = violation(identifier: node.name, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypes) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if configuration.validateProtocols,
               let violation = violation(identifier: node.name, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypes) {
                violations.append(violation)
            }
        }

        private func violation(identifier: TokenSyntax,
                               modifiers: DeclModifierListSyntax?,
                               inheritedTypes: InheritedTypeListSyntax?) -> ReasonedRuleViolation? {
            let originalName = identifier.text
            let nameConfiguration = configuration.nameConfiguration

            guard !nameConfiguration.shouldExclude(name: originalName) else { return nil }

            let name = originalName
                .strippingBackticks()
                .strippingLeadingUnderscoreIfPrivate(modifiers: modifiers)
                .strippingTrailingSwiftUIPreviewProvider(inheritedTypes: inheritedTypes)
            if !nameConfiguration.allowedSymbolsAndAlphanumerics.isSuperset(of: CharacterSet(charactersIn: name)) {
                return ReasonedRuleViolation(
                    position: identifier.positionAfterSkippingLeadingTrivia,
                    reason: "Type name '\(name)' should only contain alphanumeric and other allowed characters",
                    severity: nameConfiguration.unallowedSymbolsSeverity.severity
                )
            } else if let caseCheckSeverity = nameConfiguration.validatesStartWithLowercase.severity,
                name.first?.isLowercase == true {
                return ReasonedRuleViolation(
                    position: identifier.positionAfterSkippingLeadingTrivia,
                    reason: "Type name '\(name)' should start with an uppercase character",
                    severity: caseCheckSeverity
                )
            } else if let severity = nameConfiguration.severity(forLength: name.count) {
                return ReasonedRuleViolation(
                    position: identifier.positionAfterSkippingLeadingTrivia,
                    reason: "Type name '\(name)' should be between \(nameConfiguration.minLengthThreshold) and " +
                            "\(nameConfiguration.maxLengthThreshold) characters long",
                    severity: severity
                )
            }

            return nil
        }
    }
}

private extension String {
    func strippingBackticks() -> String {
        replacingOccurrences(of: "`", with: "")
    }

    func strippingTrailingSwiftUIPreviewProvider(inheritedTypes: InheritedTypeListSyntax?) -> String {
        guard let inheritedTypes,
              hasSuffix("_Previews"),
              let lastPreviewsIndex = lastIndex(of: "_Previews"),
              inheritedTypes.typeNames.contains("PreviewProvider") else {
            return self
        }

        return substring(from: 0, length: lastPreviewsIndex)
    }

    func strippingLeadingUnderscoreIfPrivate(modifiers: DeclModifierListSyntax?) -> String {
        if first == "_", modifiers.isPrivateOrFileprivate {
            return String(self[index(after: startIndex)...])
        }
        return self
    }
}

private extension InheritedTypeListSyntax {
    var typeNames: Set<String> {
        Set(compactMap { $0.type.as(IdentifierTypeSyntax.self) }.map(\.name.text))
    }
}
