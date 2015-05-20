//
//  RulePalette.swift
//  SwiftLint
//
//  Created by Aaron Daub on 2015-05-19.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public struct RulePalette {
  public var enabledRules: [Rule] =  [LineLengthRule(),
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
  
  private var disabledRules: [Rule] = []
  
  public init() {
    
  }
  
  func ruleWith(identifier: String, enabled: Bool) -> Rule? {
    let arrayToSearch = enabled ? self.enabledRules : self.disabledRules
    
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
    var (rulesToAddTo, rulesToRemoveFrom) = enabled ? (self.enabledRules, self.disabledRules) : (self.disabledRules, self.enabledRules)
    
    if let rule = ruleWith(identifier, enabled: !enabled) {
      moveRule(rule, enabled: enabled)
      return true
    }
    return false
  }
  
  private mutating func moveRule(rule: Rule, enabled: Bool) {
    let rulesTuple = enabled ? (self.enabledRules, self.disabledRules) : (self.disabledRules, self.enabledRules)
    var (rulesToAddTo, rulesToRemoveFrom): ([Rule], [Rule]) = rulesTuple
    
    rulesToAddTo.append(rule)
    rulesToRemoveFrom = filter(rulesToRemoveFrom) { (candidateRule: Rule) -> Bool in
      return candidateRule.identifier != rule.identifier
    }
    
    (self.enabledRules, self.disabledRules) = enabled ? (rulesToAddTo, rulesToRemoveFrom) : (rulesToRemoveFrom, rulesToAddTo)
  }
}