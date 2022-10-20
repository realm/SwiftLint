import Foundation
import SwiftSyntax

public struct TypeNameRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = NameConfiguration(minLengthWarning: 3,
                                                 minLengthError: 0,
                                                 maxLengthWarning: 40,
                                                 maxLengthError: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_name",
        name: "Type Name",
        description: "Type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 3 and 40 characters in length." +
                     "Private types may start with an underscore.",
        kind: .idiomatic,
        nonTriggeringExamples: TypeNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: TypeNameRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension TypeNameRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: NameConfiguration

        init(configuration: NameConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypeCollection) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypeCollection) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: TypealiasDeclSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: node.modifiers, inheritedTypes: nil) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: AssociatedtypeDeclSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypeCollection) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypeCollection) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if let violation = violation(identifier: node.identifier, modifiers: node.modifiers,
                                         inheritedTypes: node.inheritanceClause?.inheritedTypeCollection) {
                violations.append(violation)
            }
        }

        private func violation(identifier: TokenSyntax,
                               modifiers: ModifierListSyntax?,
                               inheritedTypes: InheritedTypeListSyntax?) -> ReasonedRuleViolation? {
            let originalName = identifier.text
            guard !configuration.excluded.contains(originalName) else {
                return nil
            }

            let name = originalName
                .strippingLeadingUnderscoreIfPrivate(modifiers: modifiers)
                .strippingTrailingSwiftUIPreviewProvider(inheritedTypes: inheritedTypes)
            let allowedSymbols = configuration.allowedSymbols.union(.alphanumerics)

            if !allowedSymbols.isSuperset(of: CharacterSet(charactersIn: name)) {
                return ReasonedRuleViolation(
                    position: identifier.positionAfterSkippingLeadingTrivia,
                    reason: "Type name should only contain alphanumeric characters: '\(name)'",
                    severity: .error
                )
            } else if configuration.validatesStartWithLowercase &&
                name.first?.isLowercase == true {
                return ReasonedRuleViolation(
                    position: identifier.positionAfterSkippingLeadingTrivia,
                    reason: "Type name should start with an uppercase character: '\(name)'",
                    severity: .error
                )
            } else if let severity = configuration.severity(forLength: name.count) {
                return ReasonedRuleViolation(
                    position: identifier.positionAfterSkippingLeadingTrivia,
                    reason: "Type name should be between \(configuration.minLengthThreshold) and " +
                            "\(configuration.maxLengthThreshold) characters long: '\(name)'",
                    severity: severity
                )
            }

            return nil
        }
    }
}

private extension String {
    func strippingTrailingSwiftUIPreviewProvider(inheritedTypes: InheritedTypeListSyntax?) -> String {
        guard let inheritedTypes = inheritedTypes,
              hasSuffix("_Previews"),
              let lastPreviewsIndex = lastIndex(of: "_Previews"),
              inheritedTypes.typeNames.contains("PreviewProvider") else {
            return self
        }

        return substring(from: 0, length: lastPreviewsIndex)
    }

    func strippingLeadingUnderscoreIfPrivate(modifiers: ModifierListSyntax?) -> String {
        if first == "_", modifiers.isPrivateOrFileprivate {
            return String(self[index(after: startIndex)...])
        }
        return self
    }
}

private extension InheritedTypeListSyntax {
    var typeNames: Set<String> {
        Set(compactMap { $0.typeName.as(SimpleTypeIdentifierSyntax.self) }.map(\.name.text))
    }
}

private extension ModifierListSyntax? {
    var isPrivateOrFileprivate: Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { elem in
            elem.name.tokenKind == .privateKeyword || elem.name.tokenKind == .fileprivateKeyword
        }
    }
}
