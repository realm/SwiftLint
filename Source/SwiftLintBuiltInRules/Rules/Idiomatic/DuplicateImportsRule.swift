import SwiftSyntax

// MARK: - Rule

struct DuplicateImportsRule: SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    // List of all possible import kinds
    static let importKinds = [
        "typealias", "struct", "class",
        "enum", "protocol", "let",
        "var", "func"
    ]

    static let description = RuleDescription(
        identifier: "duplicate_imports",
        name: "Duplicate Imports",
        description: "Imports should be unique",
        kind: .idiomatic,
        nonTriggeringExamples: DuplicateImportsRuleExamples.nonTriggeringExamples,
        triggeringExamples: DuplicateImportsRuleExamples.triggeringExamples,
        corrections: DuplicateImportsRuleExamples.corrections
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        file.duplicateImportsViolationPositions().map { position in
            StyleViolation(
                ruleDescription: Self.description,
                location: Location(file: file, position: position)
            )
        }
    }

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        queuedFatalError("Unreachable: `validate(file:)` will be used instead")
    }

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            importPositionsToRemove: file.duplicateImportsViolationPositions(),
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

// MARK: - Private

private final class ImportPathVisitor: SyntaxVisitor {
    var importPaths = [AbsolutePosition: [String]]()
    var sortedImportPaths: [(position: AbsolutePosition, path: [String])] {
        importPaths
            .sorted { $0.key < $1.key }
            .map { (position: $0, path: $1) }
    }

    override func visitPost(_ node: ImportDeclSyntax) {
        importPaths[node.positionAfterSkippingLeadingTrivia] = node.path.map(\.name.text)
    }
}

private final class IfConfigClauseVisitor: SyntaxVisitor {
    var ifConfigRanges = [ByteSourceRange]()

    override func visitPost(_ node: IfConfigClauseSyntax) {
        ifConfigRanges.append(node.totalByteRange)
    }
}

private struct ImportPathUsage: Hashable {
    struct HashableByteSourceRange: Hashable {
        let value: ByteSourceRange

        func hash(into hasher: inout Hasher) {
            hasher.combine(value.offset)
            hasher.combine(value.length)
        }
    }

    init(ifConfigRanges: [ByteSourceRange], path: [String]) {
        self.hashableIfConfigRanges = ifConfigRanges.map(HashableByteSourceRange.init)
        self.path = path
    }

    var ifConfigRanges: [ByteSourceRange] { hashableIfConfigRanges.map(\.value) }
    let hashableIfConfigRanges: [HashableByteSourceRange]
    let path: [String]
}

private extension SwiftLintFile {
    func duplicateImportsViolationPositions() -> [AbsolutePosition] {
        let importPaths = ImportPathVisitor(viewMode: .sourceAccurate)
            .walk(file: self, handler: \.sortedImportPaths)

        let ifConfigRanges = IfConfigClauseVisitor(viewMode: .sourceAccurate)
            .walk(file: self, handler: \.ifConfigRanges)

        func ranges(for position: AbsolutePosition) -> [ByteSourceRange] {
            let positionRange = ByteSourceRange(offset: position.utf8Offset, length: 0)
            return ifConfigRanges.filter { $0.intersectsOrTouches(positionRange) }
        }

        var violationPositions = Set<AbsolutePosition>()
        var seen = Set<ImportPathUsage>()

        // Exact matches
        for (position, path) in importPaths {
            let rangesForPosition = ranges(for: position)

            defer {
                seen.insert(
                    ImportPathUsage(ifConfigRanges: rangesForPosition, path: path)
                )
            }

            guard seen.map(\.path).contains(path) else {
                continue
            }

            let intersects = {
                let otherRangesForPosition = seen
                    .filter { $0.path == path }
                    .flatMap(\.ifConfigRanges)

                return rangesForPosition.contains(where: otherRangesForPosition.contains)
            }

            if rangesForPosition.isEmpty || intersects() {
                violationPositions.insert(position)
            }
        }

        // Partial matches
        for (position, path) in importPaths {
            let violation = importPaths.contains { other in
                let otherPath = other.path
                guard path.starts(with: otherPath), otherPath != path else { return false }
                let rangesForPosition = ranges(for: position)
                let otherRangesForPosition = ranges(for: other.position)
                let intersects = rangesForPosition.contains { range in
                    otherRangesForPosition.contains(range)
                }
                return intersects || rangesForPosition.isEmpty
            }
            if violation {
                violationPositions.insert(position)
            }
        }

        return violationPositions.sorted()
    }
}

private extension DuplicateImportsRule {
    final class Rewriter: ViolationsSyntaxRewriter {
        let importPositionsToRemove: [AbsolutePosition]

        init(
            importPositionsToRemove: [AbsolutePosition],
            locationConverter: SourceLocationConverter,
            disabledRegions: [SourceRange]
        ) {
            self.importPositionsToRemove = importPositionsToRemove
            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
            let itemsToRemove = node
                .enumerated()
                .filter { !$1.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) }
                .map { ($0, $1.item.positionAfterSkippingLeadingTrivia) }
                .filter { importPositionsToRemove.contains($1) }
                .map { (indexInParent: $0, absolutePosition: $1) }
            if itemsToRemove.isEmpty {
                return super.visit(node)
            }
            correctionPositions.append(contentsOf: itemsToRemove.map(\.absolutePosition))

            var copy = node
            for indexInParent in itemsToRemove.map(\.indexInParent).reversed() {
                let currentIndex = copy.index(copy.startIndex, offsetBy: indexInParent)
                let nextIndex = copy.index(after: currentIndex)
                // Preserve leading trivia by moving it to the next item
                if nextIndex < copy.endIndex {
                    copy[nextIndex].leadingTrivia = copy[currentIndex].leadingTrivia
                }
                copy.remove(at: currentIndex)
            }

            return super.visit(copy)
        }
    }
}
