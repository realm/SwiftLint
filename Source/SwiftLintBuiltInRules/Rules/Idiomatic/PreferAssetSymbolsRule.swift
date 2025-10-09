import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: false)
struct PreferAssetSymbolsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_asset_symbols",
        name: "Prefer Asset Symbols",
        description: "Prefer using asset symbols over string-based image initialization",
        rationale: """
            `UIKit.UIImage(named:)` and `SwiftUI.Image(_:)` bear the risk of bugs due to typos in their string arguments.
            Since Xcode 15, Xcode generates codes for images in the Asset Catalog. Usage of these codes and system icons from SF Symbols avoid typos and allow for compile-time checking.
            """,
        kind: .idiomatic,
        minSwiftVersion: .fiveDotNine,
        nonTriggeringExamples: [
            // UIKit - using asset symbols
            Example("UIImage(resource: .someImage)"),
            Example("UIImage(systemName: \"trash\")"),
            // SwiftUI - using asset symbols  
            Example("Image(.someImage)"),
            Example("Image(systemName: \"trash\")"),
            // Dynamic strings (variables or interpolated)
            Example("UIImage(named: imageName)"),
            Example("UIImage(named: \"image_\\(suffix)\")"),
            Example("Image(imageName)"),
            Example("Image(\"image_\\(suffix)\")"),
        ],
        triggeringExamples: [
            // UIKit examples
            Example("↓UIImage(named: \"some_image\")"),
            Example("↓UIImage(named: \"some image\")"),
            Example("↓UIImage.init(named: \"someImage\")"),
            // UIKit with bundle parameters
            Example("↓UIImage(named: \"someImage\", in: Bundle.main, compatibleWith: nil)"),
            Example("↓UIImage(named: \"someImage\", in: .main)"),
            // SwiftUI examples  
            Example("↓Image(\"some_image\")"),
            Example("↓Image(\"some image\")"),
            Example("↓Image.init(\"someImage\")"),
            // SwiftUI with bundle parameters
            Example("↓Image(\"someImage\", bundle: Bundle.main)"),
            Example("↓Image(\"someImage\", bundle: .main)"),
        ]
    )
}

private extension PreferAssetSymbolsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            // Check for UIImage(named:) calls
            if isUIImageNamedInit(node: node) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
            // Check for SwiftUI Image(_:) calls
            else if isSwiftUIImageInit(node: node) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
        
        private func isUIImageNamedInit(node: FunctionCallExprSyntax) -> Bool {
            // Check if this is a UIImage or UIImage.init call using syntax tree matching
            guard isUIImageCall(node.calledExpression) else {
                return false
            }
            
            // Check if the first argument has "named" label and is a string literal
            guard let firstArgument = node.arguments.first,
                  firstArgument.label?.text == "named",
                  let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
                  stringLiteral.isConstantString else {
                return false
            }
            
            return true
        }
        
        private func isSwiftUIImageInit(node: FunctionCallExprSyntax) -> Bool {
            // Check if this is an Image or Image.init call using syntax tree matching
            guard isImageCall(node.calledExpression) else {
                return false
            }
            
            // Check if the first argument is an unlabeled string literal
            guard let firstArgument = node.arguments.first,
                  firstArgument.label == nil,
                  let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
                  stringLiteral.isConstantString else {
                return false
            }
            
            return true
        }
        
        private func isUIImageCall(_ expression: ExprSyntax) -> Bool {
            // Match UIImage directly
            if let identifierExpr = expression.as(DeclReferenceExprSyntax.self) {
                return identifierExpr.baseName.text == "UIImage"
            }
            
            // Match UIImage.init
            if let memberAccessExpr = expression.as(MemberAccessExprSyntax.self),
               let baseExpr = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self),
               baseExpr.baseName.text == "UIImage",
               memberAccessExpr.declName.baseName.text == "init" {
                return true
            }
            
            return false
        }
        
        private func isImageCall(_ expression: ExprSyntax) -> Bool {
            // Match Image directly
            if let identifierExpr = expression.as(DeclReferenceExprSyntax.self) {
                return identifierExpr.baseName.text == "Image"
            }
            
            // Match Image.init
            if let memberAccessExpr = expression.as(MemberAccessExprSyntax.self),
               let baseExpr = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self),
               baseExpr.baseName.text == "Image",
               memberAccessExpr.declName.baseName.text == "init" {
                return true
            }
            
            return false
        }
    }
}

private extension StringLiteralExprSyntax {
    var isConstantString: Bool {
        segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
    }
}
