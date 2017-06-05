//
//  LegacyConstantRuleExamples.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/16/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

internal struct LegacyConstantRuleExamples {

    static let nonTriggeringExamples = [
        "CGRect.infinite",
        "CGPoint.zero",
        "CGRect.zero",
        "CGSize.zero",
        "NSPoint.zero",
        "NSRect.zero",
        "NSSize.zero",
        "CGRect.null",
        "CGFloat.pi",
        "Float.pi"
    ]

    static let triggeringExamples = [
        "↓CGRectInfinite",
        "↓CGPointZero",
        "↓CGRectZero",
        "↓CGSizeZero",
        "↓NSZeroPoint",
        "↓NSZeroRect",
        "↓NSZeroSize",
        "↓CGRectNull",
        "↓CGFloat(M_PI)",
        "↓Float(M_PI)"
    ]

    static let corrections = [
        "↓CGRectInfinite": "CGRect.infinite",
        "↓CGPointZero": "CGPoint.zero",
        "↓CGRectZero": "CGRect.zero",
        "↓CGSizeZero": "CGSize.zero",
        "↓NSZeroPoint": "NSPoint.zero",
        "↓NSZeroRect": "NSRect.zero",
        "↓NSZeroSize": "NSSize.zero",
        "↓CGRectNull": "CGRect.null",
        "↓CGRectInfinite\n↓CGRectNull\n": "CGRect.infinite\nCGRect.null\n",
        "↓CGFloat(M_PI)": "CGFloat.pi",
        "↓Float(M_PI)": "Float.pi",
        "↓CGFloat(M_PI)\n↓Float(M_PI)\n": "CGFloat.pi\nFloat.pi\n"
    ]

    static let patterns = [
        "CGRectInfinite": "CGRect.infinite",
        "CGPointZero": "CGPoint.zero",
        "CGRectZero": "CGRect.zero",
        "CGSizeZero": "CGSize.zero",
        "NSZeroPoint": "NSPoint.zero",
        "NSZeroRect": "NSRect.zero",
        "NSZeroSize": "NSSize.zero",
        "CGRectNull": "CGRect.null",
        "CGFloat\\(M_PI\\)": "CGFloat.pi",
        "Float\\(M_PI\\)": "Float.pi"
    ]
}
