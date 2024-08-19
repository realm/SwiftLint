// swiftlint:disable file_header
//
// Adapted from swift-format's UseSynthesizedInitializer.swift
//
// https://github.com/apple/swift-format
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct UnneededSynthesizedInitializerRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_synthesized_initializer",
        name: "Unneeded Synthesized Initializer",
        description: "Default or memberwise initializers that will be automatically synthesized " +
                     "do not need to be manually defined.",
        kind: .idiomatic,
        nonTriggeringExamples: UnneededSynthesizedInitializerRuleExamples.nonTriggering,
        triggeringExamples: UnneededSynthesizedInitializerRuleExamples.triggering,
        corrections: UnneededSynthesizedInitializerRuleExamples.corrections
    )
}

private extension UnneededSynthesizedInitializerRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(StructDeclSyntax.self, ClassDeclSyntax.self)
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            violations += node.unneededInitializers.map {
                let initializerType = $0.parameterList.isEmpty ? "default" : "memberwise"
                let reason = "This \(initializerType) initializer would be synthesized automatically - " +
                    "you do not need to define it"
                return ReasonedRuleViolation(position: $0.positionAfterSkippingLeadingTrivia, reason: reason)
            }
            return .visitChildren
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        private var unneededInitializers: [InitializerDeclSyntax] = []

        override func visitAny(_: Syntax) -> Syntax? { nil }

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            unneededInitializers = node.unneededInitializers.filter {
                !$0.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            }
            return super.visit(node)
        }

        override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
            if unneededInitializers.contains(node) {
                correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
                let expr: DeclSyntax = ""
                return expr
                    .with(\.leadingTrivia, node.leadingTrivia)
                    .with(\.trailingTrivia, node.trailingTrivia)
            }
            return super.visit(node)
        }
    }
}

private final class ElementCollector: SyntaxAnyVisitor {
    var initializers = [InitializerDeclSyntax]()
    var varDecls = [VariableDeclSyntax]()

    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        node.isProtocol((any NamedDeclSyntax).self) ? .skipChildren : .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        initializers.append(node)
        return .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        varDecls.append(node)
        return .skipChildren
    }
}

private extension StructDeclSyntax {
    var unneededInitializers: [InitializerDeclSyntax] {
        let collector = ElementCollector(viewMode: .sourceAccurate)
        collector.walk(memberBlock)
        let unneededInitializers = findUnneededInitializers(in: collector)
        if unneededInitializers.count == collector.initializers.count {
            return unneededInitializers
        }
        return []
    }

    // Finds all of the initializers that could be replaced by the synthesized
    // memberwise or default initializer(s).
    private func findUnneededInitializers(in collector: ElementCollector) -> [InitializerDeclSyntax] {
        let initializers = collector.initializers.filter {
            $0.optionalMark == nil && !$0.hasThrowsOrRethrowsKeyword
        }
        let varDecls = collector.varDecls.filter { !$0.modifiers.contains(keyword: .static) }
        return initializers.filter {
            self.initializerParameters($0.parameterList, match: varDecls) &&
            (($0.parameterList.isEmpty && hasNoSideEffects($0.body)) ||
             initializerBody($0.body, matches: varDecls)) &&
            initializerModifiers($0.modifiers, match: varDecls) && $0.attributes.isEmpty
        }
    }

    // Are the initializer parameters empty, or do they match the stored properties of the struct?
    private func initializerParameters(
        _ initializerParameters: FunctionParameterListSyntax,
        match storedProperties: [VariableDeclSyntax]
    ) -> Bool {
        if initializerParameters.isEmpty {
            // Are all properties initialized?
            return storedProperties.allSatisfy {
                $0.bindingSpecifier.tokenKind == .keyword(.var) && $0.bindings.first?.initializer != nil
            }
        }
        guard initializerParameters.count == storedProperties.count else {
            return false
        }

        for (idx, parameter) in initializerParameters.enumerated() {
            guard parameter.secondName == nil, parameter.attributes.isEmpty else {
                return false
            }
            let property = storedProperties[idx]
            let propertyId = property.firstIdentifier
            let propertyTypeDescription = property.typeDescription

            // Ensure that parameters that correspond to properties declared using 'var' have a default
            // argument that is identical to the property's default value. Otherwise, a default argument
            // doesn't match the memberwise initializer.
            if property.bindingSpecifier.tokenKind == .keyword(.var), let initializer = property.initializer {
                guard initializer.value.description == parameter.defaultValue?.value.description else {
                    return false
                }
            } else if parameter.defaultValue != nil ||
                      propertyId.identifier.text != parameter.firstName.text ||
                      (propertyTypeDescription != nil && propertyTypeDescription != parameter.typeDescription) {
                return false
            }
        }
        return true
    }

    // Does the body initialize all, and only, the stored properties for the struct?
    private func initializerBody( // swiftlint:disable:this cyclomatic_complexity
        _ initializerBody: CodeBlockSyntax?,
        matches storedProperties: [VariableDeclSyntax]
    ) -> Bool {
        guard let initializerBody, storedProperties.count == initializerBody.statements.count else {
            return false
        }

        var statements: [String] = []
        for statement in initializerBody.statements {
            guard let exp = statement.item.as(SequenceExprSyntax.self) else {
                return false
            }

            var leftName = ""
            var rightName = ""

            for element in exp.elements {
                switch Syntax(element).as(SyntaxEnum.self) {
                case .memberAccessExpr(let element):
                    guard element.isBaseSelf else {
                        return false
                    }
                    leftName = element.declName.baseName.text
                case .assignmentExpr(let element) where element.equal.tokenKind != .equal:
                    return false
                case .assignmentExpr:
                    break
                case .declReferenceExpr(let element):
                    rightName = element.baseName.text
                default:
                    return false
                }
            }
            guard leftName == rightName else {
                return false
            }
            statements.append(leftName)
        }

        for variable in storedProperties {
            let id = variable.firstIdentifier.identifier.text
            guard statements.contains(id), let idx = statements.firstIndex(of: id) else {
                return false
            }
            statements.remove(at: idx)
        }
        return statements.isEmpty
    }

    private func hasNoSideEffects(_ initializerBody: CodeBlockSyntax?) -> Bool {
        guard let initializerBody else {
            return true
        }
        return initializerBody.statements.isEmpty
    }

    // Does the actual access level of an initializer match the access level of the synthesized
    // memberwise initializer?
    private func initializerModifiers(
        _ modifiers: DeclModifierListSyntax?,
        match storedProperties: [VariableDeclSyntax]
    ) -> Bool {
        let accessLevel = modifiers?.accessLevelModifier
        switch synthesizedInitializerAccessLevel(using: storedProperties) {
        case .internal:
            // No explicit access level or internal are equivalent.
            return accessLevel == nil || accessLevel!.name.tokenKind == .keyword(.internal)
        case .fileprivate:
            return accessLevel?.name.tokenKind == .keyword(.fileprivate)
        case .private:
            return accessLevel?.name.tokenKind == .keyword(.private)
        }
    }
}

private extension InitializerDeclSyntax {
    var hasThrowsOrRethrowsKeyword: Bool {
        signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
    }

    var parameterList: FunctionParameterListSyntax {
        signature.parameterClause.parameters
    }
}

private extension FunctionParameterSyntax {
    var typeDescription: String {
        type.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension VariableDeclSyntax {
    var identifiers: [IdentifierPatternSyntax] {
        bindings.compactMap { $0.pattern.as(IdentifierPatternSyntax.self) }
    }
    var firstIdentifier: IdentifierPatternSyntax {
        identifiers[0]
    }
    var typeDescription: String? {
        bindings.first?.typeAnnotation?.type.description.trimmingCharacters(in: .whitespaces)
    }
    var initializer: InitializerClauseSyntax? {
        bindings.first?.initializer
    }
}

// Defines the access levels which may be assigned to a synthesized memberwise initializer.
private enum AccessLevel {
    case `internal`
    case `fileprivate`
    case `private`
}

// See https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html#ID21
// for the rules defining default memberwise initializer access levels
private func synthesizedInitializerAccessLevel(using storedProperties: [VariableDeclSyntax]) -> AccessLevel {
    var hasFileprivate = false
    for property in storedProperties {
        let modifiers = property.modifiers

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
