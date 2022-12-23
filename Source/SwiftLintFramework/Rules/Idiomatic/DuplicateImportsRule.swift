import Foundation
import SourceKittenFramework

struct DuplicateImportsRule: ConfigurationProviderRule, CorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    // List of all possible import kinds
    static let importKinds = [
        "typealias", "struct", "class",
        "enum", "protocol", "let",
        "var", "func"
    ]

    init() {}

    static let description = RuleDescription(
        identifier: "duplicate_imports",
        name: "Duplicate Imports",
        description: "Imports should be unique",
        kind: .idiomatic,
        nonTriggeringExamples: DuplicateImportsRuleExamples.nonTriggeringExamples,
        triggeringExamples: DuplicateImportsRuleExamples.triggeringExamples,
        corrections: DuplicateImportsRuleExamples.corrections
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
        guard ranges.count.isMultiple(of: 2) else { return [] }

        return stride(from: 0, to: ranges.count, by: 2).reduce(into: []) { result, rangeIndex in
            result.append(ranges[rangeIndex].union(with: ranges[rangeIndex + 1]))
        }
    }

    private func buildImportLineSlicesByImportSubpath(
        importLines: [Line]
    ) -> [ImportSubpath: [ImportLineSlice]] {
        var importLineSlices = [ImportSubpath: [ImportLineSlice]]()

        importLines.forEach { importLine in
            importLine.importSlices.forEach { slice in
                importLineSlices[slice.subpath, default: []].append(
                    ImportLineSlice(
                        slice: slice,
                        line: importLine
                    )
                )
            }
        }

        return importLineSlices
    }

    private func findDuplicateImports(
        file: SwiftLintFile,
        importLineSlicesGroupedBySubpath: [[ImportLineSlice]]
    ) -> [DuplicateImport] {
        typealias ImportLocation = Int

        var duplicateImportsByLocation = [ImportLocation: DuplicateImport]()

        importLineSlicesGroupedBySubpath.forEach { linesImportingSubpath in
            guard linesImportingSubpath.count > 1 else { return }
            guard let primaryImportIndex = linesImportingSubpath.firstIndex(where: {
                $0.slice.type == .complete
            }) else { return }

            linesImportingSubpath.enumerated().forEach { index, importedLine in
                guard index != primaryImportIndex else { return }
                let location = Location(
                    file: file,
                    characterOffset: importedLine.line.range.location
                )
                duplicateImportsByLocation[importedLine.line.range.location] = DuplicateImport(
                    location: location,
                    range: importedLine.line.range
                )
            }
        }

        return Array(duplicateImportsByLocation.values)
    }

    private struct DuplicateImport {
        let location: Location
        var range: NSRange
    }

    private func duplicateImports(file: SwiftLintFile) -> [DuplicateImport] {
        let contents = file.stringView

        let ignoredRanges = self.rangesInConditionalCompilation(file: file)

        let importKinds = Self.importKinds.joined(separator: "|")

        // Grammar of import declaration
        // attributes(optional) import import-kind(optional) import-path
        let regex = "^([a-zA-Z@_]+\\s)?import(\\s(\(importKinds)))?\\s+[a-zA-Z0-9._]+$"
        let importRanges = file.match(pattern: regex)
            .filter { $0.1.allSatisfy { [.keyword, .identifier, .attributeBuiltin].contains($0) } }
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

        let importLineSlices = buildImportLineSlicesByImportSubpath(importLines: importLines)

        let duplicateImports = findDuplicateImports(
            file: file,
            importLineSlicesGroupedBySubpath: Array(importLineSlices.values)
        )

        return duplicateImports.sorted(by: {
            $0.range.lowerBound < $1.range.lowerBound
        })
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return duplicateImports(file: file).map { duplicateImport in
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: duplicateImport.location
            )
        }
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let duplicateImports = duplicateImports(file: file).reversed().filter {
            file.ruleEnabled(violatingRange: $0.range, for: self) != nil
        }

        let violatingRanges = duplicateImports.map(\.range)
        let correctedFileContents = violatingRanges.reduce(file.stringView.nsString) { contents, range in
            contents.replacingCharacters(
                in: range,
                with: ""
            ).bridge()
        }

        file.write(correctedFileContents.bridge())

        return duplicateImports.map { duplicateImport in
            Correction(
                ruleDescription: Self.description,
                location: duplicateImport.location
            )
        }
    }
}

private typealias ImportSubpath = ArraySlice<String>

private struct ImportSlice {
    enum ImportSliceType {
        /// For "import A.B.C" parent subpaths are ["A", "B"] and ["A"]
        case parent

        /// For "import A.B.C" complete subpath is ["A", "B", "C"]
        case complete
    }

    let subpath: ImportSubpath
    let type: ImportSliceType
}

private struct ImportLineSlice {
    let slice: ImportSlice
    let line: Line
}

private extension Line {
    /// Returns name of the module being imported.
    var importIdentifier: Substring? {
        return self.content.split(separator: " ").last
    }

    /// For "import A.B.C" returns slices [["A", "B", "C"], ["A", "B"], ["A"]]
    var importSlices: [ImportSlice] {
        guard let importIdentifier = importIdentifier else { return [] }

        let importedSubpathParts = importIdentifier.split(separator: ".").map { String($0) }
        guard !importedSubpathParts.isEmpty else { return [] }

        return [
            ImportSlice(
                subpath: importedSubpathParts[0..<importedSubpathParts.count],
                type: .complete
            )
        ] + (1..<importedSubpathParts.count).map {
            ImportSlice(
                subpath: importedSubpathParts[0..<importedSubpathParts.count - $0],
                type: .parent
            )
        }
    }
}
