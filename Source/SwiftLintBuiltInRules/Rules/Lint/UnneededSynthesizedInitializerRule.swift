import SwiftSyntax

struct UnneededSynthesizedInitializerRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "unneeded_synthesized_initializer",
        name: "Unneeded Synthesized Initializer",
        description: "This initializer would be synthesized automatically - you do not need to define it",
        kind: .lint,
        nonTriggeringExamples: UnneededSynthesizedInitializerRuleExamples.nonTriggering,
        triggeringExamples: UnneededSynthesizedInitializerRuleExamples.triggering
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        UnneededSynthesizedInitializerVisitor(viewMode: .sourceAccurate)
    }
}

private class UnneededSynthesizedInitializerVisitor: ViolationsSyntaxVisitor {
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let extraneousInitializers = extraneousInitializers(node)

        // The synthesized memberwise initializer(s) are only created when there are no initializers.
        // If there are other initializers that cannot be replaced by a synthesized memberwise
        // initializer, then all of the initializers must remain.
        let initializersCount = node.members.members.filter { $0.decl.is(InitializerDeclSyntax.self) }.count
        if extraneousInitializers.count == initializersCount {
            extraneousInitializers.forEach {
                violations.append($0.positionAfterSkippingLeadingTrivia)
            }
        }

        return .skipChildren
    }

    // Collects all of the initializers that could be replaced by the synthesized memberwise
    // initializer(s).
    private func extraneousInitializers(_ node: StructDeclSyntax) -> [InitializerDeclSyntax] {
        // swiftlint:disable:previous cyclomatic_complexity
        var storedProperties: [VariableDeclSyntax] = []
        var initializers: [InitializerDeclSyntax] = []

        for memberItem in node.members.members {
            let member = memberItem.decl
            // Collect all stored variables into a list
            if let varDecl = member.as(VariableDeclSyntax.self) {
                guard let modifiers = varDecl.modifiers else {
                    storedProperties.append(varDecl)
                    continue
                }
                guard !modifiers.isStatic else { continue }
                storedProperties.append(varDecl)
                // Collect any possible redundant initializers into a list
            } else if let initDecl = member.as(InitializerDeclSyntax.self) {
                 guard initDecl.optionalMark == nil else { continue }
                 guard initDecl.hasThrowsOrRethrowsKeyword == false else { continue }
                 initializers.append(initDecl)
            }
        }

        var extraneousInitializers = [InitializerDeclSyntax]()
        for initializer in initializers {
            guard
                matchesPropertyList(
                    intializerParameters: initializer.signature.input.parameterList,
                    storedProperties: storedProperties
                )
            else { continue }
            guard
                matchesAssignmentBody(initializerBody: initializer.body, storedProperties: storedProperties)
            else { continue }
            guard matchesAccessLevel(modifiers: initializer.modifiers, properties: storedProperties)
            else { continue }
            guard initializer.isInlinable == false else { continue }
            extraneousInitializers.append(initializer)
        }
        return extraneousInitializers
    }
    
    // Compares initializer parameters to stored properties of the struct
    private func matchesPropertyList(
        intializerParameters: FunctionParameterListSyntax,
        storedProperties: [VariableDeclSyntax]
    ) -> Bool {
        guard intializerParameters.count == storedProperties.count else { return false }
        for (idx, parameter) in intializerParameters.enumerated() {
            guard let paramId = parameter.firstName, parameter.secondName == nil else { return false }
            guard let paramType = parameter.type else { return false }

            let property = storedProperties[idx]
            let propertyId = property.firstIdentifier
            guard let propertyType = property.bindings.first?.typeAnnotation?.type else { return false }

            // Ensure that parameters that correspond to properties declared using 'var' have a default
            // argument that is identical to the property's default value. Otherwise, a default argument
            // doesn't match the memberwise initializer.
            let isVarDecl = property.letOrVarKeyword.tokenKind == .keyword(.var)
            if isVarDecl, let initializer = property.bindings.first?.initializer {
                guard let defaultArg = parameter.defaultArgument else { return false }
                guard initializer.value.description == defaultArg.value.description else { return false }
            } else if parameter.defaultArgument != nil {
                return false
            }

            if
                propertyId.identifier.text != paramId.text
                    || propertyType.description.trimmingCharacters(in: .whitespaces) !=
                    paramType.description.trimmingCharacters(in: .whitespacesAndNewlines)
            {
                return false
            }
        }
        return true
    }

    // Evaluates if all, and only, the stored properties are initialized in the body
    private func matchesAssignmentBody( // swiftlint:disable:this cyclomatic_complexity
        initializerBody: CodeBlockSyntax?,
        storedProperties: [VariableDeclSyntax]
    ) -> Bool {
        guard let initializerBody else { return false }
        guard storedProperties.count == initializerBody.statements.count else { return false }

        var statements: [String] = []
        for statement in initializerBody.statements {
            guard let exp = statement.item.as(SequenceExprSyntax.self) else { return false }
            var leftName = ""
            var rightName = ""

            for element in exp.elements {
                switch Syntax(element).as(SyntaxEnum.self) {
                case .memberAccessExpr(let element):
                    guard let base = element.base,
                          base.description.trimmingCharacters(in: .whitespacesAndNewlines) == "self"
                    else {
                        return false
                    }
                    leftName = element.name.text
                case .assignmentExpr(let element):
                    guard element.assignToken.tokenKind == .equal else { return false }
                case .identifierExpr(let element):
                    rightName = element.identifier.text
                default:
                    return false
                }
            }
            guard leftName == rightName else { return false }
            statements.append(leftName)
        }

        for variable in storedProperties {
            let id = variable.firstIdentifier.identifier.text
            guard statements.contains(id) else { return false }
            guard let idx = statements.firstIndex(of: id) else { return false }
            statements.remove(at: idx)
        }
        return statements.isEmpty
    }

    /// Compares the actual access level of an initializer with the access level of a synthesized
    /// memberwise initializer.
    private func matchesAccessLevel(modifiers: ModifierListSyntax?, properties: [VariableDeclSyntax]) -> Bool {
        let synthesizedAccessLevel = synthesizedInitAccessLevel(using: properties)
        let accessLevel = modifiers?.accessLevelModifier
        switch synthesizedAccessLevel {
        case .internal:
            // No explicit access level or internal are equivalent.
            return accessLevel == nil || accessLevel!.name.tokenKind == .keyword(.internal)
        case .fileprivate:
            return accessLevel != nil && accessLevel!.name.tokenKind == .keyword(.fileprivate)
        case .private:
            return accessLevel != nil && accessLevel!.name.tokenKind == .keyword(.private)
        }
    }
}

private extension ModifierListSyntax {
    var isStatic: Bool {
        contains(tokenKind: .keyword(.static))
    }

    /// Returns the declaration's access level modifier, if present.
    var accessLevelModifier: DeclModifierSyntax? {
        for modifier in self {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.private), .keyword(.fileprivate), .keyword(.internal):
                return modifier
            default:
                continue
            }
        }
        return nil
    }

    private func contains(tokenKind: TokenKind) -> Bool {
        contains { $0.name.tokenKind == tokenKind }
    }
}

private extension InitializerDeclSyntax {
    var hasThrowsOrRethrowsKeyword: Bool { signature.effectSpecifiers?.throwsSpecifier != nil }
    var isInlinable: Bool { attributes.contains(attributeNamed: "inlinable") }
}

private extension VariableDeclSyntax {
    var identifiers: [IdentifierPatternSyntax] {
        var ids: [IdentifierPatternSyntax] = []
        for binding in bindings {
            guard let id = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            ids.append(id)
        }
        return ids
    }

    var firstIdentifier: IdentifierPatternSyntax {
        identifiers[0]
    }
}

/// Defines the access levels which may be assigned to a synthesized memberwise initializer.
private enum AccessLevel {
    case `internal`
    case `fileprivate`
    case `private`
}

/// Computes the access level which would be applied to the synthesized memberwise initializer of
/// a struct that contains the given properties.
///
/// The rules for default memberwise initializer access levels are defined in The Swift
/// Programming Languge:
/// https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html#ID21
///
/// - Parameter properties: The properties contained within the struct.
/// - Returns: The synthesized memberwise initializer's access level.
private func synthesizedInitAccessLevel(using properties: [VariableDeclSyntax]) -> AccessLevel {
    var hasFileprivate = false
    for property in properties {
        guard let modifiers = property.modifiers else { continue }

        // Private takes precedence, so finding 1 private property defines the access level.
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.private) && $0.detail == nil }) {
            return .private
        }
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.fileprivate) && $0.detail == nil }) {
            hasFileprivate = true
            // Can't break here because a later property might be private.
        }
    }
    return hasFileprivate ? .fileprivate : .internal
}
