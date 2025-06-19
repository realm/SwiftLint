import SwiftSyntax

typealias ReferencedVariable = ReduceIntoInsteadOfLoopRule.ReferencedVariable
typealias CollectionType = ReduceIntoInsteadOfLoopRule.CollectionType

@SwiftSyntaxRule(optIn: true)
struct ReduceIntoInsteadOfLoopRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "reduce_into_instead_of_loop",
        name: "Reduce Into Instead Of Loop",
        description: "Prefer using `reduce(into:)` instead of mutating a sequence in a `for _ in ...` loop",
        kind: .idiomatic,
        nonTriggeringExamples: ReduceIntoInsteadOfLoopRuleExamples.nonTriggeringExamples,
        triggeringExamples: ReduceIntoInsteadOfLoopRuleExamples.triggeringExamples
    )
}

internal extension ReduceIntoInsteadOfLoopRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: CodeBlockItemListSyntax) {
            // Collect all varDecls in the same scope as forInStmts
            guard let all = node.allVariableDeclsForInStatmts() else {
                return
            }
            // Select those varDecls that have initialisers
            let selected = all.reduce(into: [ForStmtSyntax: [VariableDeclSyntax]]()) { partialResult, element in
                // we're interested fully type declared and implicitly declared by initializer
                let interestingVariableDecls = element.value.filter { variableDecl in
                    variableDecl.isTypeAnnotatedAndInitializer
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
            // Collect all varDecls that are referenced (and in our case possibly
            // mutate) in the forInStmt
            let referencedVars = selected.reduce(into: Set<ReferencedVariable>()) { partialResult, keyValue in
                let (forInStmt, variableDecls) = keyValue
                if let allReferencedVars = forInStmt.referencedVariables(for: variableDecls) {
                    partialResult.formUnion(allReferencedVars)
                }
            }
            guard !referencedVars.isEmpty else {
                return
            }
            // If there are referenced varDecls, then report violations
            self.violations.append(contentsOf: referencedVars.map { $0.position })
        }
    }

    static let collectionTypes: [CollectionType] = [
        CollectionType(name: "Set", genericArguments: 1),
        CollectionType(name: "Array", genericArguments: 1),
        CollectionType(name: "Dictionary", genericArguments: 2),
    ]

    static let collectionNames: [String: CollectionType] =
        ReduceIntoInsteadOfLoopRule.collectionTypes.reduce(into: [:]) { partialResult, type in
            partialResult[type.name] = type
        }
}

private extension CodeBlockItemListSyntax {
    /// Returns a dictionary with all VariableDecls preceding a ForInStmt, at the same scope level
    func allVariableDeclsForInStatmts() -> [ForStmtSyntax: [VariableDeclSyntax]]? {
        typealias IndexRange = Range<Self.Index>
        typealias IndexRangeForStmts = (range: IndexRange, forStmt: ForStmtSyntax)
        // Collect all ForInStmts and track their index ranges
        let indexRangeForStatements: [IndexRangeForStmts] = self.reduce(into: []) { partialResult, codeBlockItem in
            guard let codeBlockItemIndex = self.index(of: codeBlockItem) else {
                return
            }
            guard codeBlockItem.item.kind == .forStmt,
                  let forStmt = codeBlockItem.item.as(ForStmtSyntax.self),
                  forStmt.inKeyword.tokenKind == .keyword(.in) else {
                return
            }
            guard let lastEncountered = partialResult.last else {
                // First item encountered
                partialResult.append((range: self.startIndex..<codeBlockItemIndex, forStmt: forStmt))
                return
            }
            // Start where the lastEncountered ended
            let start = self.index(after: lastEncountered.range.upperBound)
            partialResult.append((range: start..<codeBlockItemIndex, forStmt: forStmt))
        }
        guard !indexRangeForStatements.isEmpty else {
            return nil
        }
        // Only VariableDecls on same level of scope of the ForInStmt.
        let result = self.reduce(into: [ForStmtSyntax: [VariableDeclSyntax]]()) { partialResult, codeBlockItem in
            guard let codeBlockItemIndex = self.index(of: codeBlockItem) else {
                return
            }
            guard let variableDecl = codeBlockItem.item.as(VariableDeclSyntax.self) else {
                return
            }
            guard let matchingForInStmt = indexRangeForStatements.first(where: { element in
                let (range, _) = element
                return range.contains(codeBlockItemIndex)
            }) else {
                return
            }
            let (_, forInStmt) = matchingForInStmt
            let array = partialResult[forInStmt, default: []]
            // Add variable declaration
            partialResult[forInStmt] = array + [variableDecl]
        }
        return result.isEmpty ? nil : result
    }
}

private extension VariableDeclSyntax {
    /// Is type declared with initializer: `: Set<> = []`, `: Array<> = []`, or `: Dictionary<> = [:]`
    var isTypeAnnotatedAndInitializer: Bool {
        guard self.isVar,
              self.identifier != nil,
              let identifierPatternSyntax = self.firstPatternOf(IdentifierPatternSyntax.self) else {
            return false
        }
        //  Is type-annotated, and initialized?
        guard let patternBindingSyntax = identifierPatternSyntax.parent?.as(PatternBindingSyntax.self),
              let typeAnnotation = patternBindingSyntax.typeAnnotation,
              let type = typeAnnotation.collectionDeclarationType,
              let initializerClause = patternBindingSyntax.initializer else {
            return false
        }
        return initializerClause.isTypeInitializer(for: type)
    }

    /// Is initialized with empty collection: `= Set<Int>(), = Array<Int>(), = Dictionary[:]`
    /// but a couple of more, see `InitializerClauseExprSyntax.isCollectionInitializer`
    var isCollectionTypeInitializer: Bool {
        guard self.isVar && self.identifier != nil else {
            return false
        }
        guard let initializerClausePatternBinding = self.bindings.first(where: { patternBindingSyntax in
            patternBindingSyntax.initializer != nil
        }) else {
            return false
        }
        guard let initializerClause = initializerClausePatternBinding.initializer else {
            return false
        }
        guard initializerClause.isTypeInitializer() else {
            return false
        }
        return true
    }
}

private extension TypeAnnotationSyntax {
    /// Returns one of the collection types we define
    var collectionDeclarationType: CollectionType? {
        if let genericTypeName = self.genericCollectionDeclarationType {
            return genericTypeName
        }
        if let array = self.arrayDeclarationType {
            return array
        }
        if let dictionary = self.dictionaryDeclarationType {
            return dictionary
        }
        return nil
    }

    /// var x: Set<>, var x: Array<>, var x: Dictionary<>
    var genericCollectionDeclarationType: CollectionType? {
        guard let simpleTypeIdentifier = self.type.as(IdentifierTypeSyntax.self),
              let genericArgumentClause = simpleTypeIdentifier.genericArgumentClause,
              genericArgumentClause.leftAngle.tokenKind == .leftAngle,
              genericArgumentClause.rightAngle.tokenKind == .rightAngle,
              case .identifier(let name) = simpleTypeIdentifier.name.tokenKind,
              let collectionType = CollectionType.names[name],
              genericArgumentClause.arguments.count == collectionType.genericArguments else {
            return nil
        }
        return collectionType
    }

    /// var x: [Y]
    var arrayDeclarationType: CollectionType? {
        guard let arrayType = self.type.as(ArrayTypeSyntax.self),
              case .leftSquare = arrayType.leftSquare.tokenKind,
              case .rightSquare = arrayType.rightSquare.tokenKind,
              arrayType.element.kind == .identifierType else {
            return nil
        }
        return .array
    }

    /// var x: [K: V]
    var dictionaryDeclarationType: CollectionType? {
        guard let dictionaryType = self.type.as(DictionaryTypeSyntax.self),
              case .leftSquare = dictionaryType.leftSquare.tokenKind,
              case .rightSquare = dictionaryType.rightSquare.tokenKind,
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
    ///     2b. `= [Type]()`
    /// 3. `= Dictionary<K, V>()` | `Dictionary()` | `.init(..)` | `[:]`
    func isTypeInitializer(for collectionType: CollectionType? = nil) -> Bool {
        func isSupportedType(with name: String) -> Bool {
            if let collectionType {
                return collectionType.name == name
            }
            return CollectionType.names[name] != nil
        }
        guard self.equal.tokenKind == .equal else { return false }
        if let functionCallExpr = self.value.as(FunctionCallExprSyntax.self) {
            // either construction using explicit specialisation, or general construction
            if let specializeExpr = functionCallExpr.calledExpression.as(GenericSpecializationExprSyntax.self),
               let identifierExpr = specializeExpr.expression.as(DeclReferenceExprSyntax.self),
               case .identifier(let typename) = identifierExpr.baseName.tokenKind {
                return isSupportedType(with: typename)
            }
            if let identifierExpr = functionCallExpr.calledExpression.as(DeclReferenceExprSyntax.self),
                      case .identifier(let typename) = identifierExpr.baseName.tokenKind {
                return isSupportedType(with: typename)
            }
            if let memberAccessExpr = functionCallExpr.calledExpression.as(MemberAccessExprSyntax.self),
                      memberAccessExpr.declName.baseName.tokenKind == .keyword(.`init`) {
                // found a collection initialisation expression of `.init()`
                // e.g. var array: [Int] = .init()
                return true
            }
            if let arrayExpr = functionCallExpr.calledExpression.as(ArrayExprSyntax.self),
               arrayExpr.elements.count == 1,
               arrayExpr.elements.first?.expression.is(DeclReferenceExprSyntax.self) == true {
                // found an array initialisation expression of `[type]`()
                // e.g. var array = [Int]()
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

private extension ForStmtSyntax {
    /// Checks whether any of the collection variables in scope are referenced
    /// in the forStmt.
    /// Note: When a varDecl is referenced, that's already a good trigger for
    /// the warning: detecting which functions are mutating is not possible,
    /// other than checking for a lhs-assignment. 
    func referencedVariables(for variables: [VariableDeclSyntax]?) -> Set<ReferencedVariable>? {
        guard let variables, !variables.isEmpty else {
            return nil
        }
        let codeBlockItemList = self.body.statements
        let references: Set<ReferencedVariable> = codeBlockItemList.reduce(into: [], { partialResult, codeBlock in
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
              memberAccessExpr.period.tokenKind == .period,
              let identifierExpr = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self),
              identifierExpr.baseName.tokenKind == .identifier(varName),
              case .identifier(let name) = memberAccessExpr.declName.baseName.tokenKind else {
            return nil
        }
        return ReferencedVariable(
            name: varName,
            position: memberAccessExpr.positionAfterSkippingLeadingTrivia,
            kind: .method(name: name, arguments: self.arguments.count)
        )
    }
}

private extension SequenceExprSyntax {
    /// Detect assignment expression:
    ///     varName[xxx] = ... // index
    ///     varName = ...
    func referencedVariable(for varName: String) -> ReferencedVariable? {
        let exprList = self.elements
        guard exprList.count >= 2 else {
            return nil
        }
        let firstExpr = exprList[exprList.startIndex]
        let secondExpr = exprList[exprList.index(after: exprList.startIndex)]
        guard let assignmentExpr = secondExpr.as(AssignmentExprSyntax.self),
              assignmentExpr.equal.tokenKind == .equal else {
            // no assignment expression
            return nil
        }
        if let subscrExpr = firstExpr.as(SubscriptCallExprSyntax.self),
           subscrExpr.leftSquare.tokenKind == .leftSquare,
           subscrExpr.rightSquare.tokenKind == .rightSquare,
           let identifierExpr = subscrExpr.calledExpression.as(DeclReferenceExprSyntax.self),
              identifierExpr.baseName.tokenKind == .identifier(varName) {
            return ReferencedVariable(
                name: varName,
                position: exprList.positionAfterSkippingLeadingTrivia,
                kind: .assignment(subscript: true)
            )
        }
        if let declExpr = firstExpr.as(DeclReferenceExprSyntax.self),
                  declExpr.baseName.tokenKind == .identifier(varName) {
            return ReferencedVariable(
                name: varName,
                position: exprList.positionAfterSkippingLeadingTrivia,
                kind: .assignment(subscript: false)
            )
        }
        return nil
    }
}
