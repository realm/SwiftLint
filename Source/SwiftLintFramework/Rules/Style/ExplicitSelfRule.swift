import Foundation
import SourceKittenFramework

public struct ExplicitSelfRule: CorrectableRule, ConfigurationProviderRule, AnalyzerRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_self",
        name: "Explicit Self",
        description: "Instance variables and functions should be explicitly accessed with 'self.'.",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            struct A {
                func f1() {}
                func f2() {
                    self.f1()
                }
            }
            """),
            Example("""
            struct A {
                let p1: Int
                func f1() {
                    _ = self.p1
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct A {
                func f1() {}
                func f2() {
                    ↓f1()
                }
            }
            """),
            Example("""
            struct A {
                let p1: Int
                func f1() {
                    _ = ↓p1
                }
            }
            """)
        ],
        corrections: [
            Example("""
            struct A {
                func f1() {}
                func f2() {
                    ↓f1()
                }
            }
            """):
            Example("""
            struct A {
                func f1() {}
                func f2() {
                    self.f1()
                }
            }
            """),
            Example("""
            struct A {
                let p1: Int
                func f1() {
                    _ = ↓p1
                }
            }
            """):
            Example("""
            struct A {
                let p1: Int
                func f1() {
                    _ = self.p1
                }
            }
            """)
        ],
        requiresFileOnDisk: true
    )

    public func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        return violationRanges(in: file, compilerArguments: compilerArguments).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        let violations = violationRanges(in: file, compilerArguments: compilerArguments)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        var contents = file.contents.bridge()
        let description = type(of: self).description
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
        guard !compilerArguments.isEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(type(of: self).description.identifier) rule without any compiler arguments.
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

        guard !cursorsMissingExplicitSelf.isEmpty else {
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
            if stringView.substringWithByteRange(ByteRange(location: offset - 1, length: 1))! == "." { return nil }
            var cursorInfo = try Request.cursorInfo(file: self.path!, offset: offset,
                                                    arguments: compilerArguments).sendIfNotDisabled()
            cursorInfo["swiftlint.offset"] = Int64(offset.value)
            return cursorInfo
        }
    }
}

private extension StringView {
    func byteOffset(forLine line: Int, column: Int) -> ByteCount {
        guard line > 0 else { return ByteCount(column - 1) }
        return lines[line - 1].byteRange.location + ByteCount(column - 1)
    }

    func recursiveByteOffsets(_ dict: [String: Any]) -> [ByteCount] {
        let cur: [ByteCount]
        if let line = dict["key.line"] as? Int64,
            let column = dict["key.column"] as? Int64,
            let kindString = dict["key.kind"] as? String,
            kindsToFind.contains(kindString) {
            cur = [byteOffset(forLine: Int(line), column: Int(column))]
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
