//
//  Configuration+IndentationStyle.swift
//  SwiftLint
//
//  Created by JP Simard on 1/3/18.
//  Copyright © 2018 Realm. All rights reserved.
//

public extension Configuration {
    enum IndentationStyle: Equatable {
        case tabs
        case spaces(count: Int)

        public static var `default` = spaces(count: 4)

        // MARK: Equatable

        public static func == (lhs: IndentationStyle, rhs: IndentationStyle) -> Bool {
            switch (lhs, rhs) {
            case (.tabs, .tabs): return true
            case let (.spaces(lhs), .spaces(rhs)): return lhs == rhs
            case (_, _): return false
            }
        }
    }
}
