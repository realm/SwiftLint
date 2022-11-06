import SwiftOperators
import SwiftSyntax

public extension SourceFileSyntax {
    func folded() -> SourceFileSyntax? {
        OperatorTable.standardOperators
            .foldAll(self) { _ in }
            .as(SourceFileSyntax.self)
    }
}
