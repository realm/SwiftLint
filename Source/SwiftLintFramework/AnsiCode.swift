//
//  StructuredText.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 25/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation

enum AnsiCode: Int {
    case Reset = 0
    case Bold = 1
    case RedForeground = 31
    case GreenForeground = 32

    var string: String {
        return "\u{001B}[0;\(rawValue)m"
    }

    func wrap(text: String) -> String {
        return string + text + AnsiCode.Reset.string
    }

    static func red(string: String) -> String {
        return AnsiCode.RedForeground.wrap(string)
    }

    static func green(string: String) -> String {
        return AnsiCode.GreenForeground.wrap(string)
    }
}
