import Foundation
import SourceKittenFramework

public struct DuplicateImportsRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    // List of all possible import kinds
    static let importKinds = [
        "typealias", "struct", "class",
        "enum", "protocol", "let",
        "var", "func"
    ]

    public init() {}

    public static let description = RuleDescription(
        identifier: "duplicate_imports",
        name: "Duplicate Imports",
        description: "Imports should be unique.",
        kind: .idiomatic,
        nonTriggeringExamples: DuplicateImportsRuleExamples.nonTriggeringExamples,
        triggeringExamples: DuplicateImportsRuleExamples.triggeringExamples
    )

    private func rangesInConditionalCompilation(file: SwiftLintFile) -> [ByteRange] {
        let contents = file.stringView

        let ranges = file.syntaxMap.tokens
            .filter { $0.kind == .buildconfigKeyword }
            .map { $0.range }
            .filter { range in
                return ["#if", "#endif"].contains(contents.substringWithByteRange(range))
            }

        // Make sure that each #if has corresponding #endif
        guard ranges.count % 2 == 0 else { return [] }

        return stride(from: 0, to: ranges.count, by: 2).reduce(into: []) { result, rangeIndex in
            result.append(ranges[rangeIndex].union(with: ranges[rangeIndex + 1]))
        }
    }

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let contents = file.stringView

        let ignoredRanges = self.rangesInConditionalCompilation(file: file)

        let importKinds = DuplicateImportsRule.importKinds.joined(separator: "|")

        // Grammar of import declaration
        // attributes(optional) import import-kind(optional) import-path
        let regex = "^(\\w\\s)?import(\\s(\(importKinds)))?\\s+[a-zA-Z0-9._]+$"
        let importRanges = file.match(pattern: regex)
            .filter { $0.1.allSatisfy { [.keyword, .identifier].contains($0) } }
            .compactMap { contents.NSRangeToByteRange(start: $0.0.location, length: $0.0.length) }
            .filter { importRange -> Bool in
                return !importRange.intersects(ignoredRanges)
            }

        let lines = file.lines

        let importLines: [Line] = importRanges.compactMap { range in
            guard let line = contents.lineAndCharacter(forByteOffset: range.location)?.line
                else { return nil }
            return lines[line - 1]
        }

        var violations = [StyleViolation]()

        for indexI in 0..<importLines.count {
            for indexJ in indexI + 1..<importLines.count {
                let firstLine = importLines[indexI]
                let secondLine = importLines[indexJ]

                guard firstLine.areImportsDuplicated(with: secondLine)
                    else { continue }

                let lineWithDuplicatedImport: Line = {
                    if firstLine.importIdentifier?.count ?? 0 <= secondLine.importIdentifier?.count ?? 0 {
                        return secondLine
                    } else {
                        return firstLine
                    }
                }()

                let location = Location(file: file, characterOffset: lineWithDuplicatedImport.range.location)
                let violation = StyleViolation(ruleDescription: type(of: self).description, location: location)
                violations.append(violation)
            }
        }

        return violations
    }
}

private extension Line {
    /// Returns name of the module being imported.
    var importIdentifier: Substring? {
        return self.content.split(separator: " ").last
    }

    func areImportsDuplicated(with otherLine: Line) -> Bool {
        guard let firstImportIdentifiers = self.importIdentifier?.split(separator: "."),
            let secondImportIdentifiers = otherLine.importIdentifier?.split(separator: ".")
            else { return false }

        return zip(firstImportIdentifiers, secondImportIdentifiers).allSatisfy { $0 == $1 }
    }
}
