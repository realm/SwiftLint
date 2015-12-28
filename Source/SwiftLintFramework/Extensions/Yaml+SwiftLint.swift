//
//  Yaml+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Yaml

extension Yaml {
    var arrayOfStrings: [Swift.String]? {
        return array?.flatMap { $0.string } ?? string.map { [$0] }
    }

    var arrayOfInts: [Swift.Int]? {
        return array?.flatMap { $0.int } ?? int.map { [$0] }
    }
}
