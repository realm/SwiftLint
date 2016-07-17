//
//  RulesTests.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#if SWIFT_PACKAGE
    // This test is not possible yet with spm
#else
import Foundation
import XCTest
import SwiftLintFramework

class RulesTests: XCTestCase {

    var swiftlint: SwiftLintExecutable!

    lazy var pluginURL: NSURL = { [unowned self] in
        // swiftlint:disable line_length
        return testBundle.bundleURL
            .URLByDeletingLastPathComponent!
            .URLByAppendingPathComponent("OutdatedCopyrightRule.plugin/Contents/MacOS/OutdatedCopyrightRule")
    }()

    override func setUp() {
        super.setUp()
        swiftlint = SwiftLintExecutable()
    }

    func testRulePluginExists() {
        XCTAssertTrue(pluginURL.checkResourceIsReachableAndReturnError(nil),
                      "Plugin not found at \(pluginURL)")
    }

    func testRulesLoadingPlugin() {
        let result = swiftlint.execute([
            "rules",
            "--plugins", pluginURL.relativePath!,
            "outdated_copyright"
        ])
        assertResultSuccess(result, { string in
            string.containsString("OutdatedCopyright (outdated_copyright): Warn about outdated copyrights")
        })
    }

    func testLintLoadingOutdatedCopyrightWithPassingFile() {
        let testSwift = testUrl(passing: true)
        let passingYml = resource(named: "outdated_copyright", withExtension: "yml")
        let result = swiftlint.execute([
            "lint",
            "--config", passingYml.relativePath!,
            "--path", testSwift.relativePath!,
            "--plugins", pluginURL.relativePath!,
            "--quiet"
        ])
        assertResultSuccess(result, "")
    }

    func testLintLoadingOutdatedCopyrightWithFailingFile() {
        let testSwift = testUrl(passing: false)
        let passingYml = resource(named: "outdated_copyright", withExtension: "yml")
        let result = swiftlint.execute([
            "lint",
            "--config", passingYml.relativePath!,
            "--path", testSwift.relativePath!,
            "--plugins", pluginURL.relativePath!,
            "--quiet"
            ])
        assertResultSuccess(result, "")
    }

    private func testUrl(passing passing: Bool) -> NSURL {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let currentYear = calendar.component(.Year, fromDate: NSDate())
        let year = passing ? currentYear : currentYear - 1
        let contents = swiftContentCopyrighted(at: year)
        let url = writeTestFile(with: contents)
        return url
    }

    private func writeTestFile(with contents: String) -> NSURL {
        let yml = resource(named: "outdated_copyright", withExtension: "yml")
        let swiftFile = yml.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("outdated_copyright_test.swift")
        let url = swiftFile.URLByAppendingPathExtension("swift")
        let fileManager = NSFileManager.defaultManager()

        do {
            if url.checkResourceIsReachableAndReturnError(nil) {
                try fileManager.removeItemAtURL(url)
            }
            try contents.writeToURL(url, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            fatalError("Failed to write test swift file to \(url.relativePath!)")
        }
        return url
    }

    private func swiftContentCopyrighted(at year: Int) -> String {
        return "//" +
                "//  Test.swift" +
                "//  SwiftLint" +
                "//" +
                "//  Copyright © \(year) Realm. All rights reserved." +
                "//"
    }
}

private func resource(named name: String, withExtension ext: String? = nil) -> NSURL {
        return testBundle.URLForResource(name, withExtension: ext)!
}
#endif
