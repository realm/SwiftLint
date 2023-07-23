import Foundation
import SwiftSyntax

struct IdentifierNameRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = NameConfiguration<Self>(
        minLengthWarning: 3,
        minLengthError: 2,
        maxLengthWarning: 40,
        maxLengthError: 60,
        excluded: ["id"])

    static let description = RuleDescription(
        identifier: "identifier_name",
        name: "Identifier Name",
        description: """
           Identifier names should only contain alphanumeric characters and \
           start with a lowercase character or should only contain capital letters. \
           In an exception to the above, variable names may start with a capital letter \
           when they are declared as static. Variable names should not be too \
           long or too short
           """,
        kind: .style,
        nonTriggeringExamples: IdentifierNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: IdentifierNameRuleExamples.triggeringExamples,
        deprecatedAliases: ["variable_name"]
    )

	func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
		Visitor(configuration: configuration, sourceLocationConverter: file.locationConverter)
	}
}

extension IdentifierNameRule {
    final class Visitor: ViolationsSyntaxVisitor {
        typealias Parent = IdentifierNameRule // swiftlint:disable:this nesting

        private var configuration: NameConfiguration<Parent>
        private var configurationStack: [NameConfiguration<Parent>] = []

        private static let maximumClosureLineCount = 10

        let sourceLocationConverter: SourceLocationConverter

        init(
            configuration: NameConfiguration<Parent>,
            sourceLocationConverter: SourceLocationConverter) {
                self.sourceLocationConverter = sourceLocationConverter
                self.configuration = configuration
                super.init(viewMode: .sourceAccurate)
            }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            validateIdentifierNode(node.identifier, ofType: .enumElement)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            let identifier = node.identifier

            switch identifier.tokenKind {
            case .binaryOperator, .prefixOperator, .postfixOperator:
                return
            default: break
            }

            validateIdentifierNode(identifier, ofType: .function)
        }

        override func visitPost(_ node: IdentifierPatternSyntax) {
            validateIdentifierNode(node.identifier, ofType: .variable)
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            if
                configuration.ignoreMinLengthForShortClosureContent,
                closureLineCount(node) <= Self.maximumClosureLineCount {
                do {
                    let currentConfig = self.configuration

                    try configuration.apply(configuration: ["min_length": 0])
                    configurationStack.append(currentConfig)
                } catch {
                    queuedFatalError("Failed creating temporary config")
                }
            }
            return .visitChildren
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if
                configuration.ignoreMinLengthForShortClosureContent,
                closureLineCount(node) <= Self.maximumClosureLineCount  {
                configuration = configurationStack.popLast() ?? configuration
            }
        }

        private func validateIdentifierNode(
            _ identifier: TokenSyntax,
            ofType identifierType: IdentifierType) {
                let name = cleanupName(identifier.text)
                // confirm this node isn't in the exclusion list
                // and that it has at least one character
                guard
                    let firstCharacter = name.first.map(String.init),
                    configuration.shouldExclude(name: name) == false
                else { return }

                // confirm this isn't an override
                let previousNodes = lastThreeNodes(identifier: identifier)
                guard nodeIsOverridden(previousNodes: previousNodes) == false else { return }
                guard
                    let previousNode = previousNodes.first
                else { queuedFatalError("No declaration node") }

                // alphanumeric characters
                let nameForValidation = nodeIsPrivate(previousNodes: previousNodes) ? privateName(name) : name
                let nameValidation = validate(
                    name: nameForValidation,
                    of: identifierType,
                    isValidWithin: configuration.allowedSymbolsAndAlphanumerics)
                if case .fail(let reason, let severity) = nameValidation {
                    appendViolation(
                        at: previousNode.positionAfterSkippingLeadingTrivia,
                        reason: reason,
                        severity: severity)
                    return
                }

                // identifier length
                let lengthValidation = validateLength(of: name, ofType: identifierType, previousNode: previousNode)
                if case .fail(let reason, let severity) = lengthValidation {
                    appendViolation(
                        at: previousNode.positionAfterSkippingLeadingTrivia,
                        reason: reason,
                        severity: severity)
                    return
                }

                // at this point, the characters are all valid, it's just a matter of checking
                // specifics regarding conditions on character positioning

                // allowed starter symbols
                guard
                    configuration.allowedSymbols.contains(firstCharacter) == false
                else { return }

                // nix CapitalCase values.
                let camelValidation = validateCamelCase(of: name, ofType: identifierType, previousNodes: previousNodes)
                if case .fail(let reason, let severity) = camelValidation {
                    let locationOffset: Int
                    switch identifierType {
                    case .enumElement:
                        locationOffset = sourceLocationConverter
                            .location(for: identifier.positionAfterSkippingLeadingTrivia)
                            .offset
                    default:
                        locationOffset = sourceLocationConverter
                            .location(for: previousNode.positionAfterSkippingLeadingTrivia)
                            .offset
                    }
                    appendViolation(
                        at: AbsolutePosition(utf8Offset: locationOffset),
                        reason: reason,
                        severity: severity)
                }
            }

		private func lastThreeNodes(identifier node: TokenSyntax) -> [TokenSyntax] {
			var out: [TokenSyntax] = []

			var current: TokenSyntax? = node
			while
				let previous = current?.previousToken(viewMode: .sourceAccurate),
				out.count < 3 {
				defer { current = current?.previousToken(viewMode: .sourceAccurate) }
				out.append(previous)
			}

			return out
		}

		private func nodeIsPrivate(previousNodes: [TokenSyntax]) -> Bool {
			previousNodes.contains(where: { $0.tokenKind == .keyword(.private) })
		}

        private func privateName(_ name: String) -> String {
            guard name.first == "_" else { return name }
            return String(name[name.index(after: name.startIndex)...])
        }

        private func nodeIsStaticVariable(_ previousNodes: [TokenSyntax]) -> Bool {
            nodeIsStatic(previousNodes: previousNodes) && nodeIsVariable(previousNodes: previousNodes)
        }

        private func nodeIsVariable(previousNodes: [TokenSyntax]) -> Bool {
            previousNodes.contains(where: { $0.tokenKind == .keyword(.let) }) ||
            previousNodes.contains(where: { $0.tokenKind == .keyword(.var) })
        }

		private func nodeIsStatic(previousNodes: [TokenSyntax]) -> Bool {
			previousNodes.contains(where: { $0.tokenKind == .keyword(.static) })
		}

		private func nodeIsOverridden(previousNodes: [TokenSyntax]) -> Bool {
			previousNodes.contains(where: { $0.tokenKind == .keyword(.override) })
		}

		private func closureLineCount(_ node: ClosureExprSyntax) -> Int {
			let startLine = node.startLocation(converter: sourceLocationConverter).line
			let endLine = node.endLocation(converter: sourceLocationConverter).line
			return endLine - startLine
		}

		private func nameIsViolatingCase(_ name: String) -> Bool {
			guard
				let firstCharacter = name.first
			else {
				return true // Empty Identifier - should be impossible
			}
			if firstCharacter.isLowercase {
				return false
			}

			guard
				let secondIndex = name.index(
                    name.startIndex,
                    offsetBy: 1,
                    limitedBy: name.endIndex)
			else { return true }
			let secondCharacter = name[secondIndex]
			return secondCharacter.isLowercase
		}

        private func validate(
            name: String,
            of identifierType: IdentifierType,
            isValidWithin characterSet: CharacterSet) -> Validation {
                guard characterSet.isSuperset(of: CharacterSet(charactersIn: name)) else {
                    let reason = """
                        \(identifierType.rawValue.localizedCapitalized) name '\(name)' should only contain \
                        alphanumeric and other allowed characters
                        """
                    return .fail(reason: reason, severity: configuration.unallowedSymbolsSeverity.severity)
                }
                return .pass
            }

        private func validateLength(
            of name: String,
            ofType identifierType: IdentifierType,
            previousNode: TokenSyntax) -> Validation {
                if let severity = configuration.severity(forLength: name.count) {
                    let reason = """
                        \(identifierType.rawValue.localizedCapitalized) name '\(name)' should be between \
                        \(configuration.minLengthThreshold) and \(configuration.maxLengthThreshold) characters long \
                        (\(name.count) characters)
                        """
                    return .fail(reason: reason, severity: severity)
                }
                return .pass
            }

        private func validateCamelCase(
            of name: String,
            ofType identifierType: IdentifierType,
            previousNodes: [TokenSyntax]) -> Validation {
                if
                    let severity = configuration.validatesStartWithLowercase.severity,
                    name.first?.isUppercase == true,
                    nameIsViolatingCase(name) {
                    let reason = """
                        \(identifierType.rawValue.localizedCapitalized) name '\(name)' should start \
                        with a lowercase character
                        """
                    // make an exeption for CamelCase static var/let
                    if nodeIsStaticVariable(previousNodes) == false {
                        return .fail(reason: reason, severity: severity)
                    }
                }
                return .pass
            }

        @discardableResult
        private func appendViolation(
            at position: AbsolutePosition,
            reason: String,
            severity: ViolationSeverity) -> ReasonedRuleViolation {
                let violation = ReasonedRuleViolation(
                    position: position,
                    reason: reason,
                    severity: severity)
                violations.append(violation)
                return violation
            }

        private func cleanupName(_ name: String) -> String {
            guard
                name.first == "`",
                name.last == "`",
                name.count >= 3
            else { return name }
            let oneInFront = name.index(after: name.startIndex)
            let oneInBack = name.index(before: name.endIndex)
            return String(name[oneInFront..<oneInBack])
        }

        enum Validation { // swiftlint:disable:this nesting
            case pass
            case fail(reason: String, severity: ViolationSeverity)
        }
	}
}

extension IdentifierNameRule {
    enum IdentifierType: String {
        case variable
        case function
        case enumElement = "enum element"
    }
}
