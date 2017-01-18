//
//  LegacyConstantRuleExamples.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/16/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

internal struct LegacyConstantRuleExamples {

    static let swift2NonTriggeringExamples = commonNonTriggeringExamples

    static let swift3NonTriggeringExamples = commonNonTriggeringExamples + ["CGFloat.pi", "Float.pi"]

    static let swift2TriggeringExamples = commonTriggeringExamples

    static let swift3TriggeringExamples = commonTriggeringExamples + ["↓CGFloat(M_PI)", "↓Float(M_PI)"]

    static let swift2Corrections = commonCorrections

    static let swift3Corrections: [String: String] = {
        var corrections = commonCorrections
        ["↓CGFloat(M_PI)": "CGFloat.pi",
         "↓Float(M_PI)": "Float.pi",
         "↓CGFloat(M_PI)\n↓Float(M_PI)\n": "CGFloat.pi\nFloat.pi\n"].forEach { key, value in
            corrections[key] = value
        }
        return corrections
    }()

    static let swift2Patterns = commonPatterns

    static let swift3Patterns: [String: String] = {
        var patterns = commonPatterns
        ["CGFloat\\(M_PI\\)": "CGFloat.pi",
         "Float\\(M_PI\\)": "Float.pi"].forEach { key, value in
            patterns[key] = value
        }
        return patterns
    }()

    private static let commonNonTriggeringExamples = [
        "CGRect.infinite",
        "CGPoint.zero",
        "CGRect.zero",
        "CGSize.zero",
        "NSPoint.zero",
        "NSRect.zero",
        "NSSize.zero",
        "CGRect.null"
    ]

    private static let commonTriggeringExamples = [
        "↓CGRectInfinite",
        "↓CGPointZero",
        "↓CGRectZero",
        "↓CGSizeZero",
        "↓NSZeroPoint",
        "↓NSZeroRect",
        "↓NSZeroSize",
        "↓CGRectNull"
    ]

    private static let commonCorrections = [
        "↓CGRectInfinite": "CGRect.infinite",
        "↓CGPointZero": "CGPoint.zero",
        "↓CGRectZero": "CGRect.zero",
        "↓CGSizeZero": "CGSize.zero",
        "↓NSZeroPoint": "NSPoint.zero",
        "↓NSZeroRect": "NSRect.zero",
        "↓NSZeroSize": "NSSize.zero",
        "↓CGRectNull": "CGRect.null",
        "↓CGRectInfinite\n↓CGRectNull\n": "CGRect.infinite\nCGRect.null\n"
    ]

    private static let commonPatterns = [
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
