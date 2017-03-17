//
//  FileLengthRuleTests.swift
//  SwiftLint
//
//  Created by Daniel Rodriguez Troitino on 3/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class FileLengthRuleTests: XCTestCase {
    func testFileLength() {
        verifyRule(FileLengthRule.description, commentDoesntViolate: false,
                   testMultiByteOffsets: false)
    }

    func testFileLengthWithExcluded() {
        guard let config = makeConfig(["warning": 10, "error": 15, "excluded": ["code"]],
                                      FileLengthRule.description.identifier) else {
            XCTFail()
            return
        }

        let file = File.makeTemporalFile(contents: repeatElement("//\n", count: 16).joined())!
        let violations = Linter(file: file, configuration: config).styleViolations

        XCTAssertEqual(violations, [])
    }
}

extension FileLengthRuleTests {
    static var allTests: [(String, (FileLengthRuleTests) -> () throws -> Void)] {
        return [
            ("testFileLength", testFileLength),
            ("testFileLengthWithExcluded", testFileLengthWithExcluded)
        ]
    }
}

extension File {
    static func makeTemporalFile(contents: String) -> File? {
        let temporaryDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileNameTemplate = "code.XXXXXX.swift"
        let template = temporaryDirectoryURL.appendingPathComponent(fileNameTemplate)!
        let nsTemplate = NSURL(fileURLWithPath: template.path, isDirectory: false)

        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(PATH_MAX))
        buffer.initialize(to: 0, count: Int(PATH_MAX))

        _ = nsTemplate.getFileSystemRepresentation(buffer, maxLength: Int(PATH_MAX))

        let fd = mkstemps(buffer, 6) // .swift is 6 bytes
        guard fd != -1 else {
            fatalError("Could not create temporal file.")
        }

        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        handle.write(contents.data(using: .utf8)!)
        handle.synchronizeFile()

        let temporaryURL = URL(fileURLWithFileSystemRepresentation: buffer, isDirectory: false, relativeTo: nil)
        return File(path: temporaryURL.path)
    }
}
