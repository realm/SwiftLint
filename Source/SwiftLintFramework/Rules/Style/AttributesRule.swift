import SwiftSyntax

struct AttributesRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = AttributesConfiguration()

    init() {}

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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(
            locationConverter: file.locationConverter,
            configuration: configuration
        )
    }
}

private extension AttributesRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let locationConverter: SourceLocationConverter
        private let configuration: AttributesConfiguration

        init(locationConverter: SourceLocationConverter, configuration: AttributesConfiguration) {
            self.locationConverter = locationConverter
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

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
                attributesAndPlacements: attributesAndPlacements
            )

            if hasViolation {
                violations.append(helper.violationPosition)
                return
            }

            let linesForAttributes = attributesAndPlacements
                .filter { $1 == .dedicatedLine }
                .map { $0.0.endLine(locationConverter: locationConverter) }

            if linesForAttributes.isEmpty {
                return
            } else if !linesForAttributes.contains(helper.keywordLine - 1) {
                violations.append(helper.violationPosition)
                return
            }

            let hasMultipleNewlines = node.children(viewMode: .sourceAccurate).enumerated().contains { index, element in
                if index > 0 && element.leadingTrivia?.hasMultipleNewlines == true {
                    return true
                } else {
                    return element.trailingTrivia?.hasMultipleNewlines == true
                }
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
        } else {
            return 0
        }
    }
}

private enum AttributePlacement {
    case sameLineAsDeclaration
    case dedicatedLine
}

private struct RuleHelper {
    let violationPosition: AbsolutePosition
    let keywordLine: Int
    let shouldBeOnSameLine: Bool

    func hasViolation(
        locationConverter: SourceLocationConverter,
        attributesAndPlacements: [(AttributeSyntax, AttributePlacement)]
    ) -> Bool {
        var linesWithAttributes: Set<Int> = [keywordLine]
        for (attribute, placement) in attributesAndPlacements {
            guard let attributeStartLine = attribute.startLine(locationConverter: locationConverter) else {
                continue
            }

            switch placement {
            case .sameLineAsDeclaration:
                if attributeStartLine != keywordLine {
                    return true
                }
            case .dedicatedLine:
                let hasViolation = attributeStartLine == keywordLine ||
                    linesWithAttributes.contains(attributeStartLine)
                linesWithAttributes.insert(attributeStartLine)
                if hasViolation {
                    return true
                }
            }
        }
        return false
    }
}

private extension AttributeListSyntax {
    func attributesAndPlacements(configuration: AttributesConfiguration, shouldBeOnSameLine: Bool)
        -> [(AttributeSyntax, AttributePlacement)] {
        self
            .children(viewMode: .sourceAccurate)
            .compactMap { $0.as(AttributeSyntax.self) }
            .map { attribute in
                let atPrefixedName = "@\(attribute.attributeName.text)"
                if configuration.alwaysOnSameLine.contains(atPrefixedName) {
                    return (attribute, .sameLineAsDeclaration)
                } else if configuration.alwaysOnNewLine.contains(atPrefixedName) {
                    return (attribute, .dedicatedLine)
                } else if attribute.argument != nil {
                    return (attribute, .dedicatedLine)
                }

                return shouldBeOnSameLine ? (attribute, .sameLineAsDeclaration) : (attribute, .dedicatedLine)
            }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func makeHelper(locationConverter: SourceLocationConverter) -> RuleHelper? {
        guard let parent = parent else {
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
        } else if let importTok = parent.as(ImportDeclSyntax.self)?.importTok {
            keyword = importTok
            shouldBeOnSameLine = true
        } else if let letOrVarKeyword = parent.as(VariableDeclSyntax.self)?.letOrVarKeyword {
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
