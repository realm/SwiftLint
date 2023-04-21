import SwiftSyntax

struct TypeMemberOrderRule: ConfigurationProviderRule, OptInRule, SwiftSyntaxRule {
    var configuration = TypeMemberOrderConfiguration()

    static let description = RuleDescription(
        identifier: "type_member_order",
        name: "Type Member Order",
        description: "Enforces that members (e.g. properties, methods) are in alphabetical order within a type.",
        kind: .style,
        nonTriggeringExamples: TypeMemberOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: TypeMemberOrderRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate, configuration: configuration)
    }
}

private extension TypeMemberOrderRule {
    struct TypeState {
        let declaration: DeclSyntaxProtocol?
        var lastIdentifier: (type: DeclarationType, name: String)?
    }

    final class Visitor: ViolationsSyntaxVisitor {
        var states: [TypeState] = [TypeState(declaration: nil, lastIdentifier: nil)]
        let configuration: TypeMemberOrderConfiguration

        init(viewMode: SyntaxTreeViewMode, configuration: TypeMemberOrderConfiguration) {
            self.configuration = configuration
            super.init(viewMode: viewMode)
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            states.append(TypeState(declaration: node, lastIdentifier: nil))
            return .visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            states.append(TypeState(declaration: node, lastIdentifier: nil))
            return .visitChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            states.append(TypeState(declaration: node, lastIdentifier: nil))
            return .visitChildren
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            states.append(TypeState(declaration: node, lastIdentifier: nil))
            return .visitChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            states.append(TypeState(declaration: node, lastIdentifier: nil))
            return .visitChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            states.append(TypeState(declaration: node, lastIdentifier: nil))
            return .visitChildren
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.leadingTrivia.hasMark == true {
                states[states.count - 1].lastIdentifier = nil
            }
            return .visitChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if configuration.separateByMarks, node.leadingTrivia.hasMark {
                states[states.count - 1].lastIdentifier = nil
            }
            return .visitChildren
        }

        override func visitPost(_ node: IdentifierPatternSyntax) {
            guard let variableType = node.declarationType else { return }

            let identifier = normalizedIdentifier(for: node)
            if let lastIdentifier = states.last?.lastIdentifier,
               identifier < lastIdentifier.name,
               variableType != .localVariable {
                if variableType == lastIdentifier.type || !configuration.separateByMemberTypes {
                    violations.append(
                        ReasonedRuleViolation(
                            position: node.identifier.position,
                            reason: "\(node.identifier.text) should be before \(lastIdentifier.name)"))
                }
            }
            states[states.count - 1].lastIdentifier = (type: variableType, name: identifier)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let lastIdentifier = states.last?.lastIdentifier, node.resolvedName() < lastIdentifier.name {
                if node.declarationType == lastIdentifier.type || !configuration.separateByMemberTypes {
                    violations.append(ReasonedRuleViolation(
                        position: node.identifier.position,
                        reason: "\(node.resolvedName()) should be before \(lastIdentifier.name)"))
                }
            }
            states[states.count - 1].lastIdentifier = (type: node.declarationType, name: node.resolvedName())
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            states.removeLast()
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            states.removeLast()
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            states.removeLast()
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            states.removeLast()
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            states.removeLast()
        }

        override func visitPost(_ node: StructDeclSyntax) {
            states.removeLast()
        }

        /// Get the name of the identifier for an `IdentifierPatternSyntax`, removing any
        /// extra backticks used to quote reserved words.
        ///
        /// - Parameter identifier: The `IdentifierPatternSyntax` for the identifier
        /// - Returns: The identifier with backticks removed, or the original identifier
        ///
        private func normalizedIdentifier(for identifier: IdentifierPatternSyntax) -> String {
            let text = identifier.identifier.text
            if text.hasPrefix("`") && text.hasSuffix("`") {
                return String(text[text.index(after: text.startIndex)...text.index(before: text.endIndex)])
            } else {
                return text
            }
        }
    }
}

private enum DeclarationType {
    case instanceVariable
    case localVariable
    case typeVariable
    case instanceMethod
    case typeMethod
    case function
}

private extension IdentifierPatternSyntax {
    var declarationType: DeclarationType? {
        guard let variableDeclaration, let parent = variableDeclaration.parent else {
            return nil
        }
        if parent.is(MemberDeclListItemSyntax.self) {
            if variableDeclaration.isInstanceVariable {
                return .instanceVariable
            } else {
                return .typeVariable
            }
        } else if parent.is(CodeBlockItemSyntax.self) {
            return .localVariable
        }
        return nil
    }

    // If an identifier is part of a variable declaration, it should have this structure:
    // VariableDecl -> PatternBindingList -> PatternBinding -> IdentifierPattern
    var variableDeclaration: VariableDeclSyntax? {
        parent?.as(PatternBindingSyntax.self)?
            .parent?.as(PatternBindingListSyntax.self)?
            .parent?.as(VariableDeclSyntax.self)
    }
}

private extension FunctionDeclSyntax {
    var declarationType: DeclarationType {
        if parent?.is(MemberDeclListItemSyntax.self) == true {
            if modifiers.isClass || modifiers.isStatic {
                return .typeMethod
            } else {
                return .instanceMethod
            }
        } else {
            return .function
        }
    }
}

private extension Trivia {
    var hasMark: Bool {
        pieces.contains {
            if case .lineComment(let comment) = $0, comment.hasPrefix("// MARK:") {
                return true
            } else {
                return false
            }
        }
    }
}
