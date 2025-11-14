import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct LineLengthRule: Rule {
    var configuration = LineLengthConfiguration()

    static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Lines should not span too many characters.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example(String(repeating: "/", count: 120) + ""),
            Example(String(repeating: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)", count: 120) + ""),
            Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 120) + ""),
        ],
        triggeringExamples: [
            Example(String(repeating: "/", count: 121) + ""),
            Example(String(repeating: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)", count: 121) + ""),
            Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 121) + ""),
        ].skipWrappingInCommentTests().skipWrappingInStringTests()
    )
}

private extension LineLengthRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        // To store line numbers that should be ignored based on configuration
        private var functionDeclarationLines = Set<Int>()
        private var commentOnlyLines = Set<Int>()
        private var interpolatedStringLines = Set<Int>()
        private var multilineStringLines = Set<Int>()
        private var regexLiteralLines = Set<Int>()

        override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
            // Populate functionDeclarationLines if ignores_function_declarations is true
            if configuration.ignoresFunctionDeclarations {
                let funcVisitor = FunctionLineVisitor(locationConverter: locationConverter)
                functionDeclarationLines = funcVisitor.walk(tree: node, handler: \.lines)
            }

            // Populate multilineStringLines if ignores_multiline_strings is true
            if configuration.ignoresMultilineStrings {
                let stringVisitor = MultilineStringLiteralVisitor(locationConverter: locationConverter)
                multilineStringLines = stringVisitor.walk(tree: node, handler: \.linesSpanned)
            }

            // Populate interpolatedStringLines if ignores_interpolated_strings is true
            if configuration.ignoresInterpolatedStrings {
                let interpVisitor = InterpolatedStringLineVisitor(locationConverter: locationConverter)
                interpolatedStringLines = interpVisitor.walk(tree: node, handler: \.lines)
            }

            // Populate commentOnlyLines if ignores_comments is true
            if configuration.ignoresComments {
                let commentVisitor = CommentLinesVisitor(locationConverter: locationConverter)
                commentOnlyLines = commentVisitor.walk(tree: node, handler: \.commentOnlyLines)
            }

            // Populate regexLiteralLines if ignores_regex_literals is true
            if configuration.ignoresRegexLiterals {
                let regexVisitor = RegexLiteralVisitor(locationConverter: locationConverter)
                regexLiteralLines = regexVisitor.walk(tree: node, handler: \.lines)
            }

            return .skipChildren // We'll do the main processing in visitPost
        }

        override func visitPost(_: SourceFileSyntax) {
            let minLengthThreshold = configuration.params.map(\.value).min() ?? .max

            for line in file.lines {
                // Quick check to skip very short lines before expensive stripping
                // `line.content.count` <= `line.range.length` is true.
                // So, check `line.range.length` is larger than minimum parameter value
                // for avoiding using heavy `line.content.count`.
                if line.range.length < minLengthThreshold {
                    continue
                }

                // Apply ignore configurations
                if configuration.ignoresFunctionDeclarations, functionDeclarationLines.contains(line.index) {
                    continue
                }
                if configuration.ignoresComments, commentOnlyLines.contains(line.index) {
                    continue
                }
                if configuration.ignoresInterpolatedStrings, interpolatedStringLines.contains(line.index) {
                    continue
                }
                if configuration.ignoresMultilineStrings, multilineStringLines.contains(line.index) {
                    continue
                }
                if configuration.ignoresRegexLiterals, regexLiteralLines.contains(line.index) {
                    continue
                }
                if configuration.excludedLinesPatterns.contains(where: {
                    regex($0).firstMatch(in: line.content, range: line.content.fullNSRange) != nil
                }) {
                    continue
                }

                // String stripping logic
                var strippedString = line.content
                if configuration.ignoresURLs {
                    strippedString = strippedString.strippingURLs
                }
                strippedString = stripLiterals(fromSourceString: strippedString, withDelimiter: "#colorLiteral")
                strippedString = stripLiterals(fromSourceString: strippedString, withDelimiter: "#imageLiteral")

                let length = strippedString.count // Character count for reporting

                // Check against configured length limits
                for param in configuration.params where length > param.value {
                    let reason = "Line should be \(param.value) characters or less; " +
                        "currently it has \(length) characters"
                    // Position the violation at the start of the line, consistent with original behavior
                    violations.append(ReasonedRuleViolation(
                        position: locationConverter.position(ofLine: line.index, column: 1), // Start of the line
                        reason: reason,
                        severity: param.severity
                    ))
                    break // Only report one violation (the most severe one reached) per line
                }
            }
        }

        // Strip color and image literals from the source string
        private func stripLiterals(fromSourceString sourceString: String,
                                   withDelimiter delimiter: String) -> String {
            var modifiedString = sourceString
            while modifiedString.contains("\(delimiter)(") {
                if let rangeStart = modifiedString.range(of: "\(delimiter)("),
                   let rangeEnd = modifiedString.range(of: ")", options: .literal,
                                                       range: rangeStart.lowerBound..<modifiedString.endIndex) {
                    modifiedString.replaceSubrange(rangeStart.lowerBound..<rangeEnd.upperBound, with: "#")
                } else {
                    break
                }
            }
            return modifiedString
        }
    }
}

// MARK: - Helper Visitors for Pre-computation

// Visitor to find lines spanned by function declarations
private final class FunctionLineVisitor: SyntaxVisitor {
    let locationConverter: SourceLocationConverter
    var lines = Set<Int>()

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        collectLines(from: node)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
        collectLines(from: node)
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
        collectLines(from: node)
    }

    private func collectLines(from node: any SyntaxProtocol) {
        let startLocation = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        let endLocation = locationConverter.location(for: node.endPositionBeforeTrailingTrivia)
        for line in startLocation.line...endLocation.line {
            lines.insert(line)
        }
    }
}

// Visitor to find lines with interpolated strings
private final class InterpolatedStringLineVisitor: SyntaxVisitor {
    let locationConverter: SourceLocationConverter
    var lines = Set<Int>()

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: ExpressionSegmentSyntax) {
        // ExpressionSegmentSyntax is the interpolation inside a string
        let startLocation = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        let endLocation = locationConverter.location(for: node.endPositionBeforeTrailingTrivia)
        for line in startLocation.line...endLocation.line {
            lines.insert(line)
        }
    }
}

// Visitor to find lines with regex literals
private final class RegexLiteralVisitor: SyntaxVisitor {
    let locationConverter: SourceLocationConverter
    var lines = Set<Int>()

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: RegexLiteralExprSyntax) {
        let startLocation = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        let endLocation = locationConverter.location(for: node.endPositionBeforeTrailingTrivia)
        for line in startLocation.line...endLocation.line {
            lines.insert(line)
        }
    }
}

private extension String {
    var strippingURLs: String {
        let range = fullNSRange
        // Workaround for Linux until NSDataDetector is available
        #if os(Linux) || os(Windows)
            // Regex pattern from http://daringfireball.net/2010/07/improved_regex_for_matching_urls
            let pattern = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)" +
                "(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*" +
                "\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
            let urlRegex = regex(pattern)
            return urlRegex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        #else
            let types = NSTextCheckingResult.CheckingType.link.rawValue
            guard let urlDetector = try? NSDataDetector(types: types) else {
                return self
            }
            return urlDetector.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        #endif
    }
}
