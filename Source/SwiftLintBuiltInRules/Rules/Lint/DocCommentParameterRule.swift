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
            "Parameters in documentation comments should match the actual function parameters",
        kind: .lint,
        nonTriggeringExamples: DocCommentParameterRuleExamples.nonTriggeringExamples,
        triggeringExamples: DocCommentParameterRuleExamples.triggeringExamples
    )
}

extension DocCommentParameterRule {
    fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        // swiftlint:disable force_try
        private static let singleParamRegex = try! NSRegularExpression(
            pattern: #"^-\s*[Pp]arameter\s+(\w+)\s*:"#)
        private static let blockParamRegex = try! NSRegularExpression(
            pattern: #"^-\s*(\w+)\s*:"#)
        private static let throwsDocRegex = try! NSRegularExpression(
            pattern: #"^-\s*[Tt]hrows\s*:"#, options: .anchorsMatchLines)
        private static let returnsDocRegex = try! NSRegularExpression(
            pattern: #"^-\s*[Rr]eturns\s*:"#, options: .anchorsMatchLines)
        private static let singularParamLineRegex = try! NSRegularExpression(
            pattern: #"- [Pp]arameter\s+\w"#)
        // swiftlint:enable force_try

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

        /// Extracts the parameter name for documentation purposes.
        /// Uses the external name (firstName) if it's not an underscore, otherwise uses the internal name.
        /// Returns nil for truly unnamed parameters (both names are `_`) which have no documentable name.
        private func extractParameterName(_ param: FunctionParameterSyntax) -> String? {
            let firstName = param.firstName.text
            if firstName == "_" {
                if let secondName = param.secondName, secondName.text != "_" {
                    return secondName.text
                }
                return nil  // truly unnamed — no documentable name
            }
            return firstName
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
            -> AbsolutePosition
        {
            var currentPosition = node.position
            var matchCount = 0
            let regex = Self.singularParamLineRegex
            for piece in node.leadingTrivia.pieces {
                switch piece {
                case .docLineComment(let text), .docBlockComment(let text):
                    let matches = regex.matches(
                        in: text, range: NSRange(text.startIndex..., in: text))
                    for match in matches {
                        matchCount += 1
                        if matchCount == 2, let range = Range(match.range, in: text) {
                            let offset =
                                text.distance(from: text.startIndex, to: range.lowerBound) + 2  // skip "- "
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
            Self.throwsDocRegex.firstMatch(
                in: docComment, range: NSRange(docComment.startIndex..., in: docComment)) != nil
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
                identifier.name.text == "Never"
            {
                return
            }

            // Ignore Void / () return types — no doc needed
            let hasNonVoidReturn: Bool
            if let returnClause {
                let returnType = returnClause.type
                if let identifier = returnType.as(IdentifierTypeSyntax.self),
                    identifier.name.text == "Void"
                {
                    hasNonVoidReturn = false
                } else if returnType.is(TupleTypeSyntax.self),
                    let tuple = returnType.as(TupleTypeSyntax.self),
                    tuple.elements.isEmpty
                {
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
            Self.returnsDocRegex.firstMatch(
                in: docComment, range: NSRange(docComment.startIndex..., in: docComment)) != nil
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
            guard let match = Self.singleParamRegex.firstMatch(
                    in: line, range: NSRange(line.startIndex..., in: line)),
                  let range = Range(match.range(at: 1), in: line)
            else { return nil }
            return String(line[range])
        }

        /// Extracts parameter name from "- name: description" syntax within Parameters block
        private func extractParameterFromBlock(from line: String) -> String? {
            guard let match = Self.blockParamRegex.firstMatch(
                    in: line, range: NSRange(line.startIndex..., in: line)),
                  let range = Range(match.range(at: 1), in: line)
            else { return nil }
            let name = String(line[range])
            let excluded = [
                "returns", "throws", "note", "warning", "important", "see",
                "precondition", "postcondition", "requires", "invariant",
                "complexity", "author", "version",
            ]
            return excluded.contains(name.lowercased()) ? nil : name
        }

        /// Finds the position of a documented parameter in the source
        private func findParameterPosition(paramName: String, in node: some SyntaxProtocol)
            -> AbsolutePosition
        {
            // Search through the trivia to find the exact position of the parameter name
            let trivia = node.leadingTrivia
            var currentPosition = node.position

            for piece in trivia.pieces {
                switch piece {
                case .docLineComment(let text), .docBlockComment(let text):
                    if let range = text.range(of: "- Parameter \(paramName):") ?? text.range(
                        of: "- parameter \(paramName):") ?? text.range(of: "- \(paramName):")
                    {
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
