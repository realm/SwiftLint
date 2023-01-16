import SwiftOperators
import SwiftSyntax

extension SourceFileSyntax {
    func folded() -> SourceFileSyntax? {
        OperatorTable.standardOperators
            .foldAll(self) { _ in }
            .as(SourceFileSyntax.self)
    }
}
