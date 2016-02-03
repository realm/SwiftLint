//
//  IntegrationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftLintFramework
import XCTest

class IntegrationTests: XCTestCase {

    // protocol XCTestCaseProvider
    lazy var allTests: [(String, () throws -> Void)] = [
        ("testSwiftLintLints", self.testSwiftLintLints),
    ]

    func testSwiftLintLints() {
        // This is as close as we're ever going to get to a self-hosting linter.
        let directory = (((__FILE__ as NSString)
            .stringByDeletingLastPathComponent as NSString)
            .stringByDeletingLastPathComponent as NSString)
            .stringByDeletingLastPathComponent
        NSFileManager.defaultManager().changeCurrentDirectoryPath(directory)
        let config = Configuration(path: Configuration.fileName)
        let swiftFiles = config.lintableFilesForPath("")
        XCTAssert(swiftFiles.map({$0.path!}).contains(__FILE__), "current file should be included")

        #if SWIFTLINT_XCODE_VERSION_0730
            XCTAssertEqual(swiftFiles.flatMap({
                Linter(file: $0, configuration: config).styleViolations
            }), [])
        #else
            let violations = swiftFiles.flatMap {
                Linter(file: $0, configuration: config).styleViolations
            }
            violations.forEach {
                XCTFail($0.reason, file: $0.location.file!, line: UInt($0.location.line!))
            }
        #endif
    }
}
