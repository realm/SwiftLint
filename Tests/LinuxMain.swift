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
    testCase(ColonRuleTests.allTests),
    testCase(ConfigurationTests.allTests),
    testCase(CustomRulesTests.allTests),
    testCase(ExtendedNSStringTests.allTests),
    testCase(FileHeaderRuleTests.allTests),
    testCase(FunctionBodyLengthRuleTests.allTests),
    testCase(IntegrationTests.allTests),
    testCase(LineLengthConfigurationTests.allTests),
    testCase(LineLengthRuleTests.allTests),
    testCase(LinterCacheTests.allTests),
    testCase(NumberSeparatorRuleTests.allTests),
    testCase(ReporterTests.allTests),
    testCase(RuleConfigurationsTests.allTests),
    testCase(RulesTests.allTests),
    testCase(RuleTests.allTests),
    testCase(SourceKitCrashTests.allTests),
    testCase(TrailingCommaRuleTests.allTests),
    testCase(VerticalWhitespaceRuleTests.allTests),
    testCase(YamlParserTests.allTests),
    testCase(YamlSwiftLintTests.allTests)
])
