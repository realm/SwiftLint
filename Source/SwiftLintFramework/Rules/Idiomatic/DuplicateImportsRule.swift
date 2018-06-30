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

    private func rangesInConditionalCompilation(file: File) -> [NSRange] {
        let start = "#if"
        let end = "#endif"
        let contents = file.contents.bridge()

        let ranges = file.syntaxMap.tokens
            .filter { token -> Bool in
                guard let kind = SyntaxKind(rawValue: token.type) else {
                    return false
                }
                return kind == .buildconfigKeyword
            }
            .map { NSRange(location: $0.offset, length: $0.length) }
            .filter { range in
                guard let keyword = contents.substringWithByteRange(start: range.location, length: range.length) else {
                    return false
                }
                return keyword == start || keyword == end
            }

        var result = [NSRange]()
        for index in 0..<ranges.count where index % 2 == 0 {
            let union = NSUnionRange(ranges[index], ranges[index + 1])
            result.append(union)
        }
        return result
    }

    public func validate(file: File) -> [StyleViolation] {
        let contents = file.contents.bridge()

        let ignoredRanges = self.rangesInConditionalCompilation(file: file)

        let importKinds = DuplicateImportsRule.importKinds.joined(separator: "|")

        // Grammar of import declaration
        // attributes(optional) import import-kind(optional) import-path
        let regex = "^(\\w\\s)?import(\\s(\(importKinds)))?\\s+[a-zA-Z0-9._]+$"
        let importRanges = file.match(pattern: regex)
            .filter { $0.1.allSatisfying { $0 == .keyword || $0 == .identifier } }
            .compactMap { contents.NSRangeToByteRange(start: $0.0.location, length: $0.0.length) }
            .filter { importRange -> Bool in
                return !importRange.intersects(ignoredRanges)
            }

        let lines = contents.lines()

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

private extension Array {
    /// Returns true if all elements in array satisfy condition.
    ///
    /// - Parameter condition: in form of closure that is called on each element in array.
    /// - Returns: true if all elements satisfy provided condition, otherwise false.
    func allSatisfying(condition: (Array.Element) -> Bool) -> Bool {
        return self.reduce(true) { (result: Bool, element: Array.Element) -> Bool in
            return result ? condition(element) : result
        }
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

        return zip(firstImportIdentifiers, secondImportIdentifiers).reduce(true) { result, sequences in
            return result && sequences.0 == sequences.1
        }
    }
}
