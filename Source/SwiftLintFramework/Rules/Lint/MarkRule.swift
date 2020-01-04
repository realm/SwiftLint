import Foundation
import SourceKittenFramework

public struct MarkRule: CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "mark",
        name: "Mark",
        description: "MARK comment should be in valid format. e.g. '// MARK: ...' or '// MARK: - ...'",
        kind: .lint,
        nonTriggeringExamples: [
            "// MARK: good\n",
            "// MARK: - good\n",
            "// MARK: -\n",
            "// BOOKMARK",
            "//BOOKMARK",
            "// BOOKMARKS"
        ],
        triggeringExamples: [
            "↓//MARK: bad",
            "↓// MARK:bad",
            "↓//MARK:bad",
            "↓//  MARK: bad",
            "↓// MARK:  bad",
            "↓// MARK: -bad",
            "↓// MARK:- bad",
            "↓// MARK:-bad",
            "↓//MARK: - bad",
            "↓//MARK:- bad",
            "↓//MARK: -bad",
            "↓//MARK:-bad",
            "↓//Mark: bad",
            "↓// Mark: bad",
            "↓// MARK bad",
            "↓//MARK bad",
            "↓// MARK - bad",
            "↓//MARK : bad",
            "↓// MARKL:",
            "↓// MARKR ",
            "↓// MARKK -",
            "↓/// MARK:",
            "↓/// MARK bad",
            issue1029Example
        ],
        corrections: [
            "↓//MARK: comment": "// MARK: comment",
            "↓// MARK:  comment": "// MARK: comment",
            "↓// MARK:comment": "// MARK: comment",
            "↓//  MARK: comment": "// MARK: comment",
            "↓//MARK: - comment": "// MARK: - comment",
            "↓// MARK:- comment": "// MARK: - comment",
            "↓// MARK: -comment": "// MARK: - comment",
            "↓// MARK: -  comment": "// MARK: - comment",
            "↓// Mark: comment": "// MARK: comment",
            "↓// Mark: - comment": "// MARK: - comment",
            "↓// MARK - comment": "// MARK: - comment",
            "↓// MARK : comment": "// MARK: comment",
            "↓// MARKL:": "// MARK:",
            "↓// MARKL: -": "// MARK: -",
            "↓// MARKK ": "// MARK: ",
            "↓// MARKK -": "// MARK: -",
            "↓/// MARK:": "// MARK:",
            "↓/// MARK comment": "// MARK: comment",
            issue1029Example: issue1029Correction
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file, matching: pattern).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
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
        let description = type(of: self).description
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
        return file.rangesAndTokens(matching: pattern).filter { _, syntaxTokens in
            guard let syntaxKind = syntaxTokens.first?.kind else {
                return false
            }
            return !syntaxTokens.isEmpty && SyntaxKind.commentKinds.contains(syntaxKind)
        }.compactMap { range, syntaxTokens in
            let identifierRange = file.stringView
                .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
            return identifierRange.map { NSUnionRange($0, range) }
        }
    }
}

private let issue1029Example = "↓//MARK:- Top-Level bad mark\n" +
                               "↓//MARK:- Another bad mark\n" +
                               "struct MarkTest {}\n" +
                               "↓// MARK:- Bad mark\n" +
                               "extension MarkTest {}\n"

private let issue1029Correction = "// MARK: - Top-Level bad mark\n" +
                                 "// MARK: - Another bad mark\n" +
                                 "struct MarkTest {}\n" +
                                 "// MARK: - Bad mark\n" +
                                 "extension MarkTest {}\n"

// These need to be at the bottom of the file to work around https://bugs.swift.org/browse/SR-10486

private let nonSpace = "[^ ]"
private let twoOrMoreSpace = " {2,}"
private let mark = "MARK:"
private let nonSpaceOrTwoOrMoreSpace = "(?:\(nonSpace)|\(twoOrMoreSpace))"

private let nonSpaceOrTwoOrMoreSpaceOrNewline = "(?:[^ \n]|\(twoOrMoreSpace))"
