import Down
import SourceKittenFramework

public struct StructuredFunctionDocRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = StructuredFunctionDocConfiguration()

    public init() {}

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
            return violation(in: file, offset: docOffset)
        }

        guard isValidSummary(document: document) else {
            return violation(in: file, offset: docOffset)
        }

        guard let parametersList = findParametersList(topMarkupElements: Array(document.children)) else {
            return violation(in: file, offset: docOffset)
        }

        let parameterFirstLines = parametersList.children
            .compactMap { $0.children.first?.cmarkNode.wrap() as? Paragraph }
            .compactMap { $0.textLines.first }
        let expectedPrefixes = parameterNames.map { $0 + ":" }

        guard expectedPrefixes.count == parameterFirstLines.count else {
            return violation(in: file, offset: docOffset)
        }

        for index in 0..<parameterFirstLines.count {
            guard
                let docText = parameterFirstLines[index].literal,
                docText.starts(with: expectedPrefixes[index])
            else {
                return violation(in: file, offset: docOffset)
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
    private func isValidSummary(document: Document) -> Bool {
        guard let summaryParagraph = document.children.first?.cmarkNode.wrap() as? Paragraph else {
            return false
        }

        if configuration.maxSummaryLineCount > 0 &&
            summaryParagraph.textLines.count > configuration.maxSummaryLineCount {
            return false
        }

        return true
    }

    // Parameters list is an unordered list with "Parameters:" paragraph and an ordered list
    // of the actual parameters.
    private func findParametersList(topMarkupElements: [Node]) -> List? {
        guard
            let firstList = topMarkupElements.compactMap({ $0.cmarkNode.wrap() as? List }).first,
            case .bullet = firstList.listType
        else {
            return nil
        }

        guard
            let listItem = firstList.children.first,
            let headerParagraph = listItem.children.first as? Paragraph,
            let headerText = headerParagraph.textLines.first,
            headerText.literal == "Parameters:",
            listItem.children.count > 1,
            let parametersList = listItem.children[1].cmarkNode.wrap() as? List
        else {
            return nil
        }

        return parametersList
    }

    private func violation(in file: SwiftLintFile, offset: ByteCount) -> [StyleViolation] {
        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}

 private extension Paragraph {
    var textLines: [MarkdownText] {
        children.compactMap { $0 as? MarkdownText }
    }
 }
