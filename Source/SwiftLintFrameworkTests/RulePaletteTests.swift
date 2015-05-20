//
//  RulePaletteTests.swift
//  SwiftLint
//
//  Created by Aaron Daub on 2015-05-19.
//  Copyright (c) 2015 Realm. All rights reserved.
//

//import Cocoa
import XCTest
import SwiftLintFramework

class RulePaletteTests: XCTestCase {

  func testEnableRule() {
    var rulePalette = RulePalette()
    let beforeCount = rulePalette.enabledRules.count
    rulePalette.disableRule("line_length")
    let afterCount = rulePalette.enabledRules.count
    XCTAssertEqual(beforeCount, afterCount + 1, "Disabling a rule should decrease the number of enabled rules by 1")
  }
  
  func testDisableRule() {
    var rulePalette = RulePalette()
    let beforeCount = rulePalette.enabledRules.count
    rulePalette.disableRule("line_length")
    rulePalette.enableRule("line_length")
    let afterCount = rulePalette.enabledRules.count
    XCTAssertEqual(beforeCount, afterCount, "Disabling a rule and then enabling that rule shouldn't alter the number of enabled rules")
  }

}
