import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct UnnestSwitchesUsingTupleRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unnest_switches_using_tuple",
        name: "Unnest Switches Using Tuple",
        description: "Prevent nesting switches by preferring a switch on a tuple",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                switch a {
                  case 1:
                    switch b {
                    case 1:
                      break
                    case 2:
                      break
                    }
                  case 2:
                    let b = 5
                    switch b {
                    case 1:
                      break
                    case 2:
                      break
                    }
                }
            """),
            Example("""
                switch a {
                  case 1:
                    if (d) {
                        switch b {
                        case 1:
                          break
                        case 2:
                          break
                        }
                  }
                  case 2:
                    switch b {
                    case 1:
                      break
                    case 2:
                      break
                    }
                }
            """),
            Example("""
                switch (a, b) {
                case (1, 1):
                    break
                case (1, 2):
                    break
                case (2, 1):
                    break
                case (2, 2):
                    break
                }
            """),
            Example("""
                switch (a, b) {
                case (1, 1):
                    break
                case (1, 2):
                    break
                case (2, _):
                    break
                }
            """),
        ],
        triggeringExamples: [
            Example("""
                ↓switch a {
                  case 1:
                    switch b {
                    case 1:
                      break
                    case 2:
                      break
                    }
                  case 2:
                    switch b {
                    case 1:
                      break
                    case 2:
                      break
                    }
                }
            """),
            Example("""
                ↓switch a {
                  case 1:
                    switch b {
                    case 1:
                      break
                    case 2:
                      break
                    }
                  default:
                    switch b {
                    case 1:
                      break
                    case 2:
                      break
                    }
                }
            """),
        ]
    )
}

private extension UnnestSwitchesUsingTupleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SwitchExprSyntax) {
            guard let nestingSwitch = self.switchNestedSwitches[node] else {
                // does this switch have a parent switch?
                guard let parentSwitchExpr = node.firstParent(ofType: SwitchExprSyntax.self) else {
                    return
                }
                // file this node, which is a nested switch, under its parent
                self.switchNestedSwitches[parentSwitchExpr, default: []].append(node)
                return
            }
            // check the parent switch
            defer { self.switchNestedSwitches = [:] }
            guard !nestingSwitch.isEmpty else {
                return
            }

            // 1. We want only those nested switches that are in the
            //    scope of the case label
            let switchesWithDirectParent = nestingSwitch
                .filter { $0.isNestedSwitchCandidate() }
            guard switchesWithDirectParent.count == nestingSwitch.count else {
                return
            }

            // 2. We only want the nested switches without a local reference
            //    to the switch's decl expression, so the following is not
            //    triggering a violation:
            //
            //      let b = 1 // or a var
            //      switch (b) {
            //      }
            //
            let switchesWithoutLocalVarRefs = nestingSwitch
                .filter { !$0.hasDeclarationInLabelScope(for: $0.referencedVariable) }
            guard nestingSwitch.count == switchesWithoutLocalVarRefs.count else {
                return
            }

            // 3. The number of cases should be the same as the number
            //    of nested switches, so this will not trigger:
            //
            //    switch (...) {
            //    case <1>:
            //        switch <a> {
            //        }
            //    case <2>:
            //        // some other expressions
            //    }
            guard nestingSwitch.count == node.cases.count else {
                return
            }

            // 4. Check that each of the nested switches references the
            //    _same_ variable.
            let variables: Set<String> = nestingSwitch
                .compactMap { $0.referencedVariable }
                .reduce(into: [], { $0.insert($1) })
            guard variables.count == 1 else {
                return
            }

            self.violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        private var switchNestedSwitches: [SwitchExprSyntax: [SwitchExprSyntax]] = [:]
    }
}

private extension SwitchExprSyntax {
    func isNestedSwitchCandidate() -> Bool {
        // we're looking for a nested switch that has a specific
        // tree hierarchy: there should be a direct line to the
        // parent switch
        let parentTypesPath: [any SyntaxProtocol.Type] = [
            SwitchExprSyntax.self,
            SwitchCaseListSyntax.self,
            SwitchCaseSyntax.self,
            CodeBlockItemListSyntax.self,
            CodeBlockItemSyntax.self,
            ExpressionStmtSyntax.self,
        ].reversed()
        return self.isBackwardsTraversable(using: parentTypesPath)
    }

    func hasDeclarationInLabelScope(for variable: String?) -> Bool {
        guard let variable else {
            return false
        }
        guard let switchCaseSyntax = self.firstParent(ofType: SwitchCaseSyntax.self) else {
            return false
        }
        guard let switchCodeBlockItem = self.firstParent(ofType: CodeBlockItemSyntax.self) else {
            return false
        }
        let declReferencingVariable = switchCaseSyntax.statements
            .prefix { $0 != switchCodeBlockItem }
            .first { $0.containsReference(to: variable) }
        return declReferencingVariable != nil
    }

    var referencedVariable: String? {
        self.subject.as(DeclReferenceExprSyntax.self)?.baseName.text
    }
}

private extension SwitchCaseSyntax {
    func allStatements() -> [Syntax] {
        self.statements
            .map { Syntax($0.item) } as [Syntax]
    }

    func variableDeclReferencing(_ variable: String?) -> VariableDeclSyntax? {
        guard let variable else {
            return nil
        }
        let allStatements = self.allStatements()
        guard allStatements.isEmpty == false else {
            return nil
        }
        // 1 & 2: get all the variable decl up to the nested switch statement
        // 3: get the first one which references the variable
        return allStatements
            .prefix { $0.as(ExpressionStmtSyntax.self)?.expression.kind != .switchExpr }
            .compactMap { $0.as(VariableDeclSyntax.self) }
            .first { $0.references(variable) }
    }
}

private extension CodeBlockItemSyntax {
    func containsReference(to variable: String) -> Bool {
        guard self.item.kind == .variableDecl else {
            return false
        }
        guard let variableDecl = self.item.as(VariableDeclSyntax.self) else {
            return false
        }
        guard variableDecl.references(variable) else {
            return false
        }
        return true
    }
}

private extension VariableDeclSyntax {
    func references(_ variable: String) -> Bool {
        self.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == variable
    }
}

private extension SyntaxProtocol {
    func firstParent<T: SyntaxProtocol>(ofType type: T.Type) -> T? {
        var someParent = self.parent
        while let current = someParent, current.as(type.self) == nil {
            someParent = current.parent
        }
        return someParent?.as(type.self)
    }

    func isBackwardsTraversable(using path: [any SyntaxProtocol.Type]?) -> Bool {
        guard let path else {
            return false
        }
        let mySelf: (any SyntaxProtocol)? = self
        let parent = path.reduce(mySelf) { partialResult, parentType in
            partialResult?.parent?.as(parentType)
        }
        return parent != nil
    }
}
