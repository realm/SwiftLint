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
            Example("""
                switch a {
                case 1: 
                    let b = something
                    switch b {
                    case 1:
                        break
                    case 2:
                        break
                    }
                case 2:
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
                case 2:
                    break
                }
            """),
            Example("""
                switch a {
                case 1: 
                    ↓switch b {
                    case 1:
                        switch c {
                        case 1:
                            break
                        }
                    case 2:
                        break
                    }
                case 2:
                    break
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
                guard let parent = node.firstParent(ofKind: .switchExpr),
                      let parentSwitchExpr = parent.as(SwitchExprSyntax.self) else {
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
            // we only want the nested switched without a local reference
            // to the switch's decl expression, so the following is
            // not triggering a violation:
            //
            //      let b = 1 // or a var
            //      switch (b) {
            //      }
            //
            let variables: Set<String> = nestingSwitch
                .filter { !$0.hasDeclarationInLabelScope(for: $0.referencedVariable) }
                .compactMap { $0.referencedVariable }
                .reduce(into: [], { p, e in p.insert(e) })
            
            // we want all nested switches to reference the same variable
            // to be able to unnest a switch using tuples
            guard variables.count == 1 else {
                // different variables referenced
                return
            }
            self.violations.append(node.positionAfterSkippingLeadingTrivia)
        }
        
        private var switchNestedSwitches: [SwitchExprSyntax: [SwitchExprSyntax]] = [:]
    }
}

private extension SwitchExprSyntax {
    
    func hasDeclarationInLabelScope(for variable: String?) -> Bool {
        guard let variable else {
            return false
        }
        guard let switchCaseSyntax = self.firstParent(ofKind: .switchCase)?.as(SwitchCaseSyntax.self) else {
            return false
        }
        guard let switchCodeBlockItem = self.firstParent(ofKind: .codeBlockItem)?.as(CodeBlockItemSyntax.self) else {
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

    func firstParent(ofKind type: SyntaxKind) -> Syntax? {
        var someParent: Syntax? = self.parent
        while let current = someParent, current.kind != type {
            someParent = current.parent
        }
        return someParent
    }
}
