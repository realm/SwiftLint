import SwiftSyntax

public struct AttributesRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = AttributesConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "attributes",
        name: "Attributes",
        description: """
            Attributes should be on their own lines in functions and types, but on the same line as variables and \
            imports.
            """,
        kind: .style,
        nonTriggeringExamples: AttributesRuleExamples.nonTriggeringExamples,
        triggeringExamples: AttributesRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(
            locationConverter: file.locationConverter,
            configuration: configuration
        )
    }
}

private extension AttributesRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []
        private let locationConverter: SourceLocationConverter
        private let configuration: AttributesConfiguration

        init(locationConverter: SourceLocationConverter, configuration: AttributesConfiguration) {
            self.locationConverter = locationConverter
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ImportDeclSyntax) {
            let importLine = node.importTok.startLine(locationConverter: locationConverter)
            let hasViolation = node.attributes?.contains { attribute in
                attribute.startLine(locationConverter: locationConverter) != importLine
            } == true

            if hasViolation {
                violationPositions.append(node.importTok.positionAfterSkippingLeadingTrivia)
            }
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
                violationPositions.append(helper.violationPosition)
                return
            }

            let linesForAttributes = attributesAndPlacements
                .filter { $1 == .dedicatedLine }
                .map { $0.0.endLine(locationConverter: locationConverter) }

            if linesForAttributes.isEmpty {
                return
            } else if !linesForAttributes.contains(helper.declarationLine - 1) {
                violationPositions.append(helper.violationPosition)
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
                violationPositions.append(helper.violationPosition)
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
    let declarationLine: Int
    let shouldBeOnSameLine: Bool

    func hasViolation(
        locationConverter: SourceLocationConverter,
        attributesAndPlacements: [(AttributeSyntax, AttributePlacement)]
    ) -> Bool {
        var linesWithAttributes: Set<Int> = [declarationLine]
        for (attribute, placement) in attributesAndPlacements {
            guard let attributeStartLine = attribute.startLine(locationConverter: locationConverter) else {
                continue
            }

            switch placement {
            case .sameLineAsDeclaration:
                if attributeStartLine != declarationLine {
                    return true
                }
            case .dedicatedLine:
                let hasViolation = attributeStartLine == declarationLine ||
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

    func makeHelper(locationConverter: SourceLocationConverter) -> RuleHelper? {
        if
            let parent = parent?.as(VariableDeclSyntax.self),
            let letOrVarLine = parent.letOrVarKeyword.startLine(locationConverter: locationConverter)
        {
            return RuleHelper(
                violationPosition: parent.letOrVarKeyword.positionAfterSkippingLeadingTrivia,
                declarationLine: letOrVarLine,
                shouldBeOnSameLine: true
            )
        } else if
            let parent = parent?.as(FunctionDeclSyntax.self),
            let funcLine = parent.funcKeyword.startLine(locationConverter: locationConverter)
        {
            return RuleHelper(
                violationPosition: parent.funcKeyword.positionAfterSkippingLeadingTrivia,
                declarationLine: funcLine,
                shouldBeOnSameLine: false
            )
        } else if
            let parent = parent?.as(ClassDeclSyntax.self),
            let keywordLine = parent.classKeyword.startLine(locationConverter: locationConverter)
        {
            return RuleHelper(
                violationPosition: parent.classKeyword.positionAfterSkippingLeadingTrivia,
                declarationLine: keywordLine,
                shouldBeOnSameLine: false
            )
        } else {
            return nil
        }
    }
}
