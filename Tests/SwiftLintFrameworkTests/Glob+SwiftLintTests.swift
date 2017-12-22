//
//  GlobSupportTests.swift
//  SwiftLint
//
//  Created by Andrey Ostanin on 28/07/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Glob
@testable import SwiftLintFramework
import XCTest

class GlobSwiftLintTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let directory = #file.bridge()
            .deletingLastPathComponent.bridge()
            .deletingLastPathComponent.bridge()
            .deletingLastPathComponent
        _ = FileManager.default.changeCurrentDirectoryPath(directory)
    }

    func testFilesIncludedUsingGlobPattern() {
        guard let configuration = Configuration(included: ["Source", "Tests"]),
              let globConfiguration = Configuration(included: ["Source/**/*.swift", "Tests/**/*.swift"])
        else { return XCTAssert(false, "Failed to create configrations for test") }

        let original = configuration.lintablePaths(inPath: "").sorted(by: { $0 < $1 })
        let globed = globConfiguration.lintablePaths(inPath: "").sorted(by: { $0 < $1 })
        XCTAssertEqual(original, globed)
    }

    func testFilesExcludedUsingGlobPattern() {
        guard let configuration = Configuration(included: ["Source", "Tests"],
                                                excluded: ["Tests/SwiftLintFrameworkTests/Resources"]),
              let globConfiguration = Configuration(included: ["Source", "Tests"],
                                                    excluded: ["./**/Level*.swift"] )
        else { return XCTAssert(false, "Failed to create configrations for test") }

        let original = configuration.lintablePaths(inPath: "").sorted(by: { $0 < $1 })
        let globed = globConfiguration.lintablePaths(inPath: "").sorted(by: { $0 < $1 })
        XCTAssertEqual(original, globed)
    }
}
