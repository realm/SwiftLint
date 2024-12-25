import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct AttributesRule: Rule {
    var configuration = AttributesConfiguration()

    static let description = RuleDescription(
        identifier: "attributes",
        name: "Attributes",
        description: """
            Attributes should be on their own lines in functions and types, but on the same line as variables and \
            imports
            """,
        kind: .style,
        nonTriggeringExamples: AttributesRuleExamples.nonTriggeringExamples,
        triggeringExamples: AttributesRuleExamples.triggeringExamples
    )
}

private extension AttributesRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: AttributeListSyntax) {
            guard let helper = node.makeHelper(locationConverter: locationConverter) else {
                return
            }

            let attributesAndPlacements = node.attributesAndPlacements(
                configuration: configuration,
                shouldBeOnSameLine: helper.shouldBeOnSameLine
            )

            let hasViolation = helper.hasViolation(
                locationConverter: locationConverter,
                attributesAndPlacements: attributesAndPlacements,
                attributesWithArgumentsAlwaysOnNewLine: configuration.attributesWithArgumentsAlwaysOnNewLine
            )

            switch hasViolation {
            case .argumentsAlwaysOnNewLineViolation:
                let reason = """
                    Attributes with arguments or inside always_on_line_above must be on a new line \
                    instead of the same line
                    """

                violations.append(
                    ReasonedRuleViolation(
                        position: helper.violationPosition,
                        reason: reason,
                        severity: configuration.severityConfiguration.severity
                    )
                )
                return
            case .violation:
                violations.append(helper.violationPosition)
                return
            case .noViolation:
                break
            }

            let linesForAttributes = attributesAndPlacements
                .filter { $1 == .dedicatedLine }
                .map { $0.0.endLine(locationConverter: locationConverter) }

            if linesForAttributes.isEmpty {
                return
            }
            if !linesForAttributes.contains(helper.keywordLine - 1) {
                violations.append(helper.violationPosition)
                return
            }

            let hasMultipleNewlines = node.children(viewMode: .sourceAccurate).enumerated().contains { index, element in
                if index > 0 && element.leadingTrivia.hasMultipleNewlines == true {
                    return true
                }
                return element.trailingTrivia.hasMultipleNewlines == true
            }

            if hasMultipleNewlines {
                violations.append(helper.violationPosition)
                return
            }
        }
    }
}

private extension SyntaxProtocol {
    func startLine(locationConverter: SourceLocationConverter) -> Int? {
        locationConverter.location(for: positionAfterSkippingLeadingTrivia).line
    }

    func endLine(locationConverter: SourceLocationConverter) -> Int? {
        locationConverter.location(for: endPositionBeforeTrailingTrivia).line
    }
}

private extension Trivia {
    var hasMultipleNewlines: Bool {
        reduce(0, { $0 + $1.numberOfNewlines }) > 1
    }
}

private extension TriviaPiece {
    var numberOfNewlines: Int {
        if case .newlines(let numberOfNewlines) = self {
            return numberOfNewlines
        }
        return 0
    }
}

private enum AttributePlacement {
    case sameLineAsDeclaration
    case dedicatedLine
}

private enum Violation {
    case argumentsAlwaysOnNewLineViolation
    case noViolation
    case violation
}

private struct RuleHelper {
    let violationPosition: AbsolutePosition
    let keywordLine: Int
    let shouldBeOnSameLine: Bool

    func hasViolation(
        locationConverter: SourceLocationConverter,
        attributesAndPlacements: [(AttributeSyntax, AttributePlacement)],
        attributesWithArgumentsAlwaysOnNewLine: Bool
    ) -> (Violation) {
        var linesWithAttributes: Set<Int> = [keywordLine]
        for (attribute, placement) in attributesAndPlacements {
            guard let attributeStartLine = attribute.startLine(locationConverter: locationConverter) else {
                continue
            }

            switch placement {
            case .sameLineAsDeclaration:
                if attributeStartLine != keywordLine {
                    return .violation
                }
            case .dedicatedLine:
                let hasViolation = attributeStartLine == keywordLine ||
                    linesWithAttributes.contains(attributeStartLine)
                linesWithAttributes.insert(attributeStartLine)
                if hasViolation {
                    if attributesWithArgumentsAlwaysOnNewLine && shouldBeOnSameLine {
                        return .argumentsAlwaysOnNewLineViolation
                    }
                    return .violation
                }
            }
        }
        return .noViolation
    }
}

private extension AttributeListSyntax {
    func attributesAndPlacements(configuration: AttributesConfiguration, shouldBeOnSameLine: Bool)
        -> [(AttributeSyntax, AttributePlacement)] {
        self
            .children(viewMode: .sourceAccurate)
            .compactMap { $0.as(AttributeSyntax.self) }
            .map { attribute in
                let atPrefixedName = "@\(attribute.attributeNameText)"
                if configuration.alwaysOnSameLine.contains(atPrefixedName) {
                    return (attribute, .sameLineAsDeclaration)
                }
                if configuration.alwaysOnNewLine.contains(atPrefixedName) {
                    return (attribute, .dedicatedLine)
                }
                if attribute.arguments != nil, configuration.attributesWithArgumentsAlwaysOnNewLine {
                    return (attribute, .dedicatedLine)
                }

                return shouldBeOnSameLine ? (attribute, .sameLineAsDeclaration) : (attribute, .dedicatedLine)
            }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func makeHelper(locationConverter: SourceLocationConverter) -> RuleHelper? {
        guard let parent else {
            return nil
        }

        let keyword: any SyntaxProtocol
        let shouldBeOnSameLine: Bool
        if let funcKeyword = parent.as(FunctionDeclSyntax.self)?.funcKeyword {
            keyword = funcKeyword
            shouldBeOnSameLine = false
        } else if let initKeyword = parent.as(InitializerDeclSyntax.self)?.initKeyword {
            keyword = initKeyword
            shouldBeOnSameLine = false
        } else if let enumKeyword = parent.as(EnumDeclSyntax.self)?.enumKeyword {
            keyword = enumKeyword
            shouldBeOnSameLine = false
        } else if let structKeyword = parent.as(StructDeclSyntax.self)?.structKeyword {
            keyword = structKeyword
            shouldBeOnSameLine = false
        } else if let classKeyword = parent.as(ClassDeclSyntax.self)?.classKeyword {
            keyword = classKeyword
            shouldBeOnSameLine = false
        } else if let extensionKeyword = parent.as(ExtensionDeclSyntax.self)?.extensionKeyword {
            keyword = extensionKeyword
            shouldBeOnSameLine = false
        } else if let protocolKeyword = parent.as(ProtocolDeclSyntax.self)?.protocolKeyword {
            keyword = protocolKeyword
            shouldBeOnSameLine = false
        } else if let importTok = parent.as(ImportDeclSyntax.self)?.importKeyword {
            keyword = importTok
            shouldBeOnSameLine = true
        } else if let letOrVarKeyword = parent.as(VariableDeclSyntax.self)?.bindingSpecifier {
            keyword = letOrVarKeyword
            shouldBeOnSameLine = true
        } else {
            return nil
        }

        guard let keywordLine = keyword.startLine(locationConverter: locationConverter) else {
            return nil
        }

        return RuleHelper(
            violationPosition: keyword.positionAfterSkippingLeadingTrivia,
            keywordLine: keywordLine,
            shouldBeOnSameLine: shouldBeOnSameLine
        )
    }
}
