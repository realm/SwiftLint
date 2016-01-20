//
//  RuleConfigurationsTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest
import SwiftLintFramework

class RuleConfigurationsTests: XCTestCase {

    func testNameConfigSetsCorrectly() {
        let config = [ "min_length": ["warning": 17, "error": 7],
                       "max_length": ["warning": 170, "error": 700],
                       "excluded": "id"]
        var nameConfig = NameConfig(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        let comp = NameConfig(minLengthWarning: 17,
                              minLengthError: 7,
                              maxLengthWarning: 170,
                              maxLengthError: 700,
                              excluded: ["id"])
        if let _ = try? nameConfig.setConfiguration(config) {
            XCTAssertEqual(nameConfig, comp)
        } else {
            XCTFail("Did not configure correctly")
        }
    }

    func testNameConfigThrowsOnBadConfig() {
        let config = 17
        var nameConfig = NameConfig(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        checkError(ConfigurationError.UnknownConfiguration) {
            try nameConfig.setConfiguration(config)
        }
    }

}
