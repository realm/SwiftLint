import Foundation
import SourceKittenFramework

struct MarkRule: CorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "mark",
        name: "Mark",
        description: "MARK comment should be in valid format. e.g. '// MARK: ...' or '// MARK: - ...'",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// MARK: good\n"),
            Example("// MARK: - good\n"),
            Example("// MARK: -\n"),
            Example("// BOOKMARK"),
            Example("//BOOKMARK"),
            Example("// BOOKMARKS"),
            issue1749Example
        ],
        triggeringExamples: [
            Example("↓//MARK: bad"),
            Example("↓// MARK:bad"),
            Example("↓//MARK:bad"),
            Example("↓//  MARK: bad"),
            Example("↓// MARK:  bad"),
            Example("↓// MARK: -bad"),
            Example("↓// MARK:- bad"),
            Example("↓// MARK:-bad"),
            Example("↓//MARK: - bad"),
            Example("↓//MARK:- bad"),
            Example("↓//MARK: -bad"),
            Example("↓//MARK:-bad"),
            Example("↓//Mark: bad"),
            Example("↓// Mark: bad"),
            Example("↓// MARK bad"),
            Example("↓//MARK bad"),
            Example("↓// MARK - bad"),
            Example("↓//MARK : bad"),
            Example("↓// MARKL:"),
            Example("↓// MARKR "),
            Example("↓// MARKK -"),
            Example("↓/// MARK:"),
            Example("↓/// MARK bad"),
            issue1029Example
        ],
        corrections: [
            Example("↓//MARK: comment"): Example("// MARK: comment"),
            Example("↓// MARK:  comment"): Example("// MARK: comment"),
            Example("↓// MARK:comment"): Example("// MARK: comment"),
            Example("↓//  MARK: comment"): Example("// MARK: comment"),
            Example("↓//MARK: - comment"): Example("// MARK: - comment"),
            Example("↓// MARK:- comment"): Example("// MARK: - comment"),
            Example("↓// MARK: -comment"): Example("// MARK: - comment"),
            Example("↓// MARK: -  comment"): Example("// MARK: - comment"),
            Example("↓// Mark: comment"): Example("// MARK: comment"),
            Example("↓// Mark: - comment"): Example("// MARK: - comment"),
            Example("↓// MARK - comment"): Example("// MARK: - comment"),
            Example("↓// MARK : comment"): Example("// MARK: comment"),
            Example("↓// MARKL:"): Example("// MARK:"),
            Example("↓// MARKL: -"): Example("// MARK: -"),
            Example("↓// MARKK "): Example("// MARK: "),
            Example("↓// MARKK -"): Example("// MARK: -"),
            Example("↓/// MARK:"): Example("// MARK:"),
            Example("↓/// MARK comment"): Example("// MARK: comment"),
            issue1029Example: issue1029Correction,
            issue1749Example: issue1749Correction
        ]
    )

    private let spaceStartPattern = "(?:\(nonSpaceOrTwoOrMoreSpace)\(mark))"

    private let endNonSpacePattern = "(?:\(mark)\(nonSpace))"
    private let endTwoOrMoreSpacePattern = "(?:\(mark)\(twoOrMoreSpace))"

    private let invalidEndSpacesPattern = "(?:\(mark)\(nonSpaceOrTwoOrMoreSpace))"

    private let twoOrMoreSpacesAfterHyphenPattern = "(?:\(mark) -\(twoOrMoreSpace))"
    private let nonSpaceOrNewlineAfterHyphenPattern = "(?:\(mark) -[^ \n])"

    private let invalidSpacesAfterHyphenPattern = "(?:\(mark) -\(nonSpaceOrTwoOrMoreSpaceOrNewline))"

    private let invalidLowercasePattern = "(?:// ?[Mm]ark:)"

    private let missingColonPattern = "(?:// ?MARK[^:])"
    // The below patterns more specifically describe some of the above pattern's failure cases for correction.
    private let oneOrMoreSpacesBeforeColonPattern = "(?:// ?MARK +:)"
    private let nonWhitespaceBeforeColonPattern = "(?:// ?MARK\\S+:)"
    private let nonWhitespaceNorColonBeforeSpacesPattern = "(?:// ?MARK[^\\s:]* +)"
    private let threeSlashesInsteadOfTwo = "/// MARK:?"

    private var pattern: String {
        return [
            spaceStartPattern,
            invalidEndSpacesPattern,
            invalidSpacesAfterHyphenPattern,
            invalidLowercasePattern,
            missingColonPattern,
            threeSlashesInsteadOfTwo
        ].joined(separator: "|")
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file, matching: pattern).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        var result = [Correction]()

        result.append(contentsOf: correct(file: file,
                                          pattern: spaceStartPattern,
                                          replaceString: "// MARK:"))

        result.append(contentsOf: correct(file: file,
                                          pattern: endNonSpacePattern,
                                          replaceString: "// MARK: ",
                                          keepLastChar: true))

        result.append(contentsOf: correct(file: file,
                                          pattern: endTwoOrMoreSpacePattern,
                                          replaceString: "// MARK: "))

        result.append(contentsOf: correct(file: file,
                                          pattern: twoOrMoreSpacesAfterHyphenPattern,
                                          replaceString: "// MARK: - "))

        result.append(contentsOf: correct(file: file,
                                          pattern: nonSpaceOrNewlineAfterHyphenPattern,
                                          replaceString: "// MARK: - ",
                                          keepLastChar: true))

        result.append(contentsOf: correct(file: file,
                                          pattern: oneOrMoreSpacesBeforeColonPattern,
                                          replaceString: "// MARK:",
                                          keepLastChar: false))

        result.append(contentsOf: correct(file: file,
                                          pattern: nonWhitespaceBeforeColonPattern,
                                          replaceString: "// MARK:",
                                          keepLastChar: false))

        result.append(contentsOf: correct(file: file,
                                          pattern: nonWhitespaceNorColonBeforeSpacesPattern,
                                          replaceString: "// MARK: ",
                                          keepLastChar: false))

        result.append(contentsOf: correct(file: file,
                                          pattern: invalidLowercasePattern,
                                          replaceString: "// MARK:"))

        result.append(contentsOf: correct(file: file,
                                          pattern: threeSlashesInsteadOfTwo,
                                          replaceString: "// MARK:"))

        return result.unique
    }

    private func correct(file: SwiftLintFile,
                         pattern: String,
                         replaceString: String,
                         keepLastChar: Bool = false) -> [Correction] {
        let violations = violationRanges(in: file, matching: pattern)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        var nsstring = file.contents.bridge()
        let description = Self.description
        var corrections = [Correction]()
        for var range in matches.reversed() {
            if keepLastChar {
                range.length -= 1
            }
            let location = Location(file: file, characterOffset: range.location)
            nsstring = nsstring.replacingCharacters(in: range, with: replaceString).bridge()
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(nsstring.bridge())
        return corrections
    }

    private func violationRanges(in file: SwiftLintFile, matching pattern: String) -> [NSRange] {
        return file.rangesAndTokens(matching: pattern).filter { matchRange, syntaxTokens in
            guard
                let syntaxToken = syntaxTokens.first,
                let syntaxKind = syntaxToken.kind,
                SyntaxKind.commentKinds.contains(syntaxKind),
                case let tokenLocation = Location(file: file, byteOffset: syntaxToken.offset),
                case let matchLocation = Location(file: file, characterOffset: matchRange.location),
                // Skip MARKs that are part of a multiline comment
                tokenLocation.line == matchLocation.line
            else {
                return false
            }
            return true
        }.compactMap { range, syntaxTokens in
            let byteRange = ByteRange(location: syntaxTokens[0].offset, length: 0)
            let identifierRange = file.stringView.byteRangeToNSRange(byteRange)
            return identifierRange.map { NSUnionRange($0, range) }
        }
    }
}

private let issue1029Example = Example("""
    ↓//MARK:- Top-Level bad mark
    ↓//MARK:- Another bad mark
    struct MarkTest {}
    ↓// MARK:- Bad mark
    extension MarkTest {}
    """)

private let issue1029Correction = Example("""
    // MARK: - Top-Level bad mark
    // MARK: - Another bad mark
    struct MarkTest {}
    // MARK: - Bad mark
    extension MarkTest {}
    """)

// https://github.com/realm/SwiftLint/issues/1749
// https://github.com/realm/SwiftLint/issues/3841
private let issue1749Example = Example(
    """
    /*
    func test1() {
    }
    //MARK: mark
    func test2() {
    }
    */
    """
)

// This example should not trigger changes
private let issue1749Correction = issue1749Example

// These need to be at the bottom of the file to work around https://bugs.swift.org/browse/SR-10486

private let nonSpace = "[^ ]"
private let twoOrMoreSpace = " {2,}"
private let mark = "MARK:"
private let nonSpaceOrTwoOrMoreSpace = "(?:\(nonSpace)|\(twoOrMoreSpace))"

private let nonSpaceOrTwoOrMoreSpaceOrNewline = "(?:[^ \n]|\(twoOrMoreSpace))"
