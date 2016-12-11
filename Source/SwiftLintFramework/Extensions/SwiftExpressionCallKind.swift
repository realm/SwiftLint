//
//  SwiftExpressionCallKind.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 11/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public enum SwiftExpressionCallKind: String {
    case exprCall = "source.lang.swift.expr.call"
    case other

    public init?(rawValue: String) {
        switch rawValue {
        case SwiftExpressionCallKind.exprCall.rawValue:
            self = .exprCall
        default:
            self = .other
        }
    }
}
