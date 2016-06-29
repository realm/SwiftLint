//
//  RulesTests.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import XCTest
import SwiftLintFramework

class RulesTests: XCTestCase {

    var swiftlint: SwiftLintExecutable!

    lazy var pluginURL: NSURL = { [unowned self] in
        return testBundle.bundleURL
            .URLByDeletingLastPathComponent!
            .URLByAppendingPathComponent("PuppetPlugin.plugin")
    }()

    let destination: NSURL = {
        // Copy the source file to inspect and give it .swift extension
        // to avoid compiler processing it as a source file
        print(testBundle)
        let swiftFile = resource(named: "valid_swift", withExtension: nil)
        let url = swiftFile.URLByAppendingPathExtension("swift")
        let fileManager = NSFileManager.defaultManager()
        do {
            if fileManager.fileExistsAtPath(url.relativePath!) {
                try fileManager.removeItemAtURL(url)
            }
            try fileManager.copyItemAtURL(swiftFile, toURL: url)
        } catch let e as NSError {
            fatalError("Failed to move valid_swift file to \(url.relativePath!) \(e)")
        } catch {
            fatalError("Failed to move valid_swift file to \(url.relativePath!)")
        }
        return url
    }()

    override func setUp() {
        super.setUp()

        // executable
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
            "puppet"
        ])
        assertResultSuccess(result, "Puppet (puppet): Puppet rule, " +
            "set should_fail to true to trigger violation\n")
    }

    func testLintLoadingPuppetPluginWithPassingConfiguration() {
        let passingYml = resource(named: "puppet_config_passing", withExtension: "yml")
        let result = swiftlint.execute([
            "lint",
            "--config", passingYml.relativePath!,
            "--path", destination.relativePath!,
            "--plugins", pluginURL.relativePath!,
            "--quiet"
            ])
        assertResultSuccess(result, "")
    }

    func testLintLoadingPuppetPluginWithFailingConfiguration() {
        let failingYml = resource(named: "puppet_config_failing", withExtension: "yml")
        let result = swiftlint.execute([
            "lint",
            "--config", failingYml.relativePath!,
            "--path", destination.relativePath!,
            "--plugins", pluginURL.relativePath!,
            "--quiet"
            ])
        let expected = destination.relativePath! +
        ":0: warning: Puppet Violation: PuppetRule was told to fail (puppet)\n"
        assertResultSuccess(result, expected)

    }
}

private func resource(named name: String, withExtension ext: String? = nil) -> NSURL {
    #if SWIFT_PACKAGE
        let fileName: String
        if let ext = ext {
            fileName = "\(name).\(ext)"
        } else {
            fileName = name
        }
        let path = "Tests/swiftlint/Resources/\(fileName)"
        return NSURL(fileURLWithPath: path.absolutePathRepresentation())
    #else
        return testBundle.URLForResource(name, withExtension: ext)!
    #endif
}
