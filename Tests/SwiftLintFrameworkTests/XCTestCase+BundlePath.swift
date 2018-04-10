//
//  XCTestCase+BundlePath.swift
//  SwiftLint
//
//  Created by Stéphane Copin on 7/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    var bundlePath: String {
        #if SWIFT_PACKAGE
            return "Tests/SwiftLintFrameworkTests/Resources".bridge().absolutePathRepresentation()
        #else
            return Bundle(for: type(of: self)).resourcePath!
        #endif
    }
}
