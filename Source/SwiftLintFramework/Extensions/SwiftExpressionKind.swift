//
//  SwiftExpressionKind.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public enum SwiftExpressionKind: String {
    case call = "source.lang.swift.expr.call"
    case argument = "source.lang.swift.expr.argument"
    case array = "source.lang.swift.expr.array"
    case dictionary = "source.lang.swift.expr.dictionary"
    case objectLiteral = "source.lang.swift.expr.object_literal"
}
