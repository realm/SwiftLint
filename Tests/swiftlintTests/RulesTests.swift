//
//  RulesTests.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest

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
        let swiftFile = testBundle.URLForResource("valid_swift", withExtension: nil)!
        let url = swiftFile.URLByAppendingPathExtension("swift")
        let fileManager = NSFileManager.defaultManager()
        do {
            if fileManager.fileExistsAtPath(url.relativePath!) {
                try fileManager.removeItemAtURL(url)
            }
            try fileManager.copyItemAtURL(swiftFile, toURL: url)
        } catch {
            fatalError("Failed to move swift file to \(url.relativePath!)")
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
        let passingYml = testBundle.URLForResource("puppet_config_passing", withExtension: "yml")!
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
        let failingYml = testBundle.URLForResource("puppet_config_failing", withExtension: "yml")!
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
