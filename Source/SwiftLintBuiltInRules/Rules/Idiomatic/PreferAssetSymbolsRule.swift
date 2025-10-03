import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: false)
struct PreferAssetSymbolsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_asset_symbols",
        name: "Prefer Asset Symbols",
        description: "Prefer using asset symbols over string-based image initialization to avoid typos and enable compile-time checking",
        rationale: """
            UIKit.UIImage(named:) and SwiftUI.Image(_:) contain the risk of bugs due to typos. \
            Since Xcode 15, Xcode generates codes for images in the Asset Catalog and it can avoid typos by providing compile-time checking.
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
            // Bundle-specific initializers
            Example("UIImage(named: \"someImage\", in: Bundle.main, compatibleWith: nil)"),
            Example("Image(\"someImage\", bundle: Bundle.main)"),
        ],
        triggeringExamples: [
            // UIKit examples
            Example("↓UIImage(named: \"some_image\")"),
            Example("↓UIImage(named: \"some image\")"),
            Example("↓UIImage.init(named: \"someImage\")"),
            // SwiftUI examples  
            Example("↓Image(\"some_image\")"),
            Example("↓Image(\"some image\")"),
            Example("↓Image.init(\"someImage\")"),
        ]
    )
}

private extension PreferAssetSymbolsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let calledExpression = node.calledExpression.trimmedDescription
            
            // Check for UIImage(named:) calls
            if isUIImageNamedInit(node: node, name: calledExpression) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
            // Check for SwiftUI Image(_:) calls
            else if isSwiftUIImageInit(node: node, name: calledExpression) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
        
        private func isUIImageNamedInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            // Check if this is a UIImage or UIImage.init call
            guard uiImageInits().contains(name) else {
                return false
            }
            
            // Check if it has a "named" parameter with a string literal
            guard let namedArgument = node.arguments.first(where: { $0.label?.text == "named" }),
                  let stringLiteral = namedArgument.expression.as(StringLiteralExprSyntax.self),
                  stringLiteral.isConstantString else {
                return false
            }
            
            // Don't trigger if there are additional parameters like "in:" (bundle parameter)
            let argumentLabels = node.arguments.compactMap(\.label?.text)
            return argumentLabels == ["named"]
        }
        
        private func isSwiftUIImageInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            // Check if this is an Image or Image.init call
            guard swiftUIImageInits().contains(name) else {
                return false
            }
            
            // For SwiftUI Image, the first parameter is unlabeled for the image name
            guard let firstArgument = node.arguments.first,
                  firstArgument.label == nil,
                  let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
                  stringLiteral.isConstantString else {
                return false
            }
            
            // Don't trigger if there are additional parameters like "bundle:"
            let argumentLabels = node.arguments.compactMap(\.label?.text)
            return argumentLabels.isEmpty || (argumentLabels.count == 1 && argumentLabels.first == nil)
        }
        
        private func uiImageInits() -> [String] {
            return [
                "UIImage",
                "UIImage.init"
            ]
        }
        
        private func swiftUIImageInits() -> [String] {
            return [
                "Image", 
                "Image.init"
            ]
        }
    }
}

private extension StringLiteralExprSyntax {
    var isConstantString: Bool {
        segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
    }
}
