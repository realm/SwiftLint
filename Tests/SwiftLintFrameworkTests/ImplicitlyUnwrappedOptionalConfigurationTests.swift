//
//  ImplicitlyUnwrappedOptionalConfigurationTests.swift
//  SwiftLint
//
//  Created by Siarhei Fedartsou on 18/03/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

// swiftlint:disable:next type_name
class ImplicitlyUnwrappedOptionalConfigurationTests: XCTestCase {

    func testImplicitlyUnwrappedOptionalConfigurationProperlyAppliesConfigurationFromDictionary() throws {
        var configuration = ImplicitlyUnwrappedOptionalConfiguration(mode: .allExceptIBOutlets,
                                                                     severity: SeverityConfiguration(.warning))

        try configuration.apply(configuration: ["mode": "all", "severity": "error"])
        XCTAssertEqual(configuration.mode, .all)
        XCTAssertEqual(configuration.severity.severity, .error)

        try configuration.apply(configuration: ["mode": "all_except_iboutlets"])
        XCTAssertEqual(configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(configuration.severity.severity, .error)

        try configuration.apply(configuration: ["severity": "warning"])
        XCTAssertEqual(configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(configuration.severity.severity, .warning)

        try configuration.apply(configuration: ["mode": "all", "severity": "warning"])
        XCTAssertEqual(configuration.mode, .all)
        XCTAssertEqual(configuration.severity.severity, .warning)
    }

    func testImplicitlyUnwrappedOptionalConfigurationThrowsOnBadConfig() {
        let badConfigs: [[String: Any]] = [
            ["mode": "everything"],
            ["mode": false],
            ["mode": 42]
        ]

        for badConfig in badConfigs {
            var configuration = ImplicitlyUnwrappedOptionalConfiguration(mode: .allExceptIBOutlets,
                                                                         severity: SeverityConfiguration(.warning))
            checkError(ConfigurationError.unknownConfiguration) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }

}
