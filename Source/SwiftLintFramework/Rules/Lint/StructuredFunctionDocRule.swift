import Foundation
import Markdown
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

        let lineContents = docLines.map {
            $0.content.removingCommonLeadingWhitespaceFromLines().dropFirst(3)
        }.joined(separator: "\n")

        let document = Document(parsing: lineContents)
        guard isValidSummary(document: document) else {
            return violation(in: file, offset: docOffset)
        }

        guard let parametersList = findParametersList(topMarkupElements: Array(document.children)) else {
            return violation(in: file, offset: docOffset)
        }

        let parameterFirstLines = Array(parametersList.children)
            .compactMap { $0.child(at: 0) as? Markdown.Paragraph }
            .compactMap { $0.textLines.first }
        let expectedPrefixes = parameterNames.map { $0 + ":" }

        let minCount = min(expectedPrefixes.count, parameterFirstLines.count)
        for index in 0..<minCount {
            let docText = parameterFirstLines[index]
            guard docText.string.starts(with: expectedPrefixes[index]) else {
                return violation(in: file, offset: computeOffset(of: docText, in: docLines))
            }
        }

        if parameterFirstLines.count > minCount {
            return violation(in: file, offset: computeOffset(of: parameterFirstLines[minCount], in: docLines))
        }

        if expectedPrefixes.count > minCount {
            return violation(in: file, offset: docByteRange.upperBound - 1)
        }

        return []
    }

    // The first element must be paragraph. It's content is summary.
    private func isValidSummary(document: Markup) -> Bool {
        guard let summaryParagraph = Array(document.children).first as? Markdown.Paragraph else {
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
    private func findParametersList(topMarkupElements: [Markup]) -> UnorderedList? {
        guard let firstList = topMarkupElements.compactMap({ $0 as? UnorderedList }).first else {
            return nil
        }

        guard
            let listItem = firstList.child(at: 0),
            let headerParagraph = listItem.child(at: 0) as? Paragraph,
            let headerText = headerParagraph.textLines.first,
            headerText.string == "Parameters:",
            let parametersList = listItem.child(at: 1) as? UnorderedList
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

    private func computeOffset(of markup: Markup, in docLines: [Line]) -> ByteCount {
        let lineIndex = markup.range?.lowerBound.line ?? 1
        return docLines[lineIndex - 1].byteRange.location
    }
}

private extension Paragraph {
    var textLines: [Markdown.Text] {
        children.compactMap { $0 as? Markdown.Text }
    }
}
