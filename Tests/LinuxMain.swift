//
//  LinuxMain.swift
//  SwiftLint
//
//  Created by JP Simard on 12/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

@testable import SwiftLintFrameworkTests
import XCTest

XCTMain([
    testCase(AttributesRuleTests.allTests),
    testCase(ConfigurationTests.allTests),
    testCase(CustomRulesTests.allTests),
    testCase(ExtendedNSStringTests.allTests),
    testCase(FileHeaderRuleTests.allTests),
    testCase(FunctionBodyLengthRuleTests.allTests),
    testCase(IntegrationTests.allTests),
    testCase(ReporterTests.allTests),
    testCase(RuleConfigurationsTests.allTests),
    testCase(RuleTests.allTests),
    testCase(RulesTests.allTests),
    testCase(SourceKitCrashTests.allTests),
    testCase(YamlSwiftLintTests.allTests),
    testCase(YamlParserTests.allTests)
])
