// swiftlint:disable file_length
import Foundation
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DocCommentParameterRule: Rule {
    var configuration = DocCommentParameterConfiguration()

    static let description = RuleDescription(
        identifier: "doc_comment_parameter",
        name: "Doc Comment Parameter",
        description:
            "Documentation comments should match the actual function signature",
        kind: .lint,
        nonTriggeringExamples: DocCommentParameterRuleExamples.nonTriggeringExamples,
        triggeringExamples: DocCommentParameterRuleExamples.triggeringExamples
    )
}

private extension DocCommentParameterRule {
    // swiftlint:disable:next type_body_length
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            let parameters = node.signature.parameterClause.parameters.compactMap {
                extractParameterName($0)
            }
            validateDocComment(
                on: node,
                declKeyword: node.funcKeyword,
                parameters: parameters,
                returnClause: node.signature.returnClause,
                throwsKeyword: node.signature.effectSpecifiers?.throwsClause?.throwsSpecifier,
                isDiscardableResult: hasDiscardableResult(in: node.attributes)
            )
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            let parameters = node.signature.parameterClause.parameters.compactMap {
                extractParameterName($0)
            }
            validateDocComment(
                on: node,
                declKeyword: node.initKeyword,
                parameters: parameters,
                throwsKeyword: node.signature.effectSpecifiers?.throwsClause?.throwsSpecifier
            )
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            let parameters = node.parameterClause.parameters.compactMap { extractParameterName($0) }
            validateDocComment(
                on: node,
                declKeyword: node.subscriptKeyword,
                parameters: parameters,
                returnClause: node.returnClause
            )
        }

        private func extractParameterName(_ param: FunctionParameterSyntax) -> String? {
            if let secondName = param.secondName {
                return secondName.text == "_" ? nil : secondName.text
            }
            let firstName = param.firstName.text
            return firstName == "_" ? nil : firstName
        }

        private func hasDiscardableResult(in attributes: AttributeListSyntax) -> Bool {
            attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "discardableResult"
            }
        }

        private func validateDocComment(
            on node: some SyntaxProtocol,
            declKeyword: TokenSyntax,
            parameters: [String],
            returnClause: ReturnClauseSyntax? = nil,
            throwsKeyword: TokenSyntax? = nil,
            isDiscardableResult: Bool = false
        ) {
            guard let docComment = extractDocComment(from: node) else {
                return
            }

            let (documentedParams, paramStyle) = parseDocumentedParameters(from: docComment, node: node)

            // Check for missing parameters (parameters in function but not in docs)
            let documentedParamNames = Set(documentedParams.map(\.name))
            let actualParamNames = Set(parameters)

            let missingParams = actualParamNames.subtracting(documentedParamNames)
            let extraParams = documentedParams.filter { !actualParamNames.contains($0.name) }

            // If there are documented parameters but some actual parameters are missing
            if documentedParamNames.isNotEmpty, missingParams.isNotEmpty {
                violations.append(
                    ReasonedRuleViolation(
                        position: declKeyword.positionAfterSkippingLeadingTrivia,
                        reason: "Missing documentation for parameter(s): "
                            + missingParams.sorted().joined(separator: ", ")
                    )
                )
            }

            // Check for extra/incorrect parameters in documentation
            for extraParam in extraParams {
                violations.append(
                    ReasonedRuleViolation(
                        position: extraParam.position,
                        reason: "Documented parameter '\(extraParam.name)' not found in declaration"
                    )
                )
            }

            if configuration.validateReturns {
                validateReturnDocumentation(
                    on: node, declKeyword: declKeyword, returnClause: returnClause,
                    docComment: docComment, isDiscardableResult: isDiscardableResult)
            }
            if configuration.validateThrows {
                validateThrowsDocumentation(
                    on: node, declKeyword: declKeyword, throwsKeyword: throwsKeyword,
                    docComment: docComment)
            }
            if configuration.enforceParameterSyntax {
                validateParameterSyntax(paramCount: parameters.count, documentedStyle: paramStyle, on: node)
            }
        }

        private func validateParameterSyntax(
            paramCount: Int,
            documentedStyle: DocParameterStyle?,
            on node: some SyntaxProtocol
        ) {
            guard let style = documentedStyle, paramCount > 0 else { return }
            switch style {
            case .plural where paramCount == 1:
                let position = findParametersBlockPosition(in: node)
                violations.append(
                    ReasonedRuleViolation(
                        position: position,
                        reason: "Use '- Parameter name:' syntax for a single parameter"
                    )
                )
            case .singular where paramCount > 1:
                let position = findSecondSingularParameterPosition(in: node)
                violations.append(
                    ReasonedRuleViolation(
                        position: position,
                        reason: "Use '- Parameters:' block syntax for multiple parameters"
                    )
                )
            default:
                break
            }
        }

        private func findParametersBlockPosition(in node: some SyntaxProtocol) -> AbsolutePosition {
            var currentPosition = node.position
            for piece in node.leadingTrivia.pieces {
                switch piece {
                case .docLineComment(let text), .docBlockComment(let text):
                    for pattern in ["- Parameters:", "- parameters:"] {
                        if let range = text.range(of: pattern) {
                            let offset = text.distance(from: text.startIndex, to: range.lowerBound)
                            return currentPosition.advanced(by: offset + 2)  // point at 'P'
                        }
                    }
                default:
                    break
                }
                currentPosition = currentPosition.advanced(by: piece.sourceLength.utf8Length)
            }
            return node.positionAfterSkippingLeadingTrivia
        }

        private func findSecondSingularParameterPosition(in node: some SyntaxProtocol)
            -> AbsolutePosition {
            var currentPosition = node.position
            var matchCount = 0
            for piece in node.leadingTrivia.pieces {
                switch piece {
                case .docLineComment(let text), .docBlockComment(let text):
                    for match in text.matches(of: #/- [Pp]arameter\s+\w/#) {
                        matchCount += 1
                        if matchCount == 2 {
                            let offset =
                                text.distance(from: text.startIndex, to: match.range.lowerBound) + 2
                            return currentPosition.advanced(by: offset)
                        }
                    }
                default:
                    break
                }
                currentPosition = currentPosition.advanced(by: piece.sourceLength.utf8Length)
            }
            return node.positionAfterSkippingLeadingTrivia
        }

        private func validateThrowsDocumentation(
            on node: some SyntaxProtocol,
            declKeyword: TokenSyntax,
            throwsKeyword: TokenSyntax?,
            docComment: String
        ) {
            let hasThrowsDoc = docHasThrowsSection(docComment)
            let isThrows = throwsKeyword?.tokenKind == .keyword(.throws)
            let isRethrows = throwsKeyword?.tokenKind == .keyword(.rethrows)

            if isThrows, !hasThrowsDoc {
                violations.append(
                    ReasonedRuleViolation(
                        position: declKeyword.positionAfterSkippingLeadingTrivia,
                        reason: "Missing '- Throws:' documentation for throwing function"
                    )
                )
            } else if !isThrows, !isRethrows, hasThrowsDoc {
                let position = findThrowsSectionPosition(in: node)
                violations.append(
                    ReasonedRuleViolation(
                        position: position,
                        reason: "Unexpected '- Throws:' documentation for non-throwing function"
                    )
                )
            }
            // rethrows: Throws doc is allowed but not required — no violation either way
        }

        private func docHasThrowsSection(_ docComment: String) -> Bool {
            docComment.contains(#/(?m)^-\s*[Tt]hrows\s*:/#)
        }

        private func findThrowsSectionPosition(in node: some SyntaxProtocol) -> AbsolutePosition {
            let trivia = node.leadingTrivia
            var currentPosition = node.position
            for piece in trivia.pieces {
                switch piece {
                case .docLineComment(let text), .docBlockComment(let text):
                    for pattern in ["- Throws:", "- throws:"] {
                        if let range = text.range(of: pattern) {
                            let offset = text.distance(from: text.startIndex, to: range.lowerBound)
                            return currentPosition.advanced(by: offset + 2)  // point at 'T'
                        }
                    }
                default:
                    break
                }
                currentPosition = currentPosition.advanced(by: piece.sourceLength.utf8Length)
            }
            return node.positionAfterSkippingLeadingTrivia
        }

        private func validateReturnDocumentation(
            on node: some SyntaxProtocol,
            declKeyword: TokenSyntax,
            returnClause: ReturnClauseSyntax?,
            docComment: String,
            isDiscardableResult: Bool = false
        ) {
            let hasReturnsDoc = docHasReturnsSection(docComment)

            // Ignore Never return type — it never actually returns
            if let returnClause,
                let identifier = returnClause.type.as(IdentifierTypeSyntax.self),
                identifier.name.text == "Never" {
                return
            }

            // Ignore Void / () return types — no doc needed
            let hasNonVoidReturn: Bool
            if let returnClause {
                let returnType = returnClause.type
                if let identifier = returnType.as(IdentifierTypeSyntax.self),
                    identifier.name.text == "Void" {
                    hasNonVoidReturn = false
                } else if returnType.is(TupleTypeSyntax.self),
                    let tuple = returnType.as(TupleTypeSyntax.self),
                    tuple.elements.isEmpty {
                    hasNonVoidReturn = false
                } else {
                    hasNonVoidReturn = true
                }
            } else {
                hasNonVoidReturn = false
            }

            if hasNonVoidReturn, !hasReturnsDoc, !isDiscardableResult {
                violations.append(
                    ReasonedRuleViolation(
                        position: declKeyword.positionAfterSkippingLeadingTrivia,
                        reason:
                            "Missing '- Returns:' documentation for function that returns a value"
                    )
                )
            } else if !hasNonVoidReturn, hasReturnsDoc {
                let position = findReturnsSectionPosition(in: node)
                violations.append(
                    ReasonedRuleViolation(
                        position: position,
                        reason:
                            "Unexpected '- Returns:' documentation for function that does not return a value"
                    )
                )
            }
        }

        private func docHasReturnsSection(_ docComment: String) -> Bool {
            docComment.contains(#/(?m)^-\s*[Rr]eturns\s*:/#)
        }

        private func findReturnsSectionPosition(in node: some SyntaxProtocol) -> AbsolutePosition {
            let trivia = node.leadingTrivia
            var currentPosition = node.position
            for piece in trivia.pieces {
                switch piece {
                case .docLineComment(let text), .docBlockComment(let text):
                    let patterns = ["- Returns:", "- returns:"]
                    for pattern in patterns {
                        if let range = text.range(of: pattern) {
                            let offset = text.distance(from: text.startIndex, to: range.lowerBound)
                            return currentPosition.advanced(by: offset + 2)  // point at 'R'
                        }
                    }
                default:
                    break
                }
                currentPosition = currentPosition.advanced(by: piece.sourceLength.utf8Length)
            }
            return node.positionAfterSkippingLeadingTrivia
        }

        private func extractDocComment(from node: some SyntaxProtocol) -> String? {
            let trivia = node.leadingTrivia
            var docLines: [String] = []

            outer: for piece in trivia.pieces.reversed() {
                switch piece {
                case .docLineComment(let text):
                    let content = text.hasPrefix("///") ? String(text.dropFirst(3)) : text
                    docLines.insert(content.trimmingCharacters(in: .whitespaces), at: 0)
                case .docBlockComment(let text):
                    let content = parseBlockComment(text)
                    docLines.insert(contentsOf: content, at: 0)
                case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs:
                    continue
                default:
                    if docLines.isNotEmpty {
                        break outer
                    }
                }
            }

            return docLines.isEmpty ? nil : docLines.joined(separator: "\n")
        }

        private func parseBlockComment(_ text: String) -> [String] {
            text
                .replacingOccurrences(of: "/**", with: "")
                .replacingOccurrences(of: "*/", with: "")
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { line -> String in
                    var trimmed = line.trimmingCharacters(in: .whitespaces)
                    // Remove leading asterisks common in block comments
                    if trimmed.hasPrefix("*") {
                        trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                    }
                    return trimmed
                }
        }

        private func parseDocumentedParameters(
            from docComment: String,
            node: some SyntaxProtocol
        ) -> (params: [DocumentedParameter], style: DocParameterStyle?) {
            var parameters: [DocumentedParameter] = []
            let lines = docComment.split(separator: "\n", omittingEmptySubsequences: false)

            var inParametersBlock = false
            var foundPluralBlock = false
            var foundSingular = false

            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                // Check for "- Parameters:" block
                if trimmedLine.lowercased().hasPrefix("- parameters:") {
                    inParametersBlock = true
                    foundPluralBlock = true
                    continue
                }

                // Check for "- Parameter name:" syntax
                if let paramName = extractSingleParameter(from: trimmedLine) {
                    let position = findParameterPosition(paramName: paramName, in: node)
                    parameters.append(DocumentedParameter(name: paramName, position: position))
                    inParametersBlock = false
                    foundSingular = true
                    continue
                }

                // Check for parameters within a Parameters block (- name: description)
                if inParametersBlock {
                    if let paramName = extractParameterFromBlock(from: trimmedLine) {
                        let position = findParameterPosition(paramName: paramName, in: node)
                        parameters.append(DocumentedParameter(name: paramName, position: position))
                    } else if trimmedLine.hasPrefix("- ") {
                        // This is a different list item, exit parameters block
                        inParametersBlock = false
                    }
                }
            }

            let style: DocParameterStyle?
            if foundPluralBlock {
                style = .plural
            } else if foundSingular {
                style = .singular
            } else {
                style = nil
            }
            return (params: parameters, style: style)
        }

        /// Extracts parameter name from "- Parameter name:" syntax
        private func extractSingleParameter(from line: String) -> String? {
            guard let match = line.firstMatch(of: #/^-\s*[Pp]arameter\s+(\w+)\s*:/#) else {
                return nil
            }
            return String(match.output.1)
        }

        /// Extracts parameter name from "- name: description" syntax within Parameters block
        private func extractParameterFromBlock(from line: String) -> String? {
            guard let match = line.firstMatch(of: #/^-\s*(\w+)\s*:/#) else { return nil }
            let name = String(match.output.1)
            let excluded = [
                "returns", "throws", "note", "warning", "important", "see",
                "precondition", "postcondition", "requires", "invariant",
                "complexity", "author", "version",
            ]
            return excluded.contains(name.lowercased()) ? nil : name
        }

        /// Finds the position of a documented parameter in the source
        private func findParameterPosition(paramName: String, in node: some SyntaxProtocol)
            -> AbsolutePosition {
            // Search through the trivia to find the exact position of the parameter name
            let trivia = node.leadingTrivia
            var currentPosition = node.position

            for piece in trivia.pieces {
                switch piece {
                case .docLineComment(let text), .docBlockComment(let text):
                    if let range = text.range(of: "- Parameter \(paramName):") ?? text.range(
                        of: "- parameter \(paramName):") ?? text.range(of: "- \(paramName):") {
                        let offset = text.distance(from: text.startIndex, to: range.lowerBound)
                        // Find the parameter name within the match
                        let matchText = String(text[range])
                        if let paramRange = matchText.range(of: paramName) {
                            let paramOffset = matchText.distance(
                                from: matchText.startIndex, to: paramRange.lowerBound)
                            return currentPosition.advanced(by: offset + paramOffset)
                        }
                    }
                default:
                    break
                }
                currentPosition = currentPosition.advanced(by: piece.sourceLength.utf8Length)
            }

            // Fallback to the node position if we can't find the exact location
            return node.positionAfterSkippingLeadingTrivia
        }
    }
}

private struct DocumentedParameter {
    let name: String
    let position: AbsolutePosition
}

private enum DocParameterStyle {
    case singular
    case plural
}
