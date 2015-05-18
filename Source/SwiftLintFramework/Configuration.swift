//
//  Configuration.swift
//  SwiftLint
//
//  Created by Aaron Daub on 2015-05-18.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation

struct Configuration {
  static let defaultConfigurationName: String = ".swiftlint.yml"

  lazy var configurationString: String? {
    return String(contentsOfFile: self.fileName, encoding: NSUTF8StringEncoding, error: nil)
  }
  
  let fileName: String
  
  init(fileName: String? = nil) {
    self.fileName = fileName ?? Configuration.defaultConfigurationName
  }
  
 private var settings: [String] {
    return self.configurationString?.componentsSeparatedByString("\n") ?? []
  }
  
  // Returns an array of values for a given key
  private func settingsFor(key prefix: String) -> [String] {
    return filter(self.settings) {
      $0.hasPrefix(prefix)
    }.map {
        $0.stringByReplacingOccurrencesOfString(prefix, withString: "", options: NSStringCompareOptions.allZeros, range: nil)
    }
  }
  
  private var ruleIdentifiersToIgnore: [String] {
    return self.settingsFor(key: "swiftlint:disable_rule:")
  }
  
 public func shouldIgnore(rule: Rule) -> Bool {
    return self.ruleIdentifiersToIgnore.filter {
      rule.identifier == $0.identifier
    }.count >= 1
  }
  
}
