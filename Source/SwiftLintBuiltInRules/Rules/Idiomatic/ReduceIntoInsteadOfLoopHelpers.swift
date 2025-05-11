import SwiftSyntax

struct ReduceIntoInsteadOfLoopHelpers { }

extension PatternBindingListSyntax {
    func optionalIndex(after: PatternBindingListSyntax.Index?) -> PatternBindingListSyntax.Index? {
        guard let after else {
            return nil
        }
        return self.index(after: after)
    }
}

extension VariableDeclSyntax {
    /// Binding is a var: "`var` someVar = <...>"
    var isVar: Bool {
        self.bindingSpecifier == .keyword(.var)
    }

    var identifier: String? {
        guard let identifierPattern = self.firstOf(IdentifierPatternSyntax.self),
              case .identifier(let name) = identifierPattern.identifier.tokenKind else {
            return nil
        }
        return name
    }

    func next(after index: PatternBindingListSyntax.Index?) -> PatternBindingSyntax? {
        guard let index = self.bindings.optionalIndex(after: index),
              index >= self.bindings.startIndex && index < self.bindings.endIndex else {
            return nil
        }
        return self.bindings[index]
    }

    func next(after: PatternBindingSyntax?) -> PatternBindingSyntax? {
        guard let after, let index = self.bindings.firstIndex(where: { patterBindingSyntax in
            patterBindingSyntax == after
        }) else {
            return nil
        }
        let newIndex = self.bindings.index(after: index)
        guard newIndex >= self.bindings.startIndex && newIndex < self.bindings.endIndex else {
            return nil
        }
        return self.bindings[newIndex]
    }

    func firstOf<T: PatternSyntaxProtocol>(_ type: T.Type) -> T? {
        self.bindings.first { patternBinding in
            patternBinding.pattern.as(type) != nil
        } as? T
    }

    func firstIndexOf<T: PatternSyntaxProtocol>(_ type: T.Type) -> PatternBindingListSyntax.Index? {
        self.bindings.firstIndex(where: { patternBinding in
            patternBinding.pattern.as(type) != nil
        })
    }
}
