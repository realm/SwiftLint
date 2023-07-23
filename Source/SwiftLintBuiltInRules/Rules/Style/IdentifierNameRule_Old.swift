import Foundation
import SourceKittenFramework

struct IdentifierNameRule_Old: ASTRule, ConfigurationProviderRule {
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

    func validate(
        file: SwiftLintFile,
        kind: SwiftDeclarationKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {
        guard !dictionary.enclosedSwiftAttributes.contains(.override) else {
            return []
        }

        return validateName(dictionary: dictionary, kind: kind).map { name, offset in
            guard let firstCharacter = name.first, !configuration.shouldExclude(name: name) else {
                return []
            }
            let type = self.type(for: kind)
            if !SwiftDeclarationKind.functionKinds.contains(kind) {
                if !configuration.allowedSymbolsAndAlphanumerics.isSuperset(of: CharacterSet(charactersIn: name)) {
                    return [
                        StyleViolation(ruleDescription: Self.description,
                                       severity: configuration.unallowedSymbolsSeverity.severity,
                                       location: Location(file: file, byteOffset: offset),
                                       reason: """
                                            \(type) name '\(name)' should only contain alphanumeric and other \
                                            allowed characters
                                            """)
                    ]
                }

                if let severity = configuration.severity(forLength: name.count) {
                    let reason = "\(type) name '\(name)' should be between " +
                        "\(configuration.minLengthThreshold) and " +
                        "\(configuration.maxLengthThreshold) characters long"
                    return [
                        StyleViolation(ruleDescription: Self.description,
                                       severity: severity,
                                       location: Location(file: file, byteOffset: offset),
                                       reason: reason)
                    ]
                }
            }

            if configuration.allowedSymbols.contains(String(firstCharacter)) {
                return []
            }
            if let caseCheckSeverity = configuration.validatesStartWithLowercase.severity,
                kind != .varStatic && name.isViolatingCase && !name.isOperator {
                let reason = "\(type) name '\(name)' should start with a lowercase character"
                return [
                    StyleViolation(ruleDescription: Self.description,
                                   severity: caseCheckSeverity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: reason)
                ]
            }

            return []
        } ?? []
    }

    private func validateName(
        dictionary: SourceKittenDictionary,
        kind: SwiftDeclarationKind
    ) -> (name: String, offset: ByteCount)? {
        guard
            var name = dictionary.name,
            let offset = dictionary.offset,
            kinds.contains(kind),
            !name.hasPrefix("$")
        else { return nil }

        if
            kind == .enumelement,
            let parenIndex = name.firstIndex(of: "("),
            parenIndex > name.startIndex
        {
            let index = name.index(before: parenIndex)
            name = String(name[...index])
        }

        return (name.nameStrippingLeadingUnderscoreIfPrivate(dictionary), offset)
    }

    private let kinds: Set<SwiftDeclarationKind> = {
        return SwiftDeclarationKind.variableKinds
            .union(SwiftDeclarationKind.functionKinds)
            .union([.enumelement])
    }()

    private func type(for kind: SwiftDeclarationKind) -> String {
        if SwiftDeclarationKind.functionKinds.contains(kind) {
            return "Function"
        } else if kind == .enumelement {
            return "Enum element"
        } else {
            return "Variable"
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

    func nameStrippingLeadingUnderscoreIfPrivate(_ dict: SourceKittenDictionary) -> String {
        if let acl = dict.accessibility,
            acl.isPrivate && first == "_" {
            return String(self[index(after: startIndex)...])
        }
        return self
    }
}
