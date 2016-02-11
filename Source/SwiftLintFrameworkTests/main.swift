//
//  main.swift
//  SwiftLint
//
//  Created by 野村 憲男 on 2/3/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest

XCTMain([
    ConfigurationTests(),
    CustomRulesTests(),
    ExtendedNSStringTests(),
    FunctionBodyLengthRuleTests(),
    IntegrationTests(),
    ReporterTests(),
    RuleConfigurationurationsTests(),
    RulesTests(),
    RuleTests(),
    YamlSwiftLintTests(),
    YamlParserTests(),
    ])
