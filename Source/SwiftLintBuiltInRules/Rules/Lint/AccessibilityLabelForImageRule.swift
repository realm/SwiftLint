import SwiftSyntax

@SwiftSyntaxRule
struct AccessibilityLabelForImageRule: Rule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "accessibility_label_for_image",
        name: "Accessibility Label for Image",
        description: "Images that provide context should have an accessibility label or should be explicitly hidden " +
                     "from accessibility",
        rationale: """
        In UIKit, a `UIImageView` was by default not an accessibility element, and would only be visible to VoiceOver \
        and other assistive technologies if the developer explicitly made them an accessibility element. In SwiftUI, \
        however, an `Image` is an accessibility element by default. If the developer does not explicitly hide them \
        from accessibility or give them an accessibility label, they will inherit the name of the image file, which \
        often creates a poor experience when VoiceOver reads things like "close icon white".

        Known false negatives for Images declared as instance variables and containers that provide a label but are \
        not accessibility elements. Known false positives for Images created in a separate function from where they \
        have accessibility properties applied.
        """,
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: AccessibilityLabelForImageRuleExamples.nonTriggeringExamples,
        triggeringExamples: AccessibilityLabelForImageRuleExamples.triggeringExamples
    )
}

private extension AccessibilityLabelForImageRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var isInViewStruct = false

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            isInViewStruct = node.isViewStruct
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            isInViewStruct = false
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            // Only check Image calls within View structs
            guard isInViewStruct else { return }

            // Only process direct Image calls
            guard node.isDirectImageCall else { return }

            // Use centralized exemption logic
            if !AccessibilityDeterminator.isExempt(node) {
                let violation = ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: """
                        Images that provide context should have an accessibility label or should be \
                        explicitly hidden from accessibility
                        """,
                    severity: configuration.severity
                )
                violations.append(violation)
            }
        }
    }
}

// MARK: Accessibility Exemption Logic

private struct AccessibilityDeterminator {
    /// Maximum depth to search up the syntax tree for exemptions
    static let maxSearchDepth = 20

    /// Determines if an Image call is exempt from requiring accessibility treatment
    static func isExempt(_ imageCall: FunctionCallExprSyntax) -> Bool {
        // 1. Check for decorative or labeled initializers (e.g., Image(decorative:))
        if imageCall.isDecorativeOrLabeledImage {
            return true
        }

        // 2. Check the parent hierarchy for exemptions
        return imageCall.isExemptedByAncestors()
    }
}

// MARK: SwiftSyntax extensions

private extension StructDeclSyntax {
    /// Whether this struct conforms to View protocol
    var isViewStruct: Bool {
        guard let inheritanceClause else { return false }

        return inheritanceClause.inheritedTypes.contains { inheritedType in
            inheritedType.type.as(IdentifierTypeSyntax.self)?.name.text == "View"
        }
    }
}

private extension FunctionCallExprSyntax {
    /// Check if this is a direct Image call (not a modifier)
    var isDirectImageCall: Bool {
        // Check for direct Image call
        if let identifierExpr = calledExpression.as(DeclReferenceExprSyntax.self) {
            return identifierExpr.baseName.text == "Image"
        }

        // Check for SwiftUI.Image call
        if let memberAccessExpr = calledExpression.as(MemberAccessExprSyntax.self),
           let baseIdentifier = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self) {
            return baseIdentifier.baseName.text == "SwiftUI" &&
                   memberAccessExpr.declName.baseName.text == "Image"
        }

        return false
    }

    /// Whether this is Image(decorative:) or Image(_:label:)
    var isDecorativeOrLabeledImage: Bool {
        arguments.contains { arg in
            let label = arg.label?.text
            return label == "decorative" || label == "label"
        }
    }

    /// Walks up the syntax tree to find accessibility exemptions with depth limit
    func isExemptedByAncestors() -> Bool {
        var currentNode: Syntax? = Syntax(self)
        var depth = 0

        while let node = currentNode, depth < AccessibilityDeterminator.maxSearchDepth {
            defer {
                currentNode = node.parent
                depth += 1
            }

            // Check function calls for exempting patterns
            guard let funcCall = node.as(FunctionCallExprSyntax.self) else { continue }

            // Check for accessibility modifiers
            if let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self) {
                let modifierName = memberAccess.declName.baseName.text

                if funcCall.isDirectAccessibilityModifier(modifierName) ||
                    funcCall.isContainerExemptingModifier(modifierName) {
                    return true
                }
            }

            // Check for inherently exempting containers
            if funcCall.isInherentlyExemptingContainer() {
                return true
            }

            // Check container views with accessibility modifiers
            if funcCall.isContainerView() && funcCall.hasAccessibilityModifiersInChain() {
                return true
            }

            // Stop early at statement boundaries for performance
            if node.parent?.is(StmtSyntax.self) == true {
                break
            }
        }

        return false
    }

    /// Check if this function call represents a container view
    func isContainerView() -> Bool {
        guard let identifierExpr = calledExpression.as(DeclReferenceExprSyntax.self) else { return false }
        let containerNames: Set<String> = ["VStack", "HStack", "ZStack", "Group", "LazyVStack", "LazyHStack"]
        return containerNames.contains(identifierExpr.baseName.text)
    }

    /// Check if this container has accessibility modifiers in its modifier chain
    func hasAccessibilityModifiersInChain() -> Bool {
        var currentNode: Syntax? = Syntax(self)
        var depth = 0

        while let node = currentNode, depth < AccessibilityDeterminator.maxSearchDepth {
            defer {
                currentNode = node.parent
                depth += 1
            }

            guard let funcCall = node.as(FunctionCallExprSyntax.self),
                  let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self) else { continue }

            let modifierName = memberAccess.declName.baseName.text

            if funcCall.isDirectAccessibilityModifier(modifierName) ||
                funcCall.isContainerExemptingModifier(modifierName) {
                return true
            }

            // Stop at statement boundaries
            if node.parent?.is(StmtSyntax.self) == true {
                break
            }
        }

        return false
    }

    /// Checks for modifiers like .accessibilityLabel(...) or .accessibilityHidden(true)
    func isDirectAccessibilityModifier(_ name: String) -> Bool {
        switch name {
        case "accessibilityHidden":
            return arguments.first?.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind == .keyword(.true)
        case "accessibilityLabel", "accessibilityValue", "accessibilityHint":
            return true
        case "accessibility":
            return arguments.contains { arg in
                guard let label = arg.label?.text else { return false }
                if ["label", "value", "hint"].contains(label) { return true }
                if label == "hidden" {
                    return arg.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind == .keyword(.true)
                }
                return false
            }
        default:
            return false
        }
    }

    /// Checks for modifiers that make a container exempt its children from individual accessibility
    func isContainerExemptingModifier(_ name: String) -> Bool {
        guard name == "accessibilityElement" else { return false }

        // Check for .accessibilityElement(children: .ignore) which exempts children
        if let childrenArg = arguments.first(where: { $0.label?.text == "children" }) {
            let childrenValue = childrenArg.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
            return childrenValue == "ignore" // Only .ignore exempts individual children
        }

        // .accessibilityElement() with no arguments defaults to behavior that exempts children
        return arguments.isEmpty
    }

    /// Checks for container views that provide their own accessibility context
    func isInherentlyExemptingContainer() -> Bool {
        guard let identifier = calledExpression.as(DeclReferenceExprSyntax.self) else { return false }
        let containerName = identifier.baseName.text

        // NavigationLink automatically exempts children
        if containerName == "NavigationLink" {
            return true
        }

        // Button exempts children if it has accessibility treatment
        if containerName == "Button" {
            return hasDirectAccessibilityTreatment()
        }

        return false
    }

    /// Check if this container has direct accessibility treatment
    private func hasDirectAccessibilityTreatment() -> Bool {
        var currentNode: Syntax? = Syntax(self)
        var depth = 0

        while let node = currentNode, depth < AccessibilityDeterminator.maxSearchDepth {
            defer {
                currentNode = node.parent
                depth += 1
            }

            guard let funcCall = node.as(FunctionCallExprSyntax.self),
                  let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self) else { continue }

            let modifierName = memberAccess.declName.baseName.text
            if funcCall.isDirectAccessibilityModifier(modifierName) {
                return true
            }

            // Stop at statement boundaries
            if node.parent?.is(StmtSyntax.self) == true {
                break
            }
        }

        return false
    }
}
