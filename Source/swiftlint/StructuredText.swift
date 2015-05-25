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
            return join("", Array(count: level, repeatedValue: "#")) + " \(t)"
        case .Paragraph(let t):
            return t
        case .List(let items):
            return "\n".join(items.map { "* " + $0.markdown })
        case .Joined(let items):
            return "\n\n".join(items.map { $0.markdown } )
        }
    }

    var ansi: String {
        switch self {
        case .Header(1, let t): return t.uppercaseString
        case let .Header(other, t): return t
        case .Paragraph(let t): return t
        case .List(let items): return "\n".join(items.map { "* " + $0.ansi })
        case .Joined(let items): return "\n\n".join(items.map { $0.ansi } )
        }
    }
}
