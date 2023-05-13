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

struct UnneededSynthesizedInitializerRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension UnneededSynthesizedInitializerRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            violations += node.unneededInitializers.map {
                let initializerType = $0.parameterList.isEmpty ? "default" : "memberwise"
                let reason = "This \(initializerType) initializer would be synthesized automatically - " +
                "you do not need to define it"
                return ReasonedRuleViolation(position: $0.positionAfterSkippingLeadingTrivia, reason: reason)
            }
            return .skipChildren
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        var correctionPositions: [AbsolutePosition] = []
        private var unneededInitializers: [InitializerDeclSyntax] = []

        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

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

private extension StructDeclSyntax {
    var unneededInitializers: [InitializerDeclSyntax] {
        let unneededInitializers = findUnneededInitializers()
        let initializersCount = memberBlock.members.filter { $0.decl.is(InitializerDeclSyntax.self) }.count
        if unneededInitializers.count == initializersCount {
            return unneededInitializers
        }
        return []
    }

    // Collects all of the initializers that could be replaced by the synthesized
    // memberwise or default initializer(s).
    private func findUnneededInitializers() -> [InitializerDeclSyntax] {
        var storedProperties: [VariableDeclSyntax] = []
        var initializers: [InitializerDeclSyntax] = []

        for memberItem in memberBlock.members {
            let member = memberItem.decl
            // Collect all stored variables into a list.
            if let varDecl = member.as(VariableDeclSyntax.self) {
                let modifiers = varDecl.modifiers
                if modifiers == nil || !modifiers.isStatic {
                    storedProperties.append(varDecl)
                }
            } else if let initDecl = member.as(InitializerDeclSyntax.self),
                      initDecl.optionalMark == nil,
                      !initDecl.hasThrowsOrRethrowsKeyword {
                // Collect any possible redundant initializers into a list.
                initializers.append(initDecl)
            }
        }

        return initializers.filter {
            self.initializerParameters($0.parameterList, match: storedProperties) &&
            ($0.parameterList.isEmpty || initializerBody($0.body, matches: storedProperties)) &&
            initializerModifiers($0.modifiers, match: storedProperties) && !$0.isInlinable
        }
    }

    private func noParameterInitializer(_ storedProperties: [VariableDeclSyntax]) -> Bool {
        for storedProperty in storedProperties where storedProperty.bindingKeyword.tokenKind == .keyword(.var) {
            guard storedProperty.bindings.first?.initializer != nil else {
                return false
            }
        }
        return true
    }

    // Are the initializer parameters empty, or do they match the stored properties of the struct?
    private func initializerParameters(
        _ initializerParameters: FunctionParameterListSyntax,
        match storedProperties: [VariableDeclSyntax]
    ) -> Bool {
        guard initializerParameters.isNotEmpty else { return noParameterInitializer(storedProperties) }
        guard initializerParameters.count == storedProperties.count else { return false }

        for (idx, parameter) in initializerParameters.enumerated() {
            guard parameter.secondName == nil else { return false }

            let property = storedProperties[idx]
            let propertyId = property.firstIdentifier
            let propertyTypeDescription = property.typeDescription

            // Ensure that parameters that correspond to properties declared using 'var' have a default
            // argument that is identical to the property's default value. Otherwise, a default argument
            // doesn't match the memberwise initializer.
            if property.bindingKeyword.tokenKind == .keyword(.var),
               let initializer = property.initializer {
                guard
                    let defaultArg = parameter.defaultArgument,
                    initializer.value.description == defaultArg.value.description
                else { return false }
            } else if parameter.defaultArgument != nil {
                return false
            }

            if propertyId.identifier.text != parameter.firstName.text ||
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
                case .assignmentExpr(let element) where element.assignToken.tokenKind != .equal:
                    return false
                case .assignmentExpr:
                    break
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
            guard statements.contains(id), let idx = statements.firstIndex(of: id) else { return false }
            statements.remove(at: idx)
        }
        return statements.isEmpty
    }

    // Does the actual access level of an initializer match the access level of the synthesized
    // memberwise initializer?
    private func initializerModifiers(
        _ modifiers: ModifierListSyntax?,
        match storedProperties: [VariableDeclSyntax]
    ) -> Bool {
        let synthesizedAccessLevel = synthesizedInitializerAccessLevel(using: storedProperties)
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
    var accessLevelModifier: DeclModifierSyntax? { first { $0.isAccessLevelModifier } }
}

private extension DeclModifierSyntax {
    var isAccessLevelModifier: Bool {
        let tokenKind = name.tokenKind
        return tokenKind == .keyword(.public) || tokenKind == .keyword(.private) ||
               tokenKind == .keyword(.fileprivate) || tokenKind == .keyword(.internal)
    }
}

private extension InitializerDeclSyntax {
    var hasThrowsOrRethrowsKeyword: Bool {
        signature.effectSpecifiers?.throwsSpecifier != nil
    }
    var isInlinable: Bool {
        attributes.contains(attributeNamed: "inlinable")
    }
    var parameterList: FunctionParameterListSyntax {
        signature.input.parameterList
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
