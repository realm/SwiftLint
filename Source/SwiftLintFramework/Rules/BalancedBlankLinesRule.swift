import Foundation
import SourceKittenFramework

public struct BalancedBlankLinesRule: Rule, ConfigurationProviderRule, CorrectableRule, OptInRule {

    // MARK: - ConfigurationProviderRule

    public var configuration = SeverityConfiguration(.warning)

    // MARK: - Rule

    public init() {}

    public static let description = RuleDescription(
        identifier: "balanced_blank_lines",
        name: "Balanced Blank Lines",
        description: "The number of blank lines at the beginning and end of a curly-braced body should be identical.",
        kind: .style,
        nonTriggeringExamples: [
            "if x == y {\n    return\n}",
            "func foo() {\n    return 0\n}",
            "class C {\n    let x = true\n}",
            "class C {\n\n    let x = true\n\n}"
        ],
        triggeringExamples: [
            "if x == y ↓{\n\n    return\n}",
            "if x == y {\n    return\n\n↓}",
            "func foo() ↓{\n\n    return 0\n}",
            "func foo() {\n    return 0\n\n↓}",
            "class C {\n\n    let x = true\n↓}",
            "class C {\n    let x = true\n\n↓}"
        ],
        corrections: [
            "if x == y ↓{\n\n    return\n}": "if x == y {\n    return\n}",
            "if x == y {\n    return\n\n↓}": "if x == y {\n    return\n}",
            "func foo() ↓{\n\n    return 0\n}": "func foo() {\n    return 0\n}",
            "func foo() {\n    return 0\n\n↓}": "func foo() {\n    return 0\n}",
            "class C {\n\n    let x = true\n↓}": "class C {\n\n    let x = true\n\n}",
            "class C {\n    let x = true\n\n↓}": "class C {\n    let x = true\n}",
            "struct S {\n\n    let x = true\n↓}": "struct S {\n\n    let x = true\n\n}",
            "struct S {\n    let x = true\n\n↓}": "struct S {\n    let x = true\n}",
            "protocol P {\n\n    func foo()\n↓}": "protocol P {\n\n    func foo()\n\n}",
            "protocol P {\n    func foo()\n\n↓}": "protocol P {\n    func foo()\n}",
            "extension P {\n\n    func foo() {}\n↓}": "extension P {\n\n    func foo() {}\n\n}",
            "extension P {\n    func foo() {}\n\n↓}": "extension P {\n    func foo() {}\n}",
            "extension P {\n    func foo() {\n        return\n\n    ↓}\n}":
                "extension P {\n    func foo() {\n        return\n    }\n}",
            "class C {\n    init() ↓{\n\n        print(\"\")\n    }\n}":
                "class C {\n    init() {\n        print(\"\")\n    }\n}",
            "class C {\n    \n    private let foo: String? = nil\n↓}":
                "class C {\n    \n    private let foo: String? = nil\n\n}",
            "func foo() ↓{\n\n    func bar() ↓{\n\n        let foobar = true\n    }\n}":
                "func foo() {\n    func bar() {\n        let foobar = true\n    }\n}",
            "class A {\n\n    class B {\n\n        let foo = true\n    ↓}\n\n}":
                "class A {\n\n    class B {\n\n        let foo = true\n\n    }\n\n}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return findUnbalancedBodies(in: file).map { StyleViolation(
            ruleDescription: type(of: self).description,
            severity: configuration.severity,
            location: Location(file: file, characterOffset: $0.locationForCorrection),
            reason: "Blank lines at the beginning and end of a body should be balanced "
                + "(found \($0.blankLinesAtBeginning) / \($0.blankLinesAtEnd))")
        }
    }

    // MARK: - CorrectableRule

    public func correct(file: File) -> [Correction] {
        let unbalancedBodies = findUnbalancedBodies(in: file).filter {
            !file.ruleEnabled(violatingRanges: [$0.openingBrace, $0.closingBrace], for: self).isEmpty
        }
        var correctedContents = file.contents
        var adjustedLocations = [Location]()
        for body in unbalancedBodies.sorted(by: { $0.locationForCorrection > $1.locationForCorrection }) {
            if let contents = correctUnbalancedBody(body, in: correctedContents) {
                correctedContents = contents
                adjustedLocations.append(Location(file: file, characterOffset: body.locationForCorrection))
            }
        }
        file.write(correctedContents)
        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description, location: $0)
        }
    }

}

// MARK: - Violation Helpers

private struct UnbalancedBody {
    let kind: String
    let openingBrace: NSRange
    let closingBrace: NSRange
    let blankLinesAtBeginning: (count: Int, range: Range<String.Index>?)
    let blankLinesAtEnd: (count: Int, range: Range<String.Index>?)

    func computeOpeningBraceAndBlankLinesRange(in content: String) -> Range<String.Index>? {
        guard let indexRange = content.nsrangeToIndexRange(openingBrace) else {
            return nil
        }
        guard let blankLinesRange = blankLinesAtBeginning.range else {
            return Range<String.Index>(uncheckedBounds: (
                lower: indexRange.lowerBound,
                upper: content.lineRange(for: indexRange).upperBound))
        }
        return Range<String.Index>(uncheckedBounds: (
            lower: indexRange.lowerBound,
            upper: blankLinesRange.upperBound))
    }

    func computeClosingBraceAndBlankLinesRange(in content: String) -> Range<String.Index>? {
        guard let indexRange = content.nsrangeToIndexRange(closingBrace) else {
            return nil
        }
        guard let blankLinesRange = blankLinesAtEnd.range else {
            return Range<String.Index>(uncheckedBounds: (
                lower: content.lineRange(for: indexRange).lowerBound,
                upper: indexRange.upperBound))
        }
        return Range<String.Index>(uncheckedBounds: (
            lower: blankLinesRange.lowerBound,
            upper: indexRange.upperBound))
    }
}

private func findUnbalancedBodies(in file: File) -> [UnbalancedBody] {
    let braceRanges = file.match(pattern: "[\\{\\}]", excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    var openingBraces = [NSRange]()
    var unbalancedBodies = [UnbalancedBody]()
    for range in braceRanges {
        guard let indexRange = file.contents.nsrangeToIndexRange(range) else {
            continue
        }
        if file.contents[indexRange] == "{" {
            openingBraces.append(range)
        } else if let openingRange = openingBraces.popLast() {
            guard let openingIndexRange = file.contents.nsrangeToIndexRange(openingRange) else {
                continue
            }
            if let body = checkForUnbalancedBody(
                openingRange: openingRange,
                openingIndexRange: openingIndexRange,
                closingRange: range,
                closingIndexRange: indexRange,
                file: file) {
                unbalancedBodies.append(body)
            }
        }
    }
    return unbalancedBodies
}

private func checkForUnbalancedBody(openingRange: NSRange,
                                    openingIndexRange: Range<String.Index>,
                                    closingRange: NSRange,
                                    closingIndexRange: Range<String.Index>,
                                    file: File) -> UnbalancedBody? {
    let openingLineRange = file.contents.lineRange(for: openingIndexRange)
    let closingLineRange = file.contents.lineRange(for: closingIndexRange)
    guard openingLineRange != closingLineRange else {
        return nil
    }
    let blankLinesAtBeginning = findBlankLines(
        from: openingLineRange,
        in: file.contents,
        direction: .forward)
    let blankLinesAtEnd = findBlankLines(
        from: closingLineRange,
        in: file.contents,
        direction: .backward)
    guard blankLinesAtBeginning.count != blankLinesAtEnd.count,
        let byteOffset = file.contents.NSRangeToByteRange(
            start: closingRange.location,
            length: closingRange.length),
        let kind = file.structure.kinds(forByteOffset: byteOffset.location).last?.kind else {
            return nil
    }
    return UnbalancedBody(
        kind: kind,
        openingBrace: openingRange,
        closingBrace: closingRange,
        blankLinesAtBeginning: blankLinesAtBeginning,
        blankLinesAtEnd: blankLinesAtEnd)
}

private func findBlankLines(from lineRange: Range<String.Index>,
                            in content: String,
                            direction: SearchDirection) -> (count: Int, range: Range<String.Index>?) {
    guard let nextLineRange = direction.advance(from: lineRange, in: content),
        content[nextLineRange].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (count: 0, range: nil)
    }
    let (followingCount, followingRange) = findBlankLines(from: nextLineRange, in: content, direction: direction)
    let combinedRange: Range<String.Index>
    if let followingRange = followingRange {
        combinedRange = Range<String.Index>(uncheckedBounds: (
            lower: nextLineRange.lowerBound,
            upper: followingRange.upperBound))
    } else {
        combinedRange = nextLineRange
    }
    return (count: 1 + followingCount, range: combinedRange)
}

private enum SearchDirection {
    case forward
    case backward

    func advance(from lineRange: Range<String.Index>, in content: String) -> Range<String.Index>? {
        guard let nextIndex = getIndexForAdvancing(from: lineRange, in: content) else {
            return nil
        }
        let nextRange = Range<String.Index>(uncheckedBounds: (lower: nextIndex, upper: nextIndex))
        return content.lineRange(for: nextRange)
    }

    private func getIndexForAdvancing(from lineRange: Range<String.Index>, in content: String) -> String.Index? {
        guard canAdvance(from: lineRange, in: content) else {
            return nil
        }
        switch self {
        case .forward:
            return lineRange.upperBound
        case .backward:
            return content.index(before: lineRange.lowerBound)
        }
    }

    private func canAdvance(from lineRange: Range<String.Index>, in content: String) -> Bool {
        switch self {
        case .forward:
            return lineRange.upperBound != content.endIndex
        case .backward:
            return lineRange.lowerBound != content.startIndex
        }
    }
}

// MARK: - Correction Helpers

private let kindsAllowingSurroundingBlankLines = [SwiftDeclarationKind.class.rawValue,
                                                  SwiftDeclarationKind.enum.rawValue,
                                                  SwiftDeclarationKind.extension.rawValue,
                                                  SwiftDeclarationKind.extensionClass.rawValue,
                                                  SwiftDeclarationKind.extensionEnum.rawValue,
                                                  SwiftDeclarationKind.extensionProtocol.rawValue,
                                                  SwiftDeclarationKind.extensionStruct.rawValue,
                                                  SwiftDeclarationKind.protocol.rawValue,
                                                  SwiftDeclarationKind.struct.rawValue]

extension UnbalancedBody {
    var isCorrectableAtClosingBrace: Bool {
        return kindsAllowingSurroundingBlankLines.contains(kind)
            || blankLinesAtBeginning.count < blankLinesAtEnd.count
    }

    var locationForCorrection: Int {
        return isCorrectableAtClosingBrace ? closingBrace.location : openingBrace.location
    }
}

private func correctUnbalancedBody(_ unbalancedBody: UnbalancedBody, in contents: String) -> String? {
    if unbalancedBody.isCorrectableAtClosingBrace {
        guard let replacementRange = unbalancedBody.computeClosingBraceAndBlankLinesRange(in: contents),
            let closingBraceRange = contents.nsrangeToIndexRange(unbalancedBody.closingBrace) else {
                return nil
        }
        let replacement = replacementString(withRange: unbalancedBody.blankLinesAtBeginning.range, in: contents)
        let closingBraceLineRange = contents.lineRange(for: closingBraceRange)
        let lastLineRange = Range<String.Index>(uncheckedBounds: (
            lower: closingBraceLineRange.lowerBound,
            upper: closingBraceRange.upperBound))
        return contents.replacingCharacters(
            in: replacementRange,
            with: replacement + contents[lastLineRange])
    } else {
        guard let replacementRange = unbalancedBody.computeOpeningBraceAndBlankLinesRange(in: contents),
            let openingBraceRange = contents.nsrangeToIndexRange(unbalancedBody.openingBrace) else {
                return nil
        }
        let replacement = replacementString(withRange: unbalancedBody.blankLinesAtEnd.range, in: contents)
        let openingBraceLineRange = contents.lineRange(for: openingBraceRange)
        let firstLineRange = Range<String.Index>(uncheckedBounds: (
            lower: openingBraceRange.lowerBound,
            upper: openingBraceLineRange.upperBound))
        return contents.replacingCharacters(
            in: replacementRange,
            with: contents[firstLineRange] + replacement)
    }
}

private func replacementString(withRange range: Range<String.Index>?, in content: String) -> String {
    guard let range = range else {
        return ""
    }
    return String(content[range]).replacingOccurrences(of: "[ \t]", with: "", options: .regularExpression)
}
