//
//  StructuredText.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 20/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation

typealias StructuredInlineText = String

enum StructuredText {
    case Header(level: Int, text: StructuredInlineText)
    case Paragraph(StructuredInlineText)
    case List([StructuredText])
    case Joined([StructuredText])

    var markdown: String {
        switch self {
        case let .Header(level, t):
            return String(Repeat(count: level, repeatedValue: "#")) + " \(t)"
        case .Paragraph(let t):
            return t
        case .List(let items):
            return items.map({ "* " + $0.markdown }).joinWithSeparator("\n")
        case .Joined(let items):
            return items.map({ $0.markdown }).joinWithSeparator("\n\n")
        }
    }

    var ansi: String {
        switch self {
        case .Header(1, let t): return t.uppercaseString
        case .Header(_, let t): return t
        case .Paragraph(let t): return t
        case .List(let items): return items.map({ "* " + $0.ansi }).joinWithSeparator("\n")
        case .Joined(let items): return items.map({ $0.ansi }).joinWithSeparator("\n\n")
        }
    }
}
