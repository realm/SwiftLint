import Foundation
import SourceKittenFramework
import SwiftSyntax

private enum AttributesRuleError: Error {
    case unexpectedBlankLine
    case moreThanOneAttributeInSameLine
}

public struct AttributesRule: Rule, OptInRule, ConfigurationProviderRule {
    public var configuration = AttributesConfiguration()

    private static let parametersPattern = "^\\s*\\(.+\\)"
    private static let regularExpression = regex(parametersPattern, options: [])

    public init() {}

    public static let description = RuleDescription(
        identifier: "attributes",
        name: "Attributes",
        description: "Attributes should be on their own lines in functions and types, " +
                     "but on the same line as variables and imports.",
        kind: .style,
        nonTriggeringExamples: AttributesRuleExamples.nonTriggeringExamples,
        triggeringExamples: AttributesRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree else { return [] }

        let visitor = AttributesRuleVisitor(file: file, configuration: configuration)
        visitor.walk(tree)
        return visitor.positions.map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: position))
        }
    }
}

private final class AttributesRuleVisitor: SyntaxVisitor {
    var positions: [ByteCount] = []
    private let file: SwiftLintFile
    private let configuration: AttributesConfiguration

    init(file: SwiftLintFile, configuration: AttributesConfiguration) {
        self.file = file
        self.configuration = configuration
        super.init()
    }

    override func visitPost(_ node: ImportDeclSyntax) {
        guard let attributes = node.attributes else {
            return
        }

        let importOffset = ByteCount(node.importTok.positionAfterSkippingLeadingTrivia)
        guard let (importLine, _) = file.stringView.lineAndCharacter(forByteOffset: importOffset) else {
            return
        }

        for attr in attributes {
            let attributeOffset = ByteCount(attr.positionAfterSkippingLeadingTrivia)
            guard let (attributeLine, _) = file.stringView.lineAndCharacter(forByteOffset: attributeOffset),
                  attributeLine != importLine else {
                continue
            }


            positions.append(importOffset)
            return
        }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        guard let attributes = node.attributes,
              let position = validate(attributes: attributes, token: node.funcKeyword, fallbackValue: false) else {
            return
        }

        positions.append(position)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
        guard let attributes = node.attributes,
              let position = validate(attributes: attributes, token: node.initKeyword, fallbackValue: false) else {
            return
        }

        positions.append(position)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        guard let attributes = node.attributes,
              let position = validate(attributes: attributes, token: node.letOrVarKeyword, fallbackValue: true) else {
            return
        }

        positions.append(position)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        guard let attributes = node.attributes,
              let position = validate(attributes: attributes, token: node.classOrActorKeyword, fallbackValue: false) else {
            return
        }

        positions.append(position)
    }

    override func visitPost(_ node: StructDeclSyntax) {
        guard let attributes = node.attributes,
              let position = validate(attributes: attributes, token: node.structKeyword, fallbackValue: false) else {
            return
        }

        positions.append(position)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
        guard let attributes = node.attributes,
              let position = validate(attributes: attributes, token: node.protocolKeyword, fallbackValue: false) else {
            return
        }

        positions.append(position)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        guard let attributes = node.attributes,
              let position = validate(attributes: attributes, token: node.enumKeyword, fallbackValue: false) else {
            return
        }

        positions.append(position)
    }

    private func validate(attributes: AttributeListSyntax,
                          token: TokenSyntax,
                          fallbackValue: Bool) -> ByteCount? {
        let tokenOffset = ByteCount(token.positionAfterSkippingLeadingTrivia)
        guard let (tokenLine, _) = file.stringView.lineAndCharacter(forByteOffset: tokenOffset) else {
            return nil
        }

        var lines: [(line: Int, sameLine: Bool)] = []

        for attr in attributes {
            let attributeOffset = ByteCount(attr.endPositionBeforeTrailingTrivia)
            guard let (attributeLine, _) = file.stringView.lineAndCharacter(forByteOffset: attributeOffset) else {
                continue
            }

            let attributeShouldBeOnSameLine: Bool = {
                let attributeTokensBeforeParams = attr.withoutTrivia().tokens.split { $0.tokenKind == .leftParen }[0]
                let attributeWithoutParams = attributeTokensBeforeParams.map(\.text).joined()
                if configuration.alwaysOnNewLine.contains(attributeWithoutParams) {
                    return false
                }

                if configuration.alwaysOnSameLine.contains(attributeWithoutParams) {
                    return true
                }

                if attr.hasParameters {
                    return false
                }

                return fallbackValue
            }()

            let isLinePositionViolation: Bool
            switch attributeShouldBeOnSameLine {
            case true:
                isLinePositionViolation = attributeLine != tokenLine
            case false:
                isLinePositionViolation = attributeLine == tokenLine
            }

            if isLinePositionViolation {
                return tokenOffset
            }

            lines.append((attributeLine, attributeShouldBeOnSameLine))
        }

        // check if there're two or more attributes on the same line when one of them requires to be on its own line
        let violatesLineExclusivity = zip(lines.dropFirst(), lines).contains { lhs, rhs in
            return lhs.line == rhs.line && (!lhs.sameLine || !rhs.sameLine)
        }
        if violatesLineExclusivity {
            return tokenOffset
        }

        lines.append((tokenLine, false))

        // check if there's one of more blank lines between attributes or between attributes and the declaration
        let containsBlankLine = zip(lines.dropFirst().map(\.line), lines.map(\.line)).map(-).contains { $0 > 1 }
        if containsBlankLine {
            return tokenOffset
        }

        return nil
    }
}

private extension AttributeListSyntax.Element {
    var hasParameters: Bool {
        var kinds = tokens.map(\.tokenKind)
        kinds.removeAll(where: { $0 == .atSign })
        return kinds.count > 1
    }
}
