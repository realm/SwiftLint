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

    private class TestFileManager: LintableFileManager {
        func filesToLint(inPath: String, rootDirectory: String? = nil) -> [String] {
            return []
        }

        internal var stubbedModificationDateByPath: [String: Date] = [:]

        public func modificationDate(forFileAtPath path: String) -> Date? {
            return stubbedModificationDateByPath[path]
        }
    }

    private let fileManager = TestFileManager()

    func testInitThrowsWhenUsingInvalidCacheFormat() {
        let cache = [["version": "0.1.0"]]
        checkError(LinterCacheError.invalidFormat) {
            _ = try LinterCache(cache: cache, configuration: Configuration()!)
        }
    }
}
