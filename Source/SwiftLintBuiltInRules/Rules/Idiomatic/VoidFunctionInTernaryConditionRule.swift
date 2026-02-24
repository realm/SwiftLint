import SwiftSyntax

@SwiftSyntaxRule
struct VoidFunctionInTernaryConditionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "void_function_in_ternary",
        name: "Void Function in Ternary",
        description: "Using ternary to call Void functions should be avoided",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("""
            if success {
                askQuestion()
            } else {
                exit()
            }
            """),
            Example("""
            var price: Double {
                return hasDiscount ? calculatePriceWithDiscount() : calculateRegularPrice()
            }
            """),
            Example("foo(x == 2 ? a() : b())"),
            Example("""
            chevronView.image = collapsed ? .icon(.mediumChevronDown) : .icon(.mediumChevronUp)
            """),
            Example("""
            array.map { elem in
                elem.isEmpty() ? .emptyValue() : .number(elem)
            }
            """),
            Example("""
            func compute(data: [Int]) -> Int {
                data.isEmpty ? 0 : expensiveComputation(data)
            }
            """),
            Example("""
            var value: Int {
                mode == .fast ? fastComputation() : expensiveComputation()
            }
            """),
            Example("""
            var value: Int {
                get {
                    mode == .fast ? fastComputation() : expensiveComputation()
                }
            }
            """),
            Example("""
            subscript(index: Int) -> Int {
                get {
                    index == 0 ? defaultValue() : compute(index)
                }
            """),
            Example("""
            subscript(index: Int) -> Int {
                index == 0 ? defaultValue() : compute(index)
            """),
            Example("""
            var a = b ? c() : d()
            a += b ? c() : d()
            a -= b ? c() : d()
            a *= b ? c() : d()
            a &<<= b ? c() : d()
            a &-= b ? c() : d()
            """),
            Example("""
            func makeValue() -> MyStruct {
                if condition {
                    flag ? MyStruct(value: 0) : MyStruct(value: 1)
                } else {
                    MyStruct(value: 2)
                }
            }
            """),
            Example("""
            func computeSize(for section: Int) -> CGSize {
                switch section {
                case 0: isEditing ? CGSize(width: 150, height: 20) : CGSize(width: 100, height: 20)
                default: .zero
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("success ↓? askQuestion() : exit()"),
            Example("""
            perform { elem in
                elem.isEmpty() ↓? .emptyValue() : .number(elem)
                return 1
            }
            """),
            Example("""
            DispatchQueue.main.async {
                self.sectionViewModels[section].collapsed.toggle()
                self.sectionViewModels[section].collapsed
                    ↓? self.tableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                    : self.tableView.insertRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                self.tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: section), at: .top, animated: true)
            }
            """),
            Example("""
            subscript(index: Int) -> Int {
                index == 0 ↓? something() : somethingElse(index)
                return index
            """),
            Example("""
            var value: Int {
                mode == .fast ↓? something() : somethingElse()
                return 0
            }
            """),
            Example("""
            var value: Int {
                get {
                    mode == .fast ↓? something() : somethingElse()
                    return 0
                }
            }
            """),
            Example("""
            subscript(index: Int) -> Int {
                get {
                    index == 0 ↓? something() : somethingElse(index)
                    return index
                }
            """),
        ]
    )
}

private extension VoidFunctionInTernaryConditionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TernaryExprSyntax) {
            guard node.thenExpression.is(FunctionCallExprSyntax.self),
                  node.elseExpression.is(FunctionCallExprSyntax.self),
                  let parent = node.parent?.as(ExprListSyntax.self),
                  !parent.containsAssignment,
                  let grandparent = parent.parent,
                  grandparent.is(SequenceExprSyntax.self),
                  let blockItem = grandparent.parent?.as(CodeBlockItemSyntax.self),
                  !blockItem.isImplicitReturn else {
                return
            }

            violations.append(node.questionMark.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: UnresolvedTernaryExprSyntax) {
            guard node.thenExpression.is(FunctionCallExprSyntax.self),
                  let parent = node.parent?.as(ExprListSyntax.self),
                  parent.last?.is(FunctionCallExprSyntax.self) == true,
                  !parent.containsAssignment,
                  let grandparent = parent.parent,
                  grandparent.is(SequenceExprSyntax.self),
                  let blockItem = grandparent.parent?.as(CodeBlockItemSyntax.self),
                  !blockItem.isImplicitReturn else {
                return
            }

            violations.append(node.questionMark.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ExprListSyntax {
    var containsAssignment: Bool {
        children(viewMode: .sourceAccurate).contains {
            if let binOp = $0.as(BinaryOperatorExprSyntax.self) {
                // https://developer.apple.com/documentation/swift/operator-declarations
                return [
                    "*=",
                    "/=",
                    "%=",
                    "+=",
                    "-=",
                    "<<=",
                    ">>=",
                    "&=",
                    "|=",
                    "^=",
                    "&*=",
                    "&+=",
                    "&-=",
                    "&<<=",
                    "&>>=",
                    ".&=",
                    ".|=",
                    ".^=",
                ].contains(binOp.operator.text)
            }
            return $0.is(AssignmentExprSyntax.self)
        }
    }
}

private extension CodeBlockItemSyntax {
    var isImplicitReturn: Bool {
        isClosureImplicitReturn || isFunctionImplicitReturn ||
        isVariableImplicitReturn || isSubscriptImplicitReturn ||
        isAccessorImplicitReturn || isIfExprOrSwitchExprImplicitReturn
    }

    var isClosureImplicitReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self),
              let grandparent = parent.parent else {
            return false
        }

        return parent.children(viewMode: .sourceAccurate).count == 1 && grandparent.is(ClosureExprSyntax.self)
    }

    var isFunctionImplicitReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self),
              let functionDecl = parent.parent?.parent?.as(FunctionDeclSyntax.self) else {
            return false
        }

        return parent.children(viewMode: .sourceAccurate).count == 1 && functionDecl.signature.allowsImplicitReturns
    }

    var isVariableImplicitReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self) else {
            return false
        }

        let isVariableDecl = parent.parent?.parent?.as(PatternBindingSyntax.self) != nil
        return parent.children(viewMode: .sourceAccurate).count == 1 && isVariableDecl
    }

    var isSubscriptImplicitReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self),
              let subscriptDecl = parent.parent?.parent?.as(SubscriptDeclSyntax.self) else {
            return false
        }

        return parent.children(viewMode: .sourceAccurate).count == 1 && subscriptDecl.allowsImplicitReturns
    }

    var isAccessorImplicitReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self),
              parent.parent?.parent?.as(AccessorDeclSyntax.self) != nil else {
            return false
        }

        return parent.children(viewMode: .sourceAccurate).count == 1
    }

    /// Returns `true` if this code block item is the sole expression in a branch of an `if` or
    /// `switch` expression that is itself used as an implicit return value. This prevents false
    /// positives when a ternary that returns a value appears inside an `if`/`switch` expression
    /// branch (Swift 5.9+) where the result of the branch is used as the enclosing expression's
    /// value.
    var isIfExprOrSwitchExprImplicitReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self),
              parent.children(viewMode: .sourceAccurate).count == 1 else {
            return false
        }

        // Check if inside an if expression branch (body or else body).
        // Chain: CodeBlockItemListSyntax -> CodeBlockSyntax -> IfExprSyntax
        if let ifExpr = parent.parent?.parent?.as(IfExprSyntax.self),
           let ifCodeBlockItem = ifExpr.parent?.as(CodeBlockItemSyntax.self) {
            return ifCodeBlockItem.isImplicitReturn
        }

        // Check if inside a switch expression case body.
        // Chain: CodeBlockItemListSyntax -> SwitchCaseSyntax -> SwitchCaseListSyntax -> SwitchExprSyntax
        if let switchExpr = parent.parent?.parent?.parent?.as(SwitchExprSyntax.self),
           let switchCodeBlockItem = switchExpr.parent?.as(CodeBlockItemSyntax.self) {
            return switchCodeBlockItem.isImplicitReturn
        }

        return false
    }
}

private extension FunctionSignatureSyntax {
    var allowsImplicitReturns: Bool {
        returnClause?.allowsImplicitReturns ?? false
    }
}

private extension SubscriptDeclSyntax {
    var allowsImplicitReturns: Bool {
        returnClause.allowsImplicitReturns
    }
}

private extension ReturnClauseSyntax {
    var allowsImplicitReturns: Bool {
        if let simpleType = type.as(IdentifierTypeSyntax.self) {
            return simpleType.name.text != "Void" && simpleType.name.text != "Never"
        }
        if let tupleType = type.as(TupleTypeSyntax.self) {
            return !tupleType.elements.isEmpty
        }
        return true
    }
}
