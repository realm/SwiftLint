import SwiftSyntax

typealias ReferencedVariable = ReduceIntoInsteadOfLoop.ReferencedVariable
typealias CollectionType = ReduceIntoInsteadOfLoop.CollectionType

struct ReduceIntoInsteadOfLoop: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "reduce_into_instead_of_loop",
        name: "Reduce Into Instead Of Loop",
        description: "Prefer using reduce(into:) instead of a loop",
        kind: .idiomatic,
        nonTriggeringExamples: ReduceIntoInsteadOfLoopExamples.nonTriggeringExamples,
        triggeringExamples: ReduceIntoInsteadOfLoopExamples.triggeringExamples
    )

    init() {}

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

internal extension ReduceIntoInsteadOfLoop {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: CodeBlockItemListSyntax) {
            // reduce into forInStmts and variableDecls map
            guard let all = node.allVariableDeclsForInStatmts() else {
                return
            }
            // reduce variableDecls into the ones we're interested in
            let selected = all.reduce(into: [ForInStmtSyntax: [VariableDeclSyntax]]()) { partialResult, element in
                // we're interested fully type declared and implicitly declared by initializer
                let interestingVariableDecls = element.value.filter { variableDecl in
                    return variableDecl.isTypeAnnotatedAndInitializer
                        || variableDecl.isCollectionTypeInitializer
                }
                guard !interestingVariableDecls.isEmpty else {
                    return
                }
                partialResult[element.key] = interestingVariableDecls
            }
            guard !selected.isEmpty else {
                return
            }
            let referencedVars = selected.reduce(into: Set<ReferencedVariable>()) { partialResult, keyValue in
                let (forInStmt, variableDecls) = keyValue
                if let allReferencedVars = forInStmt.referencedVariables(for: variableDecls) {
                    partialResult.formUnion(allReferencedVars)
                }
            }
            guard !referencedVars.isEmpty else {
                return
            }
            self.violations.append(contentsOf: referencedVars.map { $0.position })
        }
    }

    static let collectionTypes: [CollectionType] = [
        CollectionType(name: "Set", genericArguments: 1),
        CollectionType(name: "Array", genericArguments: 1),
        CollectionType(name: "Dictionary", genericArguments: 2)
    ]

    static let collectionNames: [String: CollectionType] =
        ReduceIntoInsteadOfLoop.collectionTypes.reduce(into: [String: CollectionType]()) { partialResult, type in
            return partialResult[type.name] = type
        }
}

private extension CodeBlockItemListSyntax {
    /// Returns a dictionary with all VariableDecls preceding a ForInStmt, at the same scope level
    func allVariableDeclsForInStatmts() -> [ForInStmtSyntax: [VariableDeclSyntax]]? {
        typealias IndexRange = Range<Self.Index>
        typealias IndexRangeForStmts = (IndexRange, ForInStmtSyntax)
        typealias IndexRangeStmts = (IndexRange, CodeBlockItemSyntax)
        // collect all ForInStmts and track their index ranges
        let indexed: [IndexRangeForStmts] = self.reduce(into: [IndexRangeStmts]()) { partialResult, codeBlockItem in
            guard codeBlockItem.is(ForInStmtSyntax.self) else {
                return
            }
            // Not sure whether ForInStmtSyntax.index == CodeBlockItem.index
            guard let last = partialResult.last else {
                partialResult.append((self.startIndex..<codeBlockItem.index, codeBlockItem))
                return
            }
            let start = self.index(after: last.1.index)
            partialResult.append((start..<codeBlockItem.index, codeBlockItem))
        }.compactMap { element in
            let (range, codeBlockItem) = element
            guard let forInStmt = codeBlockItem.as(ForInStmtSyntax.self) else {
                return nil
            }
            return (range, forInStmt)
        }
        guard !indexed.isEmpty else {
            return nil
        }
        // only VariableDecls on same level of scope of the ForInStmt.
        let result = self.reduce(into: [ForInStmtSyntax: [VariableDeclSyntax]]()) { partialResult, codeBlockItem in
            guard let variableDecl = codeBlockItem.as(VariableDeclSyntax.self) else {
                return
            }
            guard let matchingForInStmt = indexed.first(where: { element in
                let (range, _) = element
                return range.contains(codeBlockItem.index)
            }) else {
                return
            }
            let (_, forInStmt) = matchingForInStmt
            let array = partialResult[forInStmt, default: []]
            partialResult[forInStmt] = array + [variableDecl]
        }
        return result.isEmpty ? nil : result
    }
}

private extension VariableDeclSyntax {
    /// Is type declared with initializer: `: Set<> = []`, `: Array<> = []`, or `: Dictionary<> = [:]`
    var isTypeAnnotatedAndInitializer: Bool {
        guard self.isVar && self.identifier != nil,
              let idIndex = self.firstIndexOf(IdentifierPatternSyntax.self) else {
            return false
        }
        //  Is type-annotated, and initialized?
        guard let typeAnnotationIndex = self.next(after: idIndex),
              let typeAnnotation = typeAnnotationIndex.as(TypeAnnotationSyntax.self),
              let type = typeAnnotation.collectionDeclarationType(),
              let initializerClause = self.next(after: typeAnnotationIndex)?.as(InitializerClauseSyntax.self) else {
            return false
        }
        return initializerClause.isTypeInitializer(for: type)
    }

    /// Is initialized with empty collection: `= Set<Int>(), = Array<Int>(), = Dictionary[:]`
    /// but a couple of more, see `InitializerClauseExprSyntax.isCollectionInitializer`
    var isCollectionTypeInitializer: Bool {
        guard self.isVar && self.identifier != nil,
              let idIndex = self.firstIndexOf(IdentifierPatternSyntax.self) else {
            return false
        }
        let initializerClause = self.next(after: idIndex, of: InitializerClauseSyntax.self)
        guard initializerClause?.isTypeInitializer() ?? false else {
            return false
        }
        return true
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

private extension TypeAnnotationSyntax {
    func collectionDeclarationType() -> CollectionType? {
        if let genericTypeName = self.genericCollectionDeclarationType() {
            return genericTypeName
        } else if let array = self.arrayDeclarationType() {
            return array
        } else if let dictionary = self.dictionaryDeclarationType() {
            return dictionary
        } else {
            return nil
        }
    }

    /// var x: Set<>, var x: Array<>, var x: Dictionary<>
    func genericCollectionDeclarationType() -> CollectionType? {
        guard let simpleTypeIdentifier = self.type.as(SimpleTypeIdentifierSyntax.self),
              let genericArgumentClause = simpleTypeIdentifier.genericArgumentClause,
              genericArgumentClause.leftAngleBracket.tokenKind == .leftAngle,
              genericArgumentClause.rightAngleBracket.tokenKind == .rightAngle,
              case .identifier(let name) = simpleTypeIdentifier.name.tokenKind,
              let collectionType = CollectionType.names[name],
              genericArgumentClause.arguments.count == collectionType.genericArguments else {
            return nil
        }
        return collectionType
    }

    /// var x: [Y]
    func arrayDeclarationType() -> CollectionType? {
        guard let arrayType = self.type.as(ArrayTypeSyntax.self),
              case .leftSquareBracket = arrayType.leftSquareBracket.tokenKind,
              case .rightSquareBracket = arrayType.rightSquareBracket.tokenKind,
              arrayType.elementType.kind == .simpleTypeIdentifier else {
            return nil
        }
        return .array
    }

    /// var x: [K: V]
    func dictionaryDeclarationType() -> CollectionType? {
        guard let dictionaryType = self.type.as(DictionaryTypeSyntax.self),
              case .leftSquareBracket = dictionaryType.leftSquareBracket.tokenKind,
              case .rightSquareBracket = dictionaryType.rightSquareBracket.tokenKind,
              case .colon = dictionaryType.colon.tokenKind else {
            return nil
        }
        return .dictionary
    }
}

private extension InitializerClauseSyntax {
    /// ---
    /// If `nil` we don't know the type and investigate the following, which is a`FunctionCallExpr`:
    ///     var x = Set<T>(...)
    ///     var y = Array<T>(...)
    ///     var z = Dictionary<K, V>(...)
    /// Otherwise checks for `FunctionCallExpr`,`MemberAccessExpr`,`DictionaryExpr` and `ArrayExpr`:
    /// 1. `= Set<T>(...)`  | `Set(...)`  |  `.init(...)`  |  `[]`
    /// 2. `= Array<T>(...)` | `Array(...)` | `.init(...)` | `[]`
    /// 3. `= Dictionary<K, V>()` | `Dictionary()` | `.init(..)` | `[:]`
    func isTypeInitializer(for collectionType: CollectionType? = nil) -> Bool {
        func isSupportedType(with name: String) -> Bool {
            if let collectionType {
                return collectionType.name == name
            } else {
                return CollectionType.names[name] != nil
            }
        }
        guard self.equal.tokenKind == .equal else { return false }
        if let functionCallExpr = self.value.as(FunctionCallExprSyntax.self) {
            // either construction using explicit specialisation, or general construction
            if let specializeExpr = functionCallExpr.calledExpression.as(SpecializeExprSyntax.self),
               let identifierExpr = specializeExpr.expression.as(IdentifierExprSyntax.self),
               case .identifier(let typename) = identifierExpr.identifier.tokenKind {
                return isSupportedType(with: typename)
            } else if let identifierExpr = functionCallExpr.calledExpression.as(IdentifierExprSyntax.self),
                      case .identifier(let typename) = identifierExpr.identifier.tokenKind {
                return isSupportedType(with: typename)
            } else if let memberAccessExpr = functionCallExpr.calledExpression.as(MemberAccessExprSyntax.self),
                      memberAccessExpr.name.tokenKind == .keyword(.`init`) {
                return true
            }
        } else if collectionType == .dictionary,
                  self.value.as(DictionaryExprSyntax.self) != nil {
            return true
        } else if collectionType == .array || collectionType == .set,
                  self.value.as(ArrayExprSyntax.self) != nil {
            return true
        }
        return false
    }
}

private extension ForInStmtSyntax {
    func referencedVariables(for variables: [VariableDeclSyntax]?) -> Set<ReferencedVariable>? {
        guard let variables, !variables.isEmpty,
              let codeBlock = self.body.as(CodeBlockSyntax.self),
              let codeBlockItemList = codeBlock.statements.as(CodeBlockItemListSyntax.self) else {
            return nil
        }
        let references: Set<ReferencedVariable> = codeBlockItemList.reduce(into: .init(), { partialResult, codeBlock in
            // no need to cover one liner: someMutation(); someOtherMutation()
            variables.forEach { variableDecl in
                if let referenced = codeBlock.referencedVariable(for: variableDecl) {
                    partialResult.insert(referenced)
                }
            }
        })
        return references.isEmpty ? nil : references
    }
}

private extension CodeBlockItemSyntax {
    func referencedVariable(for variableDecl: VariableDeclSyntax?) -> ReferencedVariable? {
        guard let identifier = variableDecl?.identifier else {
            return nil
        }
        return self.referencedVariable(for: identifier)
    }

    func referencedVariable(for varName: String) -> ReferencedVariable? {
        if let functionCallExpr = self.item.as(FunctionCallExprSyntax.self) {
            return functionCallExpr.referencedVariable(for: varName)
        }
        if let sequenceExpr = self.item.as(SequenceExprSyntax.self) {
            return sequenceExpr.referencedVariable(for: varName)
        }
        return nil
    }
}

private extension FunctionCallExprSyntax {
    /// varName.method(x, y, n)
    func referencedVariable(for varName: String) -> ReferencedVariable? {
        guard self.leftParen?.tokenKind == .leftParen,
              self.rightParen?.tokenKind == .rightParen,
              let memberAccessExpr = self.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccessExpr.dot.tokenKind == .period,
              let arguments = self.argumentList.as(TupleExprElementListSyntax.self)?.count,
              let identifierExpr = memberAccessExpr.base?.as(IdentifierExprSyntax.self),
              identifierExpr.identifier.tokenKind == .identifier(varName),
              case .identifier(let name) = memberAccessExpr.name.tokenKind else {
            return nil
        }
        return .init(
            name: varName,
            position: memberAccessExpr.positionAfterSkippingLeadingTrivia,
            kind: .method(name: name, arguments: arguments)
        )
    }
}

private extension SequenceExprSyntax {
    /// varName[xxx] = ...
    func referencedVariable(for varName: String) -> ReferencedVariable? {
        guard let exprList = self.as(ExprListSyntax.self), exprList.count >= 2 else {
            return nil
        }
        let first = exprList.startIndex
        let second = exprList.index(after: first)
        guard let subscrExpr = exprList[first].as(SubscriptExprSyntax.self),
              let assignmentExpr = exprList[second].as(AssignmentExprSyntax.self),
              assignmentExpr.assignToken.text == "=",
              subscrExpr.leftBracket.tokenKind == .leftSquareBracket,
              subscrExpr.rightBracket.tokenKind == .rightSquareBracket,
              subscrExpr.argumentList.is(TupleExprElementListSyntax.self),
              let identifierExpr = subscrExpr.calledExpression.as(IdentifierExprSyntax.self),
              identifierExpr.identifier.tokenKind == .identifier(varName) else {
            return nil
        }
        return .init(
            name: varName,
            position: exprList.positionAfterSkippingLeadingTrivia,
            kind: .assignment(subscript: true)
        )
    }
}

private extension PatternBindingListSyntax {
    func optionalIndex(after: PatternBindingListSyntax.Index?) -> PatternBindingListSyntax.Index? {
        guard let after else {
            return nil
        }
        return self.index(after: after)
    }
}

private extension VariableDeclSyntax {
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
}

