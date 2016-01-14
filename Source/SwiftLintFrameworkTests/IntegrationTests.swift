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
    func testSwiftLintLints() {
        // This is as close as we're ever going to get to a self-hosting linter.
        let directory = (((__FILE__ as NSString)
            .stringByDeletingLastPathComponent as NSString)
            .stringByDeletingLastPathComponent as NSString)
            .stringByDeletingLastPathComponent
        NSFileManager.defaultManager().changeCurrentDirectoryPath(directory)
        let config = Configuration(path: ".swiftlint.yml")
        let swiftFiles = config.lintableFilesForPath("")
        XCTAssert(swiftFiles.map({$0.path!}).contains(__FILE__), "current file should be included")
        XCTAssertEqual(swiftFiles.flatMap({
            Linter(file: $0, configuration: config).styleViolations
        }), [])
    }
}
