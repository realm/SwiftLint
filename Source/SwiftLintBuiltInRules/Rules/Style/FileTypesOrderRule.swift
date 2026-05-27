import Foundation
import SwiftSyntax

private typealias FileTypePosition = (fileType: FileTypesOrderConfiguration.FileType, position: AbsolutePosition)
private typealias NamedGroupDecl = any DeclGroupSyntax & NamedDeclSyntax

@SwiftSyntaxRule(optIn: true)
struct FileTypesOrderRule: Rule {
    var configuration = FileTypesOrderConfiguration()

    static let description = RuleDescription(
        identifier: "file_types_order",
        name: "File Types Order",
        description: "Specifies how the types within a file should be ordered.",
        kind: .style,
        nonTriggeringExamples: FileTypesOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: FileTypesOrderRuleExamples.triggeringExamples
    )
}

private extension FileTypesOrderRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: SourceFileSyntax) {
            let fileTypePositions = collectFileTypePositions(in: node)
            guard fileTypePositions.contains(where: { $0.fileType == .mainType }) else {
                return
            }

            let orderedFileTypePositions = fileTypePositions.sorted { lhs, rhs in
                lhs.position < rhs.position
            }

            var lastMatchingIndex = -1
            for expectedTypes in configuration.order {
                var potentialViolatingIndexes = [Int]()

                let startIndex = lastMatchingIndex + 1
                for index in startIndex..<orderedFileTypePositions.count {
                    let fileType = orderedFileTypePositions[index].fileType
                    if expectedTypes.contains(fileType) {
                        lastMatchingIndex = index
                    } else {
                        potentialViolatingIndexes.append(index)
                    }
                }

                let violatingIndexes = potentialViolatingIndexes.filter { $0 < lastMatchingIndex }
                for index in violatingIndexes {
                    let fileType = orderedFileTypePositions[index].fileType.rawValue
                    let expected = expectedTypes.map(\.rawValue).joined(separator: ",")
                    let article = ["a", "e", "i", "o", "u"].contains(fileType.substring(from: 0, length: 1))
                        ? "An"
                        : "A"
                    violations.append(.init(
                        position: orderedFileTypePositions[index].position,
                        reason: "\(article) '\(fileType)' should not be placed amongst the file type(s) '\(expected)'"
                    ))
                }
            }
        }

        private func collectFileTypePositions(in node: SourceFileSyntax) -> [FileTypePosition] {
            let declarations = declarations(in: node.statements)
            let fileName = file.path?.deletingPathExtension().lastPathComponent
            let mainTypeID = resolveMainTypeID(in: declarations, fileName: fileName)

            var fileTypePositions = [FileTypePosition]()
            for declaration in declarations {
                let position = declaration.introducer.positionAfterSkippingLeadingTrivia
                let fileTypePosition: FileTypePosition =
                    if declaration.is(ExtensionDeclSyntax.self) {
                        (fileType: .extension, position: position)
                    } else if mainTypeID == declaration.id {
                        (fileType: .mainType, position: position)
                    } else if declaration.inheritanceClause.contains(inheritedTypes: ["PreviewProvider"]) {
                        (fileType: .previewProvider, position: position)
                    } else if declaration.inheritanceClause.contains(inheritedTypes: ["LibraryContentProvider"]) {
                        (fileType: .libraryContentProvider, position: position)
                    } else {
                        (fileType: .supportingType, position: position)
                    }
                fileTypePositions.append(fileTypePosition)
            }
            return fileTypePositions
        }

        private func declarations(in statements: CodeBlockItemListSyntax) -> [NamedGroupDecl] {
            var collectedDeclarations = [NamedGroupDecl]()
            for statement in statements {
                guard let declaration = statement.item.asProtocol((any DeclGroupSyntax).self) else {
                    continue
                }
                if let ifConfig = declaration.as(IfConfigDeclSyntax.self) {
                    for clause in ifConfig.clauses {
                        let clauseStatements = clause.elements?.as(CodeBlockItemListSyntax.self) ?? []
                        collectedDeclarations.append(contentsOf: declarations(in: clauseStatements))
                    }
                    continue
                }
                if let namedDecl = declaration.asProtocol((any NamedDeclSyntax).self) as? NamedGroupDecl {
                    collectedDeclarations.append(namedDecl)
                }
            }
            return collectedDeclarations
        }

        private func resolveMainTypeID(in declarations: [NamedGroupDecl], fileName: String?) -> SyntaxIdentifier? {
            if let fileName,
               let matchingIdentifier = declarations.first(where: { $0.name.text == fileName })?.id {
                return matchingIdentifier
            }
            return declarations
                .compactMap(mainTypeCandidateInfo)
                .max(by: { lhs, rhs in lhs.bodyLength < rhs.bodyLength })?
                .id
        }

        private func mainTypeCandidateInfo(for decl: NamedGroupDecl) -> (id: SyntaxIdentifier, bodyLength: Int)? {
            if [.enumDecl, .classDecl, .structDecl].contains(decl.kind),
               !hasExcludedInheritedType(decl.inheritanceClause) {
                return (id: decl.id, bodyLength: bodyLength(of: decl.memberBlock))
            }
            return nil
        }

        private func hasExcludedInheritedType(_ inheritanceClause: InheritanceClauseSyntax?) -> Bool {
            inheritanceClause.contains(inheritedTypes: ["PreviewProvider", "LibraryContentProvider"])
        }

        private func bodyLength(of memberBlock: MemberBlockSyntax) -> Int {
            memberBlock.endPositionBeforeTrailingTrivia.utf8Offset
                - memberBlock.positionAfterSkippingLeadingTrivia.utf8Offset
        }
    }
}

extension ExtensionDeclSyntax: @retroactive NamedDeclSyntax {
    public var name: TokenSyntax {
        get {
            TokenSyntax(extendedGraphemeClusterLiteral: extendedType.trimmedDescription)
        }

        set {
            // swiftlint:disable:previous unused_setter_value
        }
    }
}
