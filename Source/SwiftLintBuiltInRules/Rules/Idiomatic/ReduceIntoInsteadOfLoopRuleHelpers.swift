import SwiftSyntax

struct ReduceIntoInsteadOfLoopRuleHelpers { }

extension VariableDeclSyntax {
    /// Binding is a var: "`var` someVar = <...>"
    var isVar: Bool {
        self.bindingSpecifier.tokenKind == .keyword(.var)
    }

    var identifier: String? {
        guard let identifierPattern = self.firstPatternOf(IdentifierPatternSyntax.self),
              case .identifier(let name) = identifierPattern.identifier.tokenKind else {
            return nil
        }
        return name
    }

    /// Returns the first binding with a `pattern` of type
    /// `type`.
    func firstPatternOf<T: PatternSyntaxProtocol>(_ type: T.Type) -> T? {
        let result = self.bindings.first { patternBinding in
            patternBinding.pattern.as(type) != nil
        }
        return result?.pattern.as(type)
    }
}
