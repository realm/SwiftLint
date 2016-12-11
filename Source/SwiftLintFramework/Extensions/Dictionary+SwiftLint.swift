//
//  DynamicInlineRule.swift
//  SwiftLint
//
//  Created by Daniel Duan on 12/08/16.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension Dictionary where Key: ExpressibleByStringLiteral {
    var enclosedSwiftAttributes: [String] {
        let array = self["key.attributes"] as? [SourceKitRepresentable] ?? []
        return array.flatMap { ($0 as? [String: String])?["key.attribute"] }
    }
}
