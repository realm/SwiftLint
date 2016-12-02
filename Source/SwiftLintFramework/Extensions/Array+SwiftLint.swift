//
//  Array+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

extension Array {
    static func array(of obj: Any?) -> [Element]? {
        if let array = obj as? [Element] {
            return array
        } else if let obj = obj as? Element {
            return [obj]
        }
        return nil
    }
}

extension Array where Element: NSTextCheckingResult {
    func ranges() -> [NSRange] {
        return map { $0.range }
    }
}
