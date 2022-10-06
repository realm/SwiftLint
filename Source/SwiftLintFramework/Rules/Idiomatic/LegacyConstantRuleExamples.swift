internal struct LegacyConstantRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("CGRect.infinite"),
        Example("CGPoint.zero"),
        Example("CGRect.zero"),
        Example("CGSize.zero"),
        Example("NSPoint.zero"),
        Example("NSRect.zero"),
        Example("NSSize.zero"),
        Example("CGRect.null"),
        Example("CGFloat.pi"),
        Example("Float.pi")
    ]

    static let triggeringExamples: [Example] = [
        Example("↓CGRectInfinite"),
        Example("↓CGPointZero"),
        Example("↓CGRectZero"),
        Example("↓CGSizeZero"),
        Example("↓NSZeroPoint"),
        Example("↓NSZeroRect"),
        Example("↓NSZeroSize"),
        Example("↓CGRectNull"),
        Example("↓CGFloat(M_PI)"),
        Example("↓Float(M_PI)")
    ]

    static let corrections: [Example: Example] = [
        Example("↓CGRectInfinite"): Example("CGRect.infinite"),
        Example("↓CGPointZero"): Example("CGPoint.zero"),
        Example("↓CGRectZero"): Example("CGRect.zero"),
        Example("↓CGSizeZero"): Example("CGSize.zero"),
        Example("↓NSZeroPoint"): Example("NSPoint.zero"),
        Example("↓NSZeroRect"): Example("NSRect.zero"),
        Example("↓NSZeroSize"): Example("NSSize.zero"),
        Example("↓CGRectNull"): Example("CGRect.null"),
        Example("↓CGRectInfinite\n↓CGRectNull\n"): Example("CGRect.infinite\nCGRect.null\n"),
        Example("↓CGFloat(M_PI)"): Example("CGFloat.pi"),
        Example("↓Float(M_PI)"): Example("Float.pi"),
        Example("↓CGFloat(M_PI)\n↓Float(M_PI)\n"): Example("CGFloat.pi\nFloat.pi\n")
    ]

    static let patterns = [
        "CGRectInfinite": "CGRect.infinite",
        "CGPointZero": "CGPoint.zero",
        "CGRectZero": "CGRect.zero",
        "CGSizeZero": "CGSize.zero",
        "NSZeroPoint": "NSPoint.zero",
        "NSZeroRect": "NSRect.zero",
        "NSZeroSize": "NSSize.zero",
        "CGRectNull": "CGRect.null"
    ]
}
