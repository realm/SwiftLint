// swiftlint:disable all
// Extracted from https://github.com/apple/swift-format/blob/f327c649efbcd7c43c2170f5c2bc7ff360f2e99b/Sources/SwiftFormatPrettyPrint/TokenStreamCreator.swift

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Rewrites a syntax tree by folding any sequence expressions contained in it.
internal final class SequenceExprFoldingRewriter: SyntaxRewriter {
    private let operatorContext: OperatorContext

    init(operatorContext: OperatorContext) {
        self.operatorContext = operatorContext
    }

    override func visit(_ node: SequenceExprSyntax) -> ExprSyntax {
        let rewrittenBySuper = super.visit(node)
        if let sequence = rewrittenBySuper.as(SequenceExprSyntax.self) {
            return sequence.folded(context: operatorContext)
        } else {
            return rewrittenBySuper
        }
    }
}
