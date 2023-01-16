import Foundation
import SourceKittenFramework

struct LineLengthRule: ConfigurationProviderRule {
    var configuration = LineLengthConfiguration(warning: 120, error: 200)

    init() {}

    private let commentKinds = SyntaxKind.commentKinds
    private let nonCommentKinds = SyntaxKind.allKinds.subtracting(SyntaxKind.commentKinds)
    private let functionKinds = SwiftDeclarationKind.functionKinds

    static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Lines should not span too many characters.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example(String(repeating: "/", count: 120) + "\n"),
            Example(String(repeating: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)", count: 120) + "\n"),
            Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 120) + "\n")
        ],
        triggeringExamples: [
            Example(String(repeating: "/", count: 121) + "\n"),
            Example(String(repeating: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)", count: 121) + "\n"),
            Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 121) + "\n")
        ].skipWrappingInCommentTests().skipWrappingInStringTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let minValue = configuration.params.map({ $0.value }).min() ?? .max
        let swiftDeclarationKindsByLine = Lazy(file.swiftDeclarationKindsByLine() ?? [])
        let syntaxKindsByLine = Lazy(file.syntaxKindsByLine() ?? [])

        return file.lines.compactMap { line in
            // `line.content.count` <= `line.range.length` is true.
            // So, `check line.range.length` is larger than minimum parameter value.
            // for avoiding using heavy `line.content.count`.
            if line.range.length < minValue {
                return nil
            }

            if configuration.ignoresFunctionDeclarations &&
                lineHasKinds(line: line,
                             kinds: functionKinds,
                             kindsByLine: swiftDeclarationKindsByLine.value) {
                return nil
            }

            if configuration.ignoresComments &&
                lineHasKinds(line: line,
                             kinds: commentKinds,
                             kindsByLine: syntaxKindsByLine.value) &&
                !lineHasKinds(line: line,
                              kinds: nonCommentKinds,
                              kindsByLine: syntaxKindsByLine.value) {
                return nil
            }

            if configuration.ignoresInterpolatedStrings &&
                lineHasKinds(line: line,
                             kinds: [.stringInterpolationAnchor],
                             kindsByLine: syntaxKindsByLine.value) {
                return nil
            }

            var strippedString = line.content
            if configuration.ignoresURLs {
                strippedString = strippedString.strippingURLs
            }
            strippedString = stripLiterals(fromSourceString: strippedString,
                                           withDelimiter: "#colorLiteral")
            strippedString = stripLiterals(fromSourceString: strippedString,
                                           withDelimiter: "#imageLiteral")

            let length = strippedString.count

            for param in configuration.params where length > param.value {
                let reason = "Line should be \(param.value) characters or less; currently it has \(length) characters"
                return StyleViolation(ruleDescription: Self.description,
                                      severity: param.severity,
                                      location: Location(file: file.path, line: line.index),
                                      reason: reason)
            }
            return nil
        }
    }

    /// Takes a string and replaces any literals specified by the `delimiter` parameter with `#`
    ///
    /// - parameter sourceString: Original string, possibly containing literals
    /// - parameter delimiter:    Delimiter of the literal
    ///                           (characters before the parentheses, e.g. `#colorLiteral`)
    ///
    /// - returns: sourceString with the given literals replaced by `#`
    private func stripLiterals(fromSourceString sourceString: String,
                               withDelimiter delimiter: String) -> String {
        var modifiedString = sourceString

        // While copy of content contains literal, replace with a single character
        while modifiedString.contains("\(delimiter)(") {
            if let rangeStart = modifiedString.range(of: "\(delimiter)("),
                let rangeEnd = modifiedString.range(of: ")",
                                                    options: .literal,
                                                    range:
                    rangeStart.lowerBound..<modifiedString.endIndex) {
                modifiedString.replaceSubrange(rangeStart.lowerBound..<rangeEnd.upperBound,
                                               with: "#")
            } else { // Should never be the case, but break to avoid accidental infinity loop
                break
            }
        }

        return modifiedString
    }

    private func lineHasKinds<Kind>(line: Line, kinds: Set<Kind>, kindsByLine: [[Kind]]) -> Bool {
        let index = line.index
        if index >= kindsByLine.count {
            return false
        }
        return !kinds.isDisjoint(with: kindsByLine[index])
    }
}

// extracted from https://forums.swift.org/t/pitch-declaring-local-variables-as-lazy/9287/3
private class Lazy<Result> {
    private var computation: () -> Result
    fileprivate private(set) lazy var value: Result = computation()

    init(_ computation: @escaping @autoclosure () -> Result) {
        self.computation = computation
    }
}

private extension String {
    var strippingURLs: String {
        let range = fullNSRange
        // Workaround for Linux until NSDataDetector is available
        #if os(Linux)
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
