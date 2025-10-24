import Foundation
import SourceKittenFramework
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct SortedImportsRule: Rule {
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
}

private extension SortedImportsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var imports = [Import]()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ImportDeclSyntax) {
            imports.append(
                Import.from(importDecl: node, grouping: configuration.grouping, locationConverter: locationConverter)
            )
        }

        override func visitPost(_: SourceFileSyntax) {
            // Group imports that are adjacent to each other.
            var importBlocks = [[Import]]()
            for `import` in imports {
                if let lastBlock = importBlocks.last, let lastImport = lastBlock.last {
                    if `import`.isDirectlyAfter(previous: lastImport, in: file) {
                        importBlocks[importBlocks.count - 1].append(`import`)
                    } else {
                        importBlocks.append([`import`])
                    }
                } else {
                    importBlocks.append([`import`])
                }
            }

            // For every block, check that the imports are sorted.
            for block in importBlocks {
                for (previous, current) in zip(block, block.dropFirst()) where previous > current {
                    violations.append(current.violationPosition)
                }
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
            var statements = rewrite(statements: node.statements)
            if numberOfCorrections == 0 {
                return super.visit(node)
            }
            if let leadingTrivia = statements.first?.leadingTrivia {
                statements[0] = statements[0].with(\.leadingTrivia, leadingTrivia.skippingLeadingNewline)
            }
            return super.visit(node.with(\.statements, CodeBlockItemListSyntax(statements)))
        }

        private func rewrite(statements: CodeBlockItemListSyntax) -> [CodeBlockItemSyntax] {
            var rewrittenStatements = [CodeBlockItemSyntax]()
            var imports = [Import]()

            for stmt in statements {
                if let importDecl = stmt.item.as(ImportDeclSyntax.self) {
                    if importDecl.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) {
                        rewrittenStatements.append(stmt)
                        continue
                    }
                    let `import` = Import.from(
                        importDecl: importDecl,
                        grouping: configuration.grouping,
                        locationConverter: locationConverter
                    )
                    if let lastImport = imports.last, !`import`.isDirectlyAfter(previous: lastImport, in: file) {
                        rewrittenStatements.append(contentsOf: sort(imports))
                        imports = [`import`]
                        continue
                    }
                    imports.append(`import`)
                } else if let ifConfigDecl = stmt.item.as(IfConfigDeclSyntax.self) {
                    // Recursively rewrite imports inside `#if` blocks.
                    let rewrittenClauses = ifConfigDecl.clauses.map { clause in
                        let rewrittenClause = clause.elements.map { elements in
                            let rewrittenElements = rewrite(statements: elements.as(CodeBlockItemListSyntax.self) ?? [])
                            return CodeBlockItemListSyntax(rewrittenElements)
                        }
                        return clause.with(\.elements, .statements(rewrittenClause ?? []))
                    }
                    let rewrittenIfConfig = ifConfigDecl.with(\.clauses, IfConfigClauseListSyntax(rewrittenClauses))
                    if !imports.isEmpty {
                        rewrittenStatements.append(contentsOf: sort(imports))
                        imports = []
                    }
                    rewrittenStatements.append(CodeBlockItemSyntax(item: .decl(DeclSyntax(rewrittenIfConfig))))
                } else {
                    rewrittenStatements.append(contentsOf: sort(imports))
                    imports = []
                    rewrittenStatements.append(stmt)
                }
            }
            rewrittenStatements.append(contentsOf: sort(imports))
            return rewrittenStatements
        }

        private func sort(_ imports: [Import]) -> [CodeBlockItemSyntax] {
            guard imports.count > 1, let firstImport = imports.first else {
                return imports.map(\.importDecl.asCodeBlockItem)
            }
            let leadingTrivia = firstImport.importDecl.leadingTrivia.splitBlocks
            if leadingTrivia.foundSplit {
                // Comment with extra newlines before first import.
                let firstImportWithoutComment = Import.from(
                    importDecl: firstImport.importDecl.with(\.leadingTrivia, leadingTrivia.second),
                    grouping: configuration.grouping,
                    locationConverter: locationConverter
                )
                let imports = [firstImportWithoutComment] + imports.dropFirst()
                let sorted = imports.sorted(by: { $0 < $1 })
                numberOfCorrections += imports.difference(from: sorted).count
                let first = sorted.first!.importDecl
                let firstWithTrivia = firstImportWithoutComment == sorted.first
                    ? first.with(\.leadingTrivia, firstImport.importDecl.leadingTrivia)
                    : first.with(\.leadingTrivia, leadingTrivia.first + first.leadingTrivia)
                return [firstWithTrivia.asCodeBlockItem] + sorted.dropFirst().map(\.importDecl.asCodeBlockItem)
            }
            let sorted = imports.sorted(by: { $0 < $1 })
            numberOfCorrections += imports.difference(from: sorted).count
            return sorted.map(\.importDecl.asCodeBlockItem)
        }
    }
}

private extension Trivia {
    var skippingLeadingNewline: Self {
        if pieces.onlyElement?.isNewline == true {
            Trivia(pieces: dropLast())
        } else if containsComments, pieces.first?.isNewline == true {
            Trivia(pieces: dropFirst())
        } else {
            self
        }
    }

    var splitBlocks: (first: Trivia, second: Trivia, foundSplit: Bool) {
        var leading = [TriviaPiece]()
        var trailing = [TriviaPiece]()
        var foundSplit = false

        for piece in pieces {
            if case let .newlines(count) = piece, count > 1 {
                leading.append(.newlines(count - 1))
                foundSplit = true
            } else if foundSplit {
                trailing.append(piece)
            } else {
                leading.append(piece)
            }
        }
        return (Trivia(pieces: leading), Trivia(pieces: trailing), foundSplit)
    }
}
private extension ImportDeclSyntax {
    var asCodeBlockItem: CodeBlockItemSyntax {
        let item = CodeBlockItemSyntax(item: .decl(DeclSyntax(self)))
        return leadingTrivia.pieces.first?.isNewline == true
            ? item
            : item.with(\.leadingTrivia, [.newlines(1)] + leadingTrivia)
    }
}

private struct Import: Comparable {
    let importDecl: ImportDeclSyntax
    let line: Int
    let offset: Int
    let attributes: String

    var violationPosition: AbsolutePosition {
        importDecl.path.positionAfterSkippingLeadingTrivia
    }

    var symbol: String {
        importDecl.path.map(\.name.text).joined(separator: ".")
    }

    static func from(importDecl: ImportDeclSyntax,
                     grouping: SortedImportsConfiguration.Grouping,
                     locationConverter: SourceLocationConverter) -> Self {
        let attributes: [String] =
            if grouping == .attributes {
                importDecl.attributes.compactMap {
                    $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                }
            } else {
                []
            }
        let startLine = locationConverter.location(for: importDecl.positionAfterSkippingLeadingTrivia).line
        return Self(
            importDecl: importDecl,
            line: startLine,
            offset: locationConverter.location(for: importDecl.path.endPositionBeforeTrailingTrivia).line - startLine,
            attributes: attributes.joined()
        )
    }

    func isDirectlyAfter(previous: Self, in file: SwiftLintFile) -> Bool {
        let lineAfterPrevious = previous.line + previous.offset + 1

        // Import is either directly after the previous import ...
        return lineAfterPrevious == line
            // ... or there are only comment lines between them.
            || file.commentLines.isSuperset(of: lineAfterPrevious..<line)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.attributes != rhs.attributes {
            if lhs.attributes.isEmpty {
                return false
            }
            return rhs.attributes.isEmpty || lhs.attributes < rhs.attributes
        }
        return lhs.symbol.caseInsensitiveCompare(rhs.symbol) == .orderedAscending
    }
}
