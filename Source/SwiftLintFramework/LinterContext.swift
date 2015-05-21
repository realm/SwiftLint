//
//  LinterContext.swift
//  SwiftLint
//
//  Created by Aaron Daub on 2015-05-21.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LinterContext {
  var region: File
  private var potentiallyEnabledRules: [Rule] = [LineLengthRule(),
    LeadingWhitespaceRule(),
    TrailingWhitespaceRule(),
    TrailingNewlineRule(),
    ForceCastRule(),
    FileLengthRule(),
    TodoRule(),
    ColonRule(),
    TypeNameRule(),
    VariableNameRule(),
    TypeBodyLengthRule(),
    FunctionBodyLengthRule(),
    NestingRule()]
  var disabledRules: [Rule] = []
  var parentEnabledRules: [Rule] = []
  
  public init(file: File) {
    self.region = file
  }
  
  public init(insideOf context: LinterContext, file: File) {
    (self.region, self.parentEnabledRules) = (file, context.enabledRules())
  }
  
  public func enabledRules() -> [Rule] {
    // All of our enabled rules that are not enabled in our parent
    return potentiallyEnabledRules.filter { (rule: Rule) -> Bool in
      return self.parentEnabledRules.filter { $0.identifier == rule.identifier}.count == 0
    }
  }
  
  func ruleWith(identifier: String, enabled: Bool) -> Rule? {
    let arrayToSearch = enabled ? self.potentiallyEnabledRules : self.disabledRules
    
    return filter(arrayToSearch) {
      return $0.identifier == identifier
      }.first
  }
  
  public mutating func enableRule(identifier: String) -> Bool {
    return changeRule(identifier, enabled: true)
  }
  
  public mutating func disableRule(identifier: String) -> Bool {
    return changeRule(identifier, enabled: false)
  }
  
  private mutating func changeRule(identifier: String, enabled: Bool) -> Bool {
    var (rulesToAddTo, rulesToRemoveFrom) = enabled ? (self.potentiallyEnabledRules, self.disabledRules) : (self.disabledRules, self.potentiallyEnabledRules)
    
    if let rule = ruleWith(identifier, enabled: !enabled) {
      moveRule(rule, enabled: enabled)
      return true
    }
    return false
  }
  
  private mutating func moveRule(rule: Rule, enabled: Bool) {
    let rulesTuple = enabled ? (self.potentiallyEnabledRules, self.disabledRules) : (self.disabledRules, self.potentiallyEnabledRules)
    var (rulesToAddTo, rulesToRemoveFrom): ([Rule], [Rule]) = rulesTuple
    
    rulesToAddTo.append(rule)
    rulesToRemoveFrom = filter(rulesToRemoveFrom) { (candidateRule: Rule) -> Bool in
      return candidateRule.identifier != rule.identifier
    }
    
    (self.potentiallyEnabledRules, self.disabledRules) = enabled ? (rulesToAddTo, rulesToRemoveFrom) : (rulesToRemoveFrom, rulesToAddTo)
  }
}