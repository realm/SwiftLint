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
    var isVar: Bool {
        return self.bindingKeyword.tokenKind == .keyword(.var)
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

    func next<T: SyntaxProtocol>(after index: PatternBindingListSyntax.Index?, of type: T.Type) -> T? {
        guard let index = self.bindings.optionalIndex(after: index),
              index >= self.bindings.startIndex && index < self.bindings.endIndex else {
            return nil
        }
        return self.bindings[index].as(type)
    }

    func next(after: PatternBindingSyntax?) -> PatternBindingSyntax? {
        guard let after, let index = self.bindings.firstIndex(where: { patterBindingSyntax in
            return patterBindingSyntax == after
        }) else {
            return nil
        }
        let newIndex = self.bindings.index(after: index)
        guard newIndex >= self.bindings.startIndex && newIndex < self.bindings.endIndex else {
            return nil
        }
        return self.bindings[newIndex]
    }

    func firstOf<T: SyntaxProtocol>(_ type: T.Type) -> T? {
        return self.bindings.first { patternBinding in
            return patternBinding.as(type) != nil
        } as? T
    }

    func firstIndexOf<T: SyntaxProtocol>(_ type: T.Type) -> PatternBindingListSyntax.Index? {
        return self.bindings.firstIndex(where: { patternBinding in
            return patternBinding.as(type) != nil
        })
    }
}
