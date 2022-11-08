import Foundation
import SourceKittenFramework

struct ExplicitSelfRule: CorrectableRule, ConfigurationProviderRule, AnalyzerRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "explicit_self",
        name: "Explicit Self",
        description: "Instance variables and functions should be explicitly accessed with 'self.'.",
        kind: .style,
        nonTriggeringExamples: ExplicitSelfRuleExamples.nonTriggeringExamples,
        triggeringExamples: ExplicitSelfRuleExamples.triggeringExamples,
        corrections: ExplicitSelfRuleExamples.corrections,
        requiresFileOnDisk: true
    )

    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        return violationRanges(in: file, compilerArguments: compilerArguments).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        let violations = violationRanges(in: file, compilerArguments: compilerArguments)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        var contents = file.contents.bridge()
        let description = Self.description
        var corrections = [Correction]()
        for range in matches.reversed() {
            contents = contents.replacingCharacters(in: range, with: "self.").bridge()
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents.bridge())
        return corrections
    }

    private func violationRanges(in file: SwiftLintFile, compilerArguments: [String]) -> [NSRange] {
        guard compilerArguments.isNotEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(Self.description.identifier) rule without any compiler arguments.
                """)
            return []
        }

        let allCursorInfo: [[String: SourceKitRepresentable]]
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

        return cursorsMissingExplicitSelf.compactMap { cursorInfo in
            guard let byteOffset = (cursorInfo["swiftlint.offset"] as? Int64).flatMap(ByteCount.init) else {
                queuedPrintError("couldn't convert offsets")
                return nil
            }

            return contents.byteRangeToNSRange(ByteRange(location: byteOffset, length: 0))
        }
    }
}

private let kindsToFind: Set = [
    "source.lang.swift.ref.function.method.instance",
    "source.lang.swift.ref.var.instance"
]

private extension SwiftLintFile {
    func allCursorInfo(compilerArguments: [String], atByteOffsets byteOffsets: [ByteCount]) throws
        -> [[String: SourceKitRepresentable]] {
        return try byteOffsets.compactMap { offset in
            if isExplicitAccess(at: offset) { return nil }
            var cursorInfo = try Request.cursorInfo(file: self.path!, offset: offset,
                                                    arguments: compilerArguments).sendIfNotDisabled()

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
        stringView.substringWithByteRange(ByteRange(location: location - 1, length: 1))! == "."
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
