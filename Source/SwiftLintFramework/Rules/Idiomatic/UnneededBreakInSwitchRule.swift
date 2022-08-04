import Foundation
import SourceKittenFramework

private func embedInSwitch(
    _ text: String,
    case: String = "case .bar",
    file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
        switch foo {
        \(`case`):
            \(text)
        }
        """, file: file, line: line)
}
public struct UnneededBreakInSwitchRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unneeded_break_in_switch",
        name: "Unneeded Break in Switch",
        description: "Avoid using unneeded break statements.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            embedInSwitch("break"),
            embedInSwitch("break", case: "default"),
            embedInSwitch("for i in [0, 1, 2] { break }"),
            embedInSwitch("if true { break }"),
            embedInSwitch("something()"),
            Example("""
            let items = [Int]()
            for item in items {
                if bar() {
                    do {
                        try foo()
                    } catch {
                        bar()
                        break
                    }
                }
            }
            """)
        ],
        triggeringExamples: [
            embedInSwitch("something()\n    ↓break"),
            embedInSwitch("something()\n    ↓break // comment"),
            embedInSwitch("something()\n    ↓break", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.match(pattern: "break", with: [.keyword]).compactMap { range in
            let contents = file.stringView
            let structureDict = file.structureDictionary

            guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length),
                  case let lastStructures = structureDict.structures(forByteOffset: byteRange.location).suffix(2),
                  lastStructures.compactMap(\.statementKind) == [.switch, .case],
                  let innerStructure = lastStructures.last,
                  let caseRange = innerStructure.byteRange,
                  let lastPatternEnd = patternEnd(dictionary: innerStructure) else {
                    return nil
            }

            let tokens = file.syntaxMap.tokens(inByteRange: caseRange).filter { token in
                guard let kind = token.kind,
                    token.offset > lastPatternEnd else {
                        return false
                }

                return !kind.isCommentLike
            }

            // is the `break` the only token inside `case`? If so, it's valid.
            guard tokens.count > 1 else {
                return nil
            }

            // is the `break` found the last (non-comment) token inside `case`?
            guard let lastValidToken = tokens.last,
                lastValidToken.kind == .keyword,
                lastValidToken.offset == byteRange.location,
                lastValidToken.length == byteRange.length else {
                    return nil
            }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }

    private func patternEnd(dictionary: SourceKittenDictionary) -> ByteCount? {
        let patternEnds = dictionary.elements.compactMap { subDictionary -> ByteCount? in
            guard subDictionary.kind == "source.lang.swift.structure.elem.pattern",
                let offset = subDictionary.offset,
                let length = subDictionary.length else {
                    return nil
            }

            return offset + length
        }

        return patternEnds.max()
    }
}
