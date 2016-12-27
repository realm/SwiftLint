//
//  LinterCacheTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import XCTest

class LinterCacheTests: XCTestCase {

    func testInitThrowsWhenUsingDifferentVersion() {
        let cache = ["version": "0.1.0"]
        checkError(LinterCacheError.differentVersion) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        }
    }

    func testInitThrowsWhenUsingInvalidCacheFormat() {
        let cache = [["version": "0.1.0"]]
        checkError(LinterCacheError.invalidFormat) {
            _ = try LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        }
    }

    func testInitSucceeds() {
        let cache = ["version": "0.2.0"]
        let linterCache = try? LinterCache(cache: cache, currentVersion: Version(value: "0.2.0"))
        XCTAssertNotNil(linterCache)
    }
}
