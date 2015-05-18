//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SwiftXPC
import SourceKittenFramework

public struct Linter {
    private let file: File
    private let configuration: Configuration?

    public var styleViolations: [StyleViolation] {
        return reduce(self.rules, [], +)
    }
  
  private var rules: [Rule] {
    let allRules: [Rule] = [
      LineLengthRule.validateFile(file),
      LeadingWhitespaceRule.validateFile(file),
      TrailingWhitespaceRule.validateFile(file),
      TrailingNewlineRule.validateFile(file),
      ForceCastRule.validateFile(file),
      FileLengthRule.validateFile(file),
      TodoRule.validateFile(file),
      ColonRule.validateFile(file),
      TypeNameRule.validateFile(file),
      VariableNameRule.validateFile(file),
      TypeBodyLengthRule.validateFile(file),
      FunctionBodyLengthRule.validateFile(file),
      NestingRule.validateFile(file)
    ]
    
    return map(self.configuration) {
      filter(allRules) {
        return !self.configuration.shouldIgnore($0)
      }
    } ?? allRules
  }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File, configuration: Configuration? = nil) {
        (self.file, self.configuration) = (file, configuration)
    }
}
