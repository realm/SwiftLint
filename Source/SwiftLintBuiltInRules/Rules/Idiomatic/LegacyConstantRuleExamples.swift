internal struct LegacyConstantRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
        "CGRect.infinite",
        "CGPoint.zero",
        "CGRect.zero",
        "CGSize.zero",
        "NSPoint.zero",
        "NSRect.zero",
        "NSSize.zero",
        "CGRect.null",
        "CGFloat.pi",
        "Float.pi",
    ])

    static let triggeringExamples: [Example] = #examples([
        "↓CGRectInfinite",
        "↓CGPointZero",
        "↓CGRectZero",
        "↓CGSizeZero",
        "↓NSZeroPoint",
        "↓NSZeroRect",
        "↓NSZeroSize",
        "↓CGRectNull",
        "↓CGFloat(M_PI)",
        "↓Float(M_PI)",
    ])

    static let corrections: [Example: Example] = #corrections([
        "↓CGRectInfinite": "CGRect.infinite",
        "↓CGPointZero": "CGPoint.zero",
        "↓CGRectZero": "CGRect.zero",
        "↓CGSizeZero": "CGSize.zero",
        "↓NSZeroPoint": "NSPoint.zero",
        "↓NSZeroRect": "NSRect.zero",
        "↓NSZeroSize": "NSSize.zero",
        "↓CGRectNull": "CGRect.null",
        "↓CGRectInfinite\n↓CGRectNull": "CGRect.infinite\nCGRect.null",
        "↓CGFloat(M_PI)": "CGFloat.pi",
        "↓Float(M_PI)": "Float.pi",
        "↓CGFloat(M_PI)\n↓Float(M_PI)": "CGFloat.pi\nFloat.pi",
    ])

    static let patterns = [
        "CGRectInfinite": "CGRect.infinite",
        "CGPointZero": "CGPoint.zero",
        "CGRectZero": "CGRect.zero",
        "CGSizeZero": "CGSize.zero",
        "NSZeroPoint": "NSPoint.zero",
        "NSZeroRect": "NSRect.zero",
        "NSZeroSize": "NSSize.zero",
        "CGRectNull": "CGRect.null",
    ]
}
