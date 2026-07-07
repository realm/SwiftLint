import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct LegacyUIGraphicsFunctionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_uigraphics_function",
        name: "Legacy UIGraphics Function",
        description: "Prefer using `UIGraphicsImageRenderer` over legacy functions",
        rationale: "The modern replacement is safer, cleaner, Retina-aware and more performant.",
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
            UIGraphicsImageRenderer(size: newSize, format: UIGraphicsImageRendererFormat()).image { _ in
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

private extension LegacyUIGraphicsFunctionRule {
    final class Visitor: LegacyFunctionVisitor<ConfigurationType> {
        private static let legacyUIGraphicsFunctions: [String: LegacyFunctionRewriteStrategy] = [
            "UIGraphicsBeginImageContext": .noRewrite,
            "UIGraphicsBeginImageContextWithOptions": .noRewrite,
            "UIGraphicsGetImageFromCurrentImageContext": .noRewrite,
            "UIGraphicsEndImageContext": .noRewrite,
        ]

        init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file, legacyFunctions: Self.legacyUIGraphicsFunctions)
        }
    }
}
