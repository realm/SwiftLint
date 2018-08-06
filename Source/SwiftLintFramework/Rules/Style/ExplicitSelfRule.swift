import Foundation
import SourceKittenFramework

public struct ExplicitSelfRule: CorrectableRule, ConfigurationProviderRule, CompilerArgumentRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_self",
        name: "Explicit Self",
        description: "Instance variables and functions should be explicitly accessed with 'self.'.",
        kind: .style,
        nonTriggeringExamples: [
            """
            struct A {
                let p1: Int
                func f1() {
                    self.p1 = 0
                }
                func f2() {
                    self.f1()
                }
            }
            """
        ],
        triggeringExamples: [
            """
            struct A {
                let p1: Int
                func f1() {
                    ↓p1 = 0
                }
                func f2() {
                    ↓f1()
                }
            }
            """
        ],
        corrections: [
            """
            struct A {
                let p1: Int
                func f1() {
                    ↓p1 = 0
                }
                func f2() {
                    ↓f1()
                }
            }
            """:
            """
            struct A {
                let p1: Int
                func f1() {
                    self.p1 = 0
                }
                func f2() {
                    self.f1()
                }
            }
            """
        ]
    )

    public func validate(file: File, compilerArguments: [String]) -> [StyleViolation] {
        return selfish(runMode: .log, file: file, compilerArguments: compilerArguments)
    }

    public func correct(file: File, compilerArguments: [String]) -> [Correction] {
        let violations = selfish(runMode: .overwrite, file: file, compilerArguments: compilerArguments)
        return violations.map { violation in
            return Correction(ruleDescription: violation.ruleDescription, location: violation.location)
        }
    }
}

private let kindsToFind = Set([
    "source.lang.swift.ref.function.method.instance",
    "source.lang.swift.ref.var.instance"
])

private extension File {
    func allCursorInfo(compilerArguments: [String], atByteOffsets byteOffsets: [Int]) throws
        -> [[String: SourceKitRepresentable]] {
        return try byteOffsets.compactMap { offset in
            if contents.bridge().substringWithByteRange(start: offset - 1, length: 1)! == "." { return nil }
            var cursorInfo = try Request.cursorInfo(file: self.path!, offset: Int64(offset),
                                                    arguments: compilerArguments).send()
            cursorInfo["jp.offset"] = Int64(offset)
            return cursorInfo
        }
    }
}

private extension NSString {
    func byteOffset(forLine line: Int, column: Int) -> Int {
        var byteOffset = 0
        for line in lines()[..<(line - 1)] {
            byteOffset += line.byteRange.length
        }
        return byteOffset + column - 1
    }

    func recursiveByteOffsets(_ dict: [String: Any]) -> [Int] {
        let cur: [Int]
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

private func binaryOffsets(file: File, compilerArguments: [String]) throws -> [Int] {
    let absoluteFile = file.path!.bridge().absolutePathRepresentation()
    let index = try Request.index(file: absoluteFile, arguments: compilerArguments).send()
    let binaryOffsets = file.contents.bridge().recursiveByteOffsets(index)
    return binaryOffsets.sorted()
}

private enum RunMode {
    case log
    case overwrite
}

private func selfish(runMode: RunMode, file: File, compilerArguments: [String]) -> [StyleViolation] {
    guard !compilerArguments.isEmpty else {
        return []
    }

    let allCursorInfo: [[String: SourceKitRepresentable]]
    do {
        let byteOffsets = try binaryOffsets(file: file, compilerArguments: compilerArguments)
        allCursorInfo = try file.allCursorInfo(compilerArguments: compilerArguments, atByteOffsets: byteOffsets)
    } catch {
        print(error)
        return []
    }

    let cursorsMissingExplicitSelf = allCursorInfo.filter { cursorInfo in
        guard let kindString = cursorInfo["key.kind"] as? String else { return false }
        return kindsToFind.contains(kindString)
    }

    guard !cursorsMissingExplicitSelf.isEmpty else {
        return []
    }

    if runMode == .log {
        return cursorsMissingExplicitSelf.compactMap { cursorInfo in
            guard let byteOffset = cursorInfo["jp.offset"] as? Int64 else {
                print("couldn't convert offsets")
                return nil
            }

            return StyleViolation(ruleDescription: ExplicitSelfRule.description, severity: .warning,
                                  location: Location(file: file, byteOffset: Int(byteOffset)),
                                  reason: "Missing explicit reference to 'self.'")
        }
    }

    guard let contents = file.contents.bridge().mutableCopy() as? NSMutableString else {
        print("couldn't make mutable copy of contents")
        return []
    }

    for cursorInfo in cursorsMissingExplicitSelf.reversed() {
        guard let byteOffset = cursorInfo["jp.offset"] as? Int64,
            let nsrangeToInsert = contents.byteRangeToNSRange(start: Int(byteOffset), length: 0) else {
            print("couldn't convert offsets")
            return []
        }
        contents.replaceCharacters(in: nsrangeToInsert, with: "self.")
    }

    file.write(contents.bridge())
    return []
}
