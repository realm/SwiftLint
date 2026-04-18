import Foundation
import SourceKittenFramework
import SwiftSyntax

struct ExplicitSelfRule: CorrectableRule, AnalyzerRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "explicit_self",
        name: "Explicit Self",
        description: "Instance variables and functions should be explicitly accessed with 'self.'",
        kind: .style,
        nonTriggeringExamples: ExplicitSelfRuleExamples.nonTriggeringExamples,
        triggeringExamples: ExplicitSelfRuleExamples.triggeringExamples,
        corrections: ExplicitSelfRuleExamples.corrections,
        requiresFileOnDisk: true
    )

    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        violationRanges(in: file, compilerArguments: compilerArguments).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    func correct(file: SwiftLintFile, compilerArguments: [String]) -> Int {
        let violations = violationRanges(in: file, compilerArguments: compilerArguments)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty {
            return 0
        }
        var contents = file.contents.bridge()
        for range in matches.reversed() {
            contents = contents.replacingCharacters(in: range, with: "self.").bridge()
        }
        file.write(contents.bridge())
        return matches.count
    }

    private func violationRanges(in file: SwiftLintFile, compilerArguments: [String]) -> [NSRange] {
        guard compilerArguments.isNotEmpty else {
            Issue.missingCompilerArguments(path: file.path, ruleID: Self.identifier).print()
            return []
        }

        let allCursorInfo: [[String: any SourceKitRepresentable]]
        do {
            let byteOffsets = try binaryOffsets(file: file, compilerArguments: compilerArguments)
            allCursorInfo = try file.allCursorInfo(compilerArguments: compilerArguments,
                                                   atByteOffsets: byteOffsets)
        } catch {
            queuedPrintError(String(describing: error))
            return []
        }

        let cursorsMissingExplicitSelf = allCursorInfo.filter { cursorInfo in
            guard let kindString = cursorInfo["key.kind"] as? String else { return false }
            return kindsToFind.contains(kindString)
        }

        guard cursorsMissingExplicitSelf.isNotEmpty else {
            return []
        }

        let contents = file.stringView
        let staticStringLiteralTextRanges = byteRangesOfStaticStringLiteralText(in: file)

        return cursorsMissingExplicitSelf.compactMap { cursorInfo in
            guard let byteOffset = (cursorInfo["swiftlint.offset"] as? Int64).flatMap(ByteCount.init) else {
                Issue.genericWarning("Cannot convert offsets in '\(Self.identifier)' rule.").print()
                return nil
            }

            // SourceKit’s index can attach member refs to identifiers that appear only as text inside a string literal
            // (e.g. `{foo:` before `\(self.foo)`). Those are not real member accesses and must be ignored.
            if staticStringLiteralTextRanges.contains(where: { $0.contains(byteOffset) }) {
                return nil
            }

            // The index sometimes reports a member ref at the `(` of `\(` / `\#(…)`; correcting inserts `self.`
            // before `(` and breaks the interpolation (`\self.(…)` / `\#self.(…)`). Drop these bogus offsets.
            if contents.isStringInterpolationOpenParen(at: byteOffset) {
                return nil
            }

            // SourceKit can also attach refs to string literal delimiters and `\` before `\(` inside `"\(a)\(b)"`-style
            // literals. Those offsets are not identifier starts; inserting `self.` corrupts the literal. Real implicit
            // `self` fixes always begin at the first character of a member name (letter, `_`, or `$`).
            if !contents.isOffsetAtPlausibleImplicitMemberIdentifierHead(byteOffset) {
                return nil
            }

            let sourceKittenDictionary = SourceKittenDictionary(cursorInfo)
            if contents.sourceTextShowsExplicitSelfMember(cursorInfo: sourceKittenDictionary, at: byteOffset) {
                return nil
            }

            return contents.byteRangeToNSRange(ByteRange(location: byteOffset, length: 0))
        }
    }
}

private let kindsToFind: Set = [
    "source.lang.swift.ref.function.method.instance",
    "source.lang.swift.ref.var.instance",
]

private extension SwiftLintFile {
    func allCursorInfo(compilerArguments: [String], atByteOffsets byteOffsets: [ByteCount]) throws
        -> [[String: any SourceKitRepresentable]] {
        try byteOffsets.compactMap { offset in
            if isExplicitAccess(at: offset) { return nil }
            let cursorInfoRequest = Request.cursorInfoWithoutSymbolGraph(
                file: self.path!, offset: offset, arguments: compilerArguments
            )
            var cursorInfo = try cursorInfoRequest.sendIfNotDisabled()

            // Accessing a `projectedValue` of a property wrapper (e.g. `self.$foo`) or the property wrapper itself
            // (e.g. `self._foo`) results in an incorrect `key.length` (it does not account for the identifier
            // prefixes `$` and `_`), while `key.name` contains the prefix. Hence we need to check for explicit access
            // at a corrected offset as well.
            var prefixLength: Int64 = 0
            let sourceKittenDictionary = SourceKittenDictionary(cursorInfo)
            if sourceKittenDictionary.kind == "source.lang.swift.ref.var.instance",
               let name = sourceKittenDictionary.name,
               let length = sourceKittenDictionary.length {
                prefixLength = Int64(name.count - length.value)
                if prefixLength > 0, isExplicitAccess(at: offset - ByteCount(prefixLength)) {
                    return nil
                }
            }

            cursorInfo["swiftlint.offset"] = Int64(offset.value) - prefixLength
            return cursorInfo
        }
    }

    private func isExplicitAccess(at location: ByteCount) -> Bool {
        guard location > 0 else { return false }
        let view = stringView
        // Standard member access: `.foo`
        if view.substringWithByteRange(ByteRange(location: location - 1, length: 1)) == "." {
            return true
        }
        // SourceKit offset for `foo` in string interpolations like `\(self.foo)` can disagree with the
        // character immediately preceding the identifier, so also accept an explicit `self.` prefix.
        let explicitSelfDot = "self."
        let explicitSelfDotLength = ByteCount(explicitSelfDot.utf8.count)
        guard location >= explicitSelfDotLength else { return false }
        let range = ByteRange(location: location - explicitSelfDotLength, length: explicitSelfDotLength)
        return view.substringWithByteRange(range) == explicitSelfDot
    }
}

private extension StringView {
    func recursiveByteOffsets(_ dict: [String: Any]) -> [ByteCount] {
        let cur: [ByteCount]
        if let line = dict["key.line"] as? Int64,
           let column = dict["key.column"] as? Int64,
           let kindString = dict["key.kind"] as? String,
           kindsToFind.contains(kindString),
           let offset = byteOffset(forLine: line, bytePosition: column) {
            cur = [offset]
        } else {
            cur = []
        }
        if let entities = dict["key.entities"] as? [[String: Any]] {
            return entities.flatMap(recursiveByteOffsets) + cur
        }
        return cur
    }
}

private func binaryOffsets(file: SwiftLintFile, compilerArguments: [String]) throws -> [ByteCount] {
    let absoluteFile = file.path!.bridge().absolutePathRepresentation()
    let index = try Request.index(file: absoluteFile, arguments: compilerArguments).sendIfNotDisabled()
    let binaryOffsets = file.stringView.recursiveByteOffsets(index)
    return binaryOffsets.sorted()
}

/// Byte ranges of static text in string literals (excluding `\(...)` interpolation expressions).
private func byteRangesOfStaticStringLiteralText(in file: SwiftLintFile) -> [ByteRange] {
    let visitor = StringLiteralStaticTextVisitor()
    visitor.walk(file.syntaxTree)
    return visitor.byteRanges
}

private final class StringLiteralStaticTextVisitor: SyntaxVisitor {
    private(set) var byteRanges: [ByteRange] = []

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: StringSegmentSyntax) {
        let token = node.content
        let start = token.positionAfterSkippingLeadingTrivia
        let end = token.endPositionBeforeTrailingTrivia
        let length = end.utf8Offset - start.utf8Offset
        guard length > 0 else {
            return
        }
        byteRanges.append(ByteRange(location: ByteCount(start.utf8Offset), length: ByteCount(length)))
    }
}

private extension StringView {
    /// `true` when `offset` starts an identifier that implicit-`self` correction prefixes with `self.`
    /// (`_`, `$`, or a letter). Drops bogus SourceKit offsets on string literal punctuation.
    func isOffsetAtPlausibleImplicitMemberIdentifierHead(_ offset: ByteCount) -> Bool {
        guard let firstChar = firstCharacter(startingAtByteOffset: offset) else {
            return false
        }
        return firstChar.isPlausibleImplicitSelfIdentifierHead
    }

    /// Reads the first `Character` beginning at `offset` (UTF-8); `offset` must be on a character boundary.
    func firstCharacter(startingAtByteOffset offset: ByteCount) -> Character? {
        guard let prefix = substringWithByteRange(ByteRange(location: offset, length: ByteCount(16))) else {
            return nil
        }
        return prefix.first
    }

    /// `true` when `offset` is the `(` that begins string interpolation: `\(` or raw-string `\#…(` (any run of `#`).
    func isStringInterpolationOpenParen(at offset: ByteCount) -> Bool {
        guard offset > 0 else {
            return false
        }
        guard substringWithByteRange(ByteRange(location: offset, length: 1)) == "(" else {
            return false
        }
        var idx = offset - 1
        while idx >= 0, substringWithByteRange(ByteRange(location: idx, length: 1)) == "#" {
            idx -= 1
        }
        guard idx >= 0 else {
            return false
        }
        return substringWithByteRange(ByteRange(location: idx, length: 1)) == "\\"
    }

    /// True when the source at `memberStart` is the member of an explicit `self.<member>` access.
    /// Uses `key.length` from cursor info so the identifier matches the indexed slice
    /// (not `key.name`, which can differ).
    func sourceTextShowsExplicitSelfMember(cursorInfo: SourceKittenDictionary, at memberStart: ByteCount) -> Bool {
        guard let length = cursorInfo.length, length.value > 0,
              let identifier = substringWithByteRange(ByteRange(location: memberStart, length: length)) else {
            return false
        }
        let memberText = "self." + identifier
        guard let memberBytes = memberText.data(using: .utf8), !memberBytes.isEmpty else {
            return false
        }
        let memberLength = ByteCount(memberBytes.count)
        let selfDotLength = ByteCount("self.".utf8.count)
        guard memberStart >= selfDotLength else {
            return false
        }
        let spanStart = memberStart - selfDotLength
        return substringWithByteRange(ByteRange(location: spanStart, length: memberLength)) == memberText
    }
}

private extension ByteRange {
    func contains(_ offset: ByteCount) -> Bool {
        offset >= location && offset < location + length
    }
}

private extension Character {
    /// First character of an instance member name referenced without `self.` (including `$foo` / `_foo` wrappers).
    var isPlausibleImplicitSelfIdentifierHead: Bool {
        if self == "_" || self == "$" {
            return true
        }
        if isLetter {
            return true
        }
        // Bogus index offsets in string literals are almost always ASCII punctuation (`"`, `\`, delimiters).
        if isASCII {
            return false
        }
        // Rare non-ASCII identifier heads that are not “letters” in Unicode sense: allow rather than risk false
        // negatives for valid Unicode identifiers.
        return true
    }
}
