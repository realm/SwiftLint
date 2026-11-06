import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ImportsAtTopRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "imports_at_top",
        name: "Imports at Top",
        description: "Imports should appear at the beginning of the file",
        kind: .style,
        nonTriggeringExamples: #examples([
            """
            struct Foo {}
            """,
            """
            import Foundation
            import UIKit
            @testable import MyModule

            struct Foo {}
            """,
            """
            // File header comment

            import Foundation
            import UIKit

            struct Foo {}
            """,
            """
            #if canImport(UIKit)
            import UIKit
            #else
            import AppKit
            #endif

            import Foundation

            struct Foo {}
            """,
            """
            #if canImport(UIKit)
            #if DEBUG
            import UIKit
            #endif
            #endif

            import Foundation

            struct Foo {}
            """,
        ]),
        triggeringExamples: #examples([
            """
            import Foundation

            struct Foo {}

            ↓import UIKit
            """,
            """
            struct FooTests {}

            @testable ↓import MyModule
            """,
            """
            struct Foo {}

            #if canImport(UIKit)
            ↓import UIKit
            #else
            ↓import AppKit
            #endif
            """,
            """
            #if DEBUG
            struct DebugHelper {}

            ↓import Testing
            #endif
            """,
            """
            #if DEBUG
            struct DebugHelper {}

            #if canImport(UIKit)
            ↓import UIKit
            #endif
            #endif
            """,
        ])
    )
}

private extension ImportsAtTopRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: SourceFileSyntax) {
            var hasSeenNonImportItem = false
            checkImportPlacement(
                in: node.statements,
                hasSeenNonImportItem: &hasSeenNonImportItem
            )
        }

        private func checkImportPlacement(in statements: CodeBlockItemListSyntax, hasSeenNonImportItem: inout Bool) {
            for statement in statements {
                if let importDecl = statement.item.as(ImportDeclSyntax.self) {
                    if hasSeenNonImportItem {
                        violations.append(
                            importDecl.importKeyword.positionAfterSkippingLeadingTrivia
                        )
                    }
                    continue
                }

                if let ifConfig = statement.item.as(IfConfigDeclSyntax.self) {
                    checkImportPlacement(
                        in: ifConfig,
                        hasSeenNonImportItem: &hasSeenNonImportItem
                    )
                    continue
                }

                hasSeenNonImportItem = true
            }
        }

        private func checkImportPlacement(in ifConfig: IfConfigDeclSyntax, hasSeenNonImportItem: inout Bool) {
            let hadSeenNonImportItemBeforeIf = hasSeenNonImportItem
            var anyClauseHasSeenNonImportItem = false

            for clause in ifConfig.clauses {
                guard let statements = clause.elements?.as(CodeBlockItemListSyntax.self) else {
                    continue
                }

                var clauseHasSeenNonImportItem = hadSeenNonImportItemBeforeIf

                checkImportPlacement(
                    in: statements,
                    hasSeenNonImportItem: &clauseHasSeenNonImportItem
                )

                if clauseHasSeenNonImportItem {
                    anyClauseHasSeenNonImportItem = true
                }
            }
            hasSeenNonImportItem = hadSeenNonImportItemBeforeIf || anyClauseHasSeenNonImportItem
        }
    }
}
