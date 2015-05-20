//
//  StructuredText.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 20/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation

typealias StructuredInlineText = String

private extension Array {
    func dropWhile(x: Element -> Bool) -> [Element] {
        var count = 0
        while x(self[count]) { count++ }
        var copy = self
        copy.removeRange(0..<count)
        return copy
    }
}


extension String {
    var chomped: String {
        return String(reverse(self).dropWhile { $0 == "\n" }.reverse())
    }
}

enum AnsiCode: Int {
    case Reset = 0
    case Bold = 1
    case RedForeground = 31
    case GreenForeground = 32
    
    
    
    var string: String {
        return "\u{001B}[0;\(rawValue)m"
    }
    
    func wrap(text: String) -> String {
        return self.string + text + AnsiCode.Reset.string
    }
    
    static func red(string: String) -> String {
        return AnsiCode.RedForeground.wrap(string)
    }
    
    static func green(string: String) -> String {
        return AnsiCode.GreenForeground.wrap(string)
    }
}

enum StructuredText {
    case Header(level: Int, text: StructuredInlineText)
    case Paragraph(StructuredInlineText)
    case List(items: [StructuredText])
    case Joined([StructuredText])
    
    var markdown: String {
        switch self {
        case let .Header(level, t): return join("", Array(count: level, repeatedValue: "#")) + " " + t
        case .Paragraph(let t): return t
        case .List(let items): return "\n".join(items.map { "* " + $0.markdown })
        case .Joined(let items): return "\n\n".join(items.map { $0.markdown } )
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