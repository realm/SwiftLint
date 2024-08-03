import Foundation
import SourceKittenFramework

fileprivate extension Line {
    var contentRange: NSRange {
        NSRange(location: range.location, length: content.bridge().length)
    }

    // `Line` in this rule always contains word import
    // This method returns contents of line that are before import
    func importAttributes() -> String {
        content[importAttributesRange()].trimmingCharacters(in: .whitespaces)
    }

    // `Line` in this rule always contains word import
    // This method returns contents of line that are after import
    func importModule() -> Substring {
        content[importModuleRange()]
    }

    func importAttributesRange() -> Range<String.Index> {
        let rangeOfImport = content.range(of: "import")
        precondition(rangeOfImport != nil)
        return content.startIndex..<rangeOfImport!.lowerBound
    }

    func importModuleRange() -> Range<String.Index> {
        let rangeOfImport = content.range(of: "import")
        precondition(rangeOfImport != nil)
        let moduleStart = content.rangeOfCharacter(from: CharacterSet.whitespaces.inverted, options: [],
                                                   range: rangeOfImport!.upperBound..<content.endIndex)
        return moduleStart!.lowerBound..<content.endIndex
    }
}

private extension Sequence where Element == Line {
    // Groups lines, so that lines that are one after the other
    // will end up in same group.
    func grouped() -> [[Line]] {
        reduce(into: [[]]) { result, line in
            guard let last = result.last?.last else {
                result = [[line]]
                return
            }

            if last.index == line.index - 1 {
                result[result.count - 1].append(line)
            } else {
                result.append([line])
            }
        }
    }
}

struct SortedImportsRule: CorrectableRule, OptInRule {
    var configuration = SortedImportsConfiguration()

    static let description = RuleDescription(
        identifier: "sorted_imports",
        name: "Sorted Imports",
        description: "Imports should be sorted",
        kind: .style,
        nonTriggeringExamples: SortedImportsRuleExamples.nonTriggeringExamples,
        triggeringExamples: SortedImportsRuleExamples.triggeringExamples,
        corrections: SortedImportsRuleExamples.corrections
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let groups = importGroups(in: file, filterEnabled: false)
        return violatingOffsets(inGroups: groups).map { index -> StyleViolation in
            let location = Location(file: file, characterOffset: index)
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: location)
        }
    }

    private func importGroups(in file: SwiftLintFile, filterEnabled: Bool) -> [[Line]] {
        var importRanges = file.match(pattern: "import\\s+\\w+", with: [.keyword, .identifier])
        if filterEnabled {
            importRanges = file.ruleEnabled(violatingRanges: importRanges, for: self)
        }

        let contents = file.stringView
        let lines = file.lines
        let importLines: [Line] = importRanges.compactMap { range in
            guard let line = contents.lineAndCharacter(forCharacterOffset: range.location)?.line
                else { return nil }
            return lines[line - 1]
        }

        return importLines.grouped()
    }

    private func violatingOffsets(inGroups groups: [[Line]]) -> [Int] {
        groups.flatMap { group in
            zip(group, group.dropFirst()).reduce(into: []) { violatingOffsets, groupPair in
                let (previous, current) = groupPair
                let isOrderedCorrectly = should(previous, comeBefore: current)
                if isOrderedCorrectly {
                    return
                }
                let distance = current.content.distance(from: current.content.startIndex,
                                                        to: current.importModuleRange().lowerBound)
                violatingOffsets.append(current.range.location + distance)
            }
        }
    }

    /// - returns: whether `lhs` should come before `rhs` based on a comparison of the contents of the import lines
    private func should(_ lhs: Line, comeBefore rhs: Line) -> Bool {
        switch configuration.grouping {
        case .attributes:
            let lhsAttributes = lhs.importAttributes()
            let rhsAttributes = rhs.importAttributes()
            if lhsAttributes != rhsAttributes {
                if lhsAttributes.isEmpty != rhsAttributes.isEmpty {
                    return rhsAttributes.isEmpty
                }
                return lhsAttributes < rhsAttributes
            }
        case .names:
            break
        }
        return lhs.importModule().lowercased() <= rhs.importModule().lowercased()
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let groups = importGroups(in: file, filterEnabled: true)

        let corrections = violatingOffsets(inGroups: groups).map { characterOffset -> Correction in
            let location = Location(file: file, characterOffset: characterOffset)
            return Correction(ruleDescription: Self.description, location: location)
        }

        guard corrections.isNotEmpty else {
            return []
        }

        let correctedContents = NSMutableString(string: file.contents)
        for group in groups.map({ $0.sorted(by: should(_:comeBefore:)) }) {
            guard let first = group.first?.contentRange else {
                continue
            }
            let result = group.map(\.content).joined(separator: "\n")
            let union = group.dropFirst().reduce(first) { result, line in
                NSUnionRange(result, line.contentRange)
            }
            correctedContents.replaceCharacters(in: union, with: result)
        }
        file.write(correctedContents.bridge())

        return corrections
    }
}
