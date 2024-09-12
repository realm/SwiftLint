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
            Example("let result = success ? foo() : bar()"),
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
            func example() -> String {
                if true {
                    isTrue ? defaultValue() : defaultValue()
                } else {
                    "Default"
                }
            }
            """),
            Example("""
            func exampleNestedIfExpr() -> String {
                if true {
                  isTrue ? defaultValue() : defaultValue()
                } else {
                    "Default"
                }
            }
            """),
            Example("""
            func exampleNestedIfExpr() -> String {
                test()
                if true {
                  isTrue ? defaultValue() : defaultValue()
                } else {
                    "Default"
                }
            }
            """),
            Example("""
            func collectionView() -> CGSize {
                switch indexPath.section {
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
            Example("""
            func example() -> Void {
                if true {
                    isTrue ↓? defaultValue() : defaultValue()
                } else {
                    print("false")
                }
            }
            """),
            Example("""
            func exampleNestedIfExpr() -> String {
                if true {
                  isTrue ↓? defaultValue() : defaultValue()
                } else {
                    "Default"
                }
                return hoge
            }
            """),
            Example("""
            func collectionView() -> CGSize {
                switch indexPath.section {
                case 0: isEditing ↓? CGSize(width: 150, height: 20) : CGSize(width: 100, height: 20)
                default: .zero
                }
                return hoge
            }
            """),
            Example("""
            func exampleNestedIfExpr() -> String {
                if true {
                  if true {
                    isTrue ↓? defaultValue() : defaultValue()
                  } else {
                    return "False"
                  }
                } else {
                  return "Default"
                }
                return hoge
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
        children(viewMode: .sourceAccurate).contains(where: { $0.is(AssignmentExprSyntax.self) })
    }
}

private extension CodeBlockItemSyntax {
    var isImplicitReturn: Bool {
        isClosureImplictReturn || isFunctionImplicitReturn ||
        isVariableImplicitReturn || isSubscriptImplicitReturn ||
        isAcessorImplicitReturn || isIfExprImplicitReturn || isSwitchExprImplicitReturn
    }

    var isClosureImplictReturn: Bool {
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

    var isAcessorImplicitReturn: Bool {
        guard let parent = parent?.as(CodeBlockItemListSyntax.self),
              parent.parent?.parent?.as(AccessorDeclSyntax.self) != nil else {
            return false
        }

        return parent.children(viewMode: .sourceAccurate).count == 1
    }

    func getFunctionDeclSyntax(parent: CodeBlockItemListSyntax) -> FunctionDeclSyntax? {
      let targetSyntax = parent.parent?.parent
      if let targetSyntax = targetSyntax?.as(FunctionDeclSyntax.self) {
        return targetSyntax
      }
      if let ifExprSyntax = targetSyntax?.as(IfExprSyntax.self) {
        guard let codeBlockItemListSyntax = ifExprSyntax.parent?.parent?.parent?.as(CodeBlockItemListSyntax.self) else {
          return nil
        }
        return getFunctionDeclSyntax(parent: codeBlockItemListSyntax)
      }
      if let switchExpr = targetSyntax?.parent?.as(SwitchExprSyntax.self) {
        guard let codeBlockItemListSyntax = switchExpr.parent?.parent?.parent?.as(CodeBlockItemListSyntax.self) else {
          return nil
        }
        return getFunctionDeclSyntax(parent: codeBlockItemListSyntax)
      }
      return nil
    }

    var isIfExprImplicitReturn: Bool {
      guard let parent = parent?.as(CodeBlockItemListSyntax.self) else { return false }
      guard let result = getFunctionDeclSyntax(parent: parent) else { return false }
      if let codeBlockItemListSyntax = result.body?.statements,
         let expressionStmtSyntax = codeBlockItemListSyntax.last?.item.as(ExpressionStmtSyntax.self) {
        return parent.children(viewMode: .sourceAccurate).count == 1 &&
        ( codeBlockItemListSyntax.count == 1 || expressionStmtSyntax.expression.is(IfExprSyntax.self)) &&
        result.signature.allowsImplicitReturns
      }
      return false
    }

    var isSwitchExprImplicitReturn: Bool {
      guard let parent = parent?.as(CodeBlockItemListSyntax.self),
            let switchExprSytax = parent.parent?.parent?.parent?.as(SwitchExprSyntax.self) else {
        return false
      }
      guard let funcDecl = switchExprSytax.parent?.parent?.parent?.parent?.parent?.as(FunctionDeclSyntax.self) else {
        return false
      }
      return parent.children(viewMode: .sourceAccurate).count == 1 &&
      funcDecl.signature.allowsImplicitReturns &&
      switchExprSytax.parent?.parent?.parent?.as(CodeBlockItemListSyntax.self)?.count == 1
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
