import Down
import SourceKittenFramework

public struct StructuredFunctionDocRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = StructuredFunctionDocConfiguration()

    public init() {}

    private static let parameterKeyword = "parameter"

    public static let description = RuleDescription(
        identifier: "structured_function_doc",
        name: "Structured Function Doc",
        description:
            "Function documentation should have a short summary followed by parameters section.",
        kind: .lint,
        nonTriggeringExamples: StructuredFunctionDocRuleExamples.nonTriggeringExamples,
        triggeringExamples: StructuredFunctionDocRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            SwiftDeclarationKind.functionKinds.contains(kind),
            let docOffset = dictionary.docOffset,
            let docLength = dictionary.docLength
        else {
            return []
        }

        let parameterNames = dictionary.substructure.compactMap { subStructure -> String? in
            guard subStructure.declarationKind == .varParameter, let name = subStructure.name else {
                return nil
            }
            return name
        }

        guard parameterNames.count >= configuration.minimalNumberOfParameters else {
            return []
        }

        let docByteRange = ByteRange(location: docOffset, length: docLength)
        guard let docLineRange = file.stringView.lineRangeWithByteRange(docByteRange) else {
            return []
        }
        let docLines = Array(file.stringView.lines[docLineRange.start - 1 ..< docLineRange.end - 1])

        guard let document = parseMarkdown(lines: docLines) else {
            return violation(in: file, offset: docOffset, reason: "documentation isn't a proper markdown")
        }

        if let invalidReason = validateSummary(document: document) {
            return violation(in: file, offset: docOffset, reason: invalidReason)
        }

        guard let markdownParameters = parseMarkdownParameters(topMarkupElements: Array(document.children)) else {
            return violation(in: file, offset: docOffset, reason: "Parameters section or separate parameter fields " +
                "must be in the first markdown list")
        }

        guard parameterNames.count == markdownParameters.count else {
            return violation(in: file, offset: docOffset,
                             reason: "Documented parameters must match function definition.")
        }

        for index in 0..<markdownParameters.count {
            guard
                markdownParameters[index].starts(with: parameterNames[index] + ":")
            else {
                let unexpectedParameter = markdownParameters[index].prefix(while: { $0 != ":" })
                return violation(in: file, offset: docOffset, reason: "Expected documentation for " +
                    "'\(parameterNames[index])', but found '\(unexpectedParameter)'")
            }
        }

        return []
    }

    private func parseMarkdown(lines: [Line]) -> Document? {
        let markdownString = lines.map {
            $0.content.removingCommonLeadingWhitespaceFromLines().dropFirst(3)
        }.joined(separator: "\n")

        let document: CMarkNode
        do {
            document = try Down(markdownString: markdownString).toAST()
        } catch {
            return nil
        }

        return document.wrap() as? Document
    }

    // The first element must be paragraph. Its content is the summary.
    private func validateSummary(document: Document) -> String? {
        guard let summaryParagraph = document.children.first?.cmarkNode.wrap() as? Paragraph else {
            return "Documentation must begin with summary paragraph"
        }

        if configuration.maxSummaryLineCount > 0 &&
            summaryParagraph.textLines.count > configuration.maxSummaryLineCount {
            return "Summary must not exceed \(configuration.maxSummaryLineCount) lines"
        }

        return nil
    }

    private func parseMarkdownParameters(topMarkupElements: [Node]) -> [String]? {
        guard
            let firstList = topMarkupElements.compactMap({ $0.cmarkNode.wrap() as? List }).first,
            case .bullet = firstList.listType
        else {
            return nil
        }

        if let parameters = parseSectionParameters(list: firstList) {
          return parameters
        }

        return parseSeparateParameters(list: firstList)
    }

    // Section parameters is a list with "Parameters:" paragraph followed by list of actual parameters.
    // Example:
    // - Parameters:
    //   - list:
    private func parseSectionParameters(list: List) -> [String]? {
        guard
            let firstItem = list.children.first,
            let headerParagraph = firstItem.children.first as? Paragraph,
            let headerText = headerParagraph.textLines.first?.literal,
            headerText.caseInsensitiveCompare("Parameters:") == .orderedSame,
            firstItem.children.count > 1,
            let parametersList = firstItem.children[1].cmarkNode.wrap() as? List
        else {
            return nil
        }

        return parametersList.children
            .compactMap { $0.children.first?.cmarkNode.wrap() as? Paragraph }
            .compactMap { $0.textLines.first?.literal }
    }

    // Parse separate parameters fields. Example:
    // - Parameter a:
    // - Parameter b:
    private func parseSeparateParameters(list: List) -> [String]? {
        return list.children
            .compactMap { $0.children.first?.cmarkNode.wrap() as? Paragraph }
            .compactMap { $0.textLines.first?.literal }
            .filter { $0.startsCaseInsensitive(with: Self.parameterKeyword) }
            .map { $0.dropFirst(Self.parameterKeyword.count) }
            .filter { $0.first?.isWhitespace ?? false }
            .map { String($0).removingCommonLeadingWhitespaceFromLines() }
    }

    private func violation(in file: SwiftLintFile, offset: ByteCount, reason: String? = nil) -> [StyleViolation] {
        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: offset),
                           reason: reason)
        ]
    }
}

private extension Paragraph {
    var textLines: [MarkdownText] {
        children.compactMap { $0 as? MarkdownText }
    }
}

private extension String {
    func startsCaseInsensitive(with possiblePrefix: String) -> Bool {
        prefix(possiblePrefix.count).caseInsensitiveCompare(possiblePrefix) == .orderedSame
    }
}
