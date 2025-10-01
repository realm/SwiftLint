import SwiftSyntax

@SwiftSyntaxRule
struct LegacyUIGraphicsFunctionsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_uigraphics_functions",
        name: "Legacy UIGraphics Functions",
        description: "Prefer using `UIGraphicsImageRenderer` over legacy functions",
        rationale: "The modern replacement is safer, cleaner, Retina-aware and more performant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            let screenshot = renderer.image { _ in
                myUIView.drawHierarchy(in: bounds, afterScreenUpdates: true)
            }
            """),
            
            Example("""
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let combined = renderer.image { _ in
                background.draw(in: CGRect(origin: .zero, size: newSize))
                watermark.draw(in: CGRect(origin: .zero, size: watermarkSize))
            }
            """),
            
            Example("""
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            ↓UIGraphicsBeginImageContext(newSize)
            myUIView.drawHierarchy(in: bounds, afterScreenUpdates: false)
            let optionalScreenshot = ↓UIGraphicsGetImageFromCurrentImageContext()
            ↓UIGraphicsEndImageContext()
            """),
            
            Example("""
            ↓UIGraphicsBeginImageContext(newSize)
            background.draw(in: CGRect(origin: .zero, size: newSize))
            watermark.draw(in: CGRect(origin: .zero, size: watermarkSize))
            let optionalOutput = ↓UIGraphicsGetImageFromCurrentImageContext()
            ↓UIGraphicsEndImageContext()
            """),
            
            Example("""
            ↓UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let optionalOutput = ↓UIGraphicsGetImageFromCurrentImageContext()
            ↓UIGraphicsEndImageContext()
            """),
        ]
    )
}

private extension LegacyUIGraphicsFunctionsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private static let legacyUIGraphicsFunctions: Set<String> = [
            "UIGraphicsBeginImageContext",
            "UIGraphicsBeginImageContextWithOptions",
            "UIGraphicsGetImageFromCurrentImageContext",
            "UIGraphicsEndImageContext",
        ]

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let function = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
               Self.legacyUIGraphicsFunctions.contains(function) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
