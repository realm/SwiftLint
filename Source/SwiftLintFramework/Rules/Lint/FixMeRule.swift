import Foundation
import SourceKittenFramework

struct FixMeRule: CorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "fixme",
        name: "FixMe",
        description: "FIXME comment should be in valid format. e.g. '// FIXME: ...' or '// FIXME: - ...'",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// FIXME: good\n"),
            Example("// FIXME: - good\n"),
            Example("// FIXME: -\n"),
            Example("// MYFIXME"),
            Example("//MYFIXME"),
            Example("// MYFIXMES"),
            exampleTwo
        ],
        triggeringExamples: [
            Example("↓//FIXME: bad"),
            Example("↓// FIXME:bad"),
            Example("↓//FIXME:bad"),
            Example("↓//  FIXME: bad"),
            Example("↓// FIXME:  bad"),
            Example("↓// FIXME: -bad"),
            Example("↓// FIXME:- bad"),
            Example("↓// FIXME:-bad"),
            Example("↓//FIXME: - bad"),
            Example("↓//FIXME:- bad"),
            Example("↓//FIXME: -bad"),
            Example("↓//FIXME:-bad"),
            Example("↓//Fixme: bad"),
            Example("↓// Fixme: bad"),
            Example("↓// FIXME bad"),
            Example("↓//FIXME bad"),
            Example("↓// FIXME - bad"),
            Example("↓//FIXME : bad"),
            Example("↓// FIXMEL:"),
            Example("↓// FIXMER "),
            Example("↓// FIXMEK -"),
            Example("↓/// FIXME:"),
            Example("↓/// FIXME bad"),
            exampleOne
        ],
        corrections: [
            Example("↓//FIXME: comment"): Example("// FIXME: comment"),
            Example("↓// FIXME:  comment"): Example("// FIXME: comment"),
            Example("↓// FIXME:comment"): Example("// FIXME: comment"),
            Example("↓//  FIXME: comment"): Example("// FIXME: comment"),
            Example("↓//FIXME: - comment"): Example("// FIXME: - comment"),
            Example("↓// FIXME:- comment"): Example("// FIXME: - comment"),
            Example("↓// FIXME: -comment"): Example("// FIXME: - comment"),
            Example("↓// FIXME: -  comment"): Example("// FIXME: - comment"),
            Example("↓// Fixme: comment"): Example("// FIXME: comment"),
            Example("↓// Fixme: - comment"): Example("// FIXME: - comment"),
            Example("↓// FIXME - comment"): Example("// FIXME: - comment"),
            Example("↓// FIXME : comment"): Example("// FIXME: comment"),
            Example("↓// FIXMEL:"): Example("// FIXME:"),
            Example("↓// FIXMEL: -"): Example("// FIXME: -"),
            Example("↓// FIXMEK "): Example("// FIXME: "),
            Example("↓// FIXMEK -"): Example("// FIXME: -"),
            Example("↓/// FIXME:"): Example("// FIXME:"),
            Example("↓/// FIXME comment"): Example("// FIXME: comment"),
            exampleOne: exampleOneCorrection,
            exampleTwo: exampleTwoCorrection
        ]
    )

    private let spaceStartPattern = "(?:\(nonSpaceOrTwoOrMoreSpace)\(fixme))"

    private let endNonSpacePattern = "(?:\(fixme)\(nonSpace))"
    private let endTwoOrMoreSpacePattern = "(?:\(fixme)\(twoOrMoreSpace))"

    private let invalidEndSpacesPattern = "(?:\(fixme)\(nonSpaceOrTwoOrMoreSpace))"

    private let twoOrMoreSpacesAfterHyphenPattern = "(?:\(fixme) -\(twoOrMoreSpace))"
    private let nonSpaceOrNewlineAfterHyphenPattern = "(?:\(fixme) -[^ \n])"

    private let invalidSpacesAfterHyphenPattern = "(?:\(fixme) -\(nonSpaceOrTwoOrMoreSpaceOrNewline))"

    private let invalidLowercasePattern = "(?:// ?[Ff]ix[Mm]e:)"

    private let missingColonPattern = "(?:// ?FIXME[^:])"
    // The below patterns more specifically describe some of the above pattern's failure cases for correction.
    private let oneOrMoreSpacesBeforeColonPattern = "(?:// ?FIXME +:)"
    private let nonWhitespaceBeforeColonPattern = "(?:// ?FIXME\\S+:)"
    private let nonWhitespaceNorColonBeforeSpacesPattern = "(?:// ?FIXME[^\\s:]* +)"
    private let threeSlashesInsteadOfTwo = "/// FIXME:?"

    private var pattern: String {
        return [
            spaceStartPattern,
            invalidEndSpacesPattern,
            invalidSpacesAfterHyphenPattern,
            invalidLowercasePattern,
            missingColonPattern, // here
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
                                          replaceString: "// FIXME:"))

        result.append(contentsOf: correct(file: file,
                                          pattern: endNonSpacePattern,
                                          replaceString: "// FIXME: ",
                                          keepLastChar: true))

        result.append(contentsOf: correct(file: file,
                                          pattern: endTwoOrMoreSpacePattern,
                                          replaceString: "// FIXME: "))

        result.append(contentsOf: correct(file: file,
                                          pattern: twoOrMoreSpacesAfterHyphenPattern,
                                          replaceString: "// FIXME: - "))

        result.append(contentsOf: correct(file: file,
                                          pattern: nonSpaceOrNewlineAfterHyphenPattern,
                                          replaceString: "// FIXME: - ",
                                          keepLastChar: true))

        result.append(contentsOf: correct(file: file,
                                          pattern: oneOrMoreSpacesBeforeColonPattern,
                                          replaceString: "// FIXME:",
                                          keepLastChar: false))

        result.append(contentsOf: correct(file: file,
                                          pattern: nonWhitespaceBeforeColonPattern,
                                          replaceString: "// FIXME:",
                                          keepLastChar: false))

        result.append(contentsOf: correct(file: file,
                                          pattern: nonWhitespaceNorColonBeforeSpacesPattern,
                                          replaceString: "// FIXME: ",
                                          keepLastChar: false))

        result.append(contentsOf: correct(file: file,
                                          pattern: invalidLowercasePattern,
                                          replaceString: "// FIXME:"))

        result.append(contentsOf: correct(file: file,
                                          pattern: threeSlashesInsteadOfTwo,
                                          replaceString: "// FIXME:"))

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
                // Skip FIXMEs that are part of a multiline comment
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

// Based on MarkRule issue1029Example
private let exampleOne = Example("""
    ↓//FIXME:- Top-Level bad fixme
    ↓//FIXME:- Another bad fixme
    struct FixMeTest {}
    ↓// FIXME:- Bad fixme
    extension FixMeTest {}
    """)

private let exampleOneCorrection = Example("""
    // FIXME: - Top-Level bad fixme
    // FIXME: - Another bad fixme
    struct FixMeTest {}
    // FIXME: - Bad fixme
    extension FixMeTest {}
    """)

// Based on MarkRule issue1749Example
// https://github.com/realm/SwiftLint/issues/1749
// https://github.com/realm/SwiftLint/issues/3841
private let exampleTwo = Example(
    """
    /*
    func test1() {
    }
    //FIXME: fixme
    func test2() {
    }
    */
    """
)

// This example should not trigger changes
private let exampleTwoCorrection = exampleTwo

// These need to be at the bottom of the file to work around https://bugs.swift.org/browse/SR-10486

private let nonSpace = "[^ ]"
private let twoOrMoreSpace = " {2,}"
private let fixme = "FIXME:"
private let nonSpaceOrTwoOrMoreSpace = "(?:\(nonSpace)|\(twoOrMoreSpace))"

private let nonSpaceOrTwoOrMoreSpaceOrNewline = "(?:[^ \n]|\(twoOrMoreSpace))"
