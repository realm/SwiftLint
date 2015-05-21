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
  private let context: LinterContext
  private let file: File

  public var styleViolations: [StyleViolation] {
    let linters = self.linters
      return linters.flatMap {
        $0.styleViolations
      } + context.enabledRules().flatMap {
        $0.validateFile(self.file)
      }
    }
  
  private var linters: [Linter] {
    let linterContextBegin = "// swift-lint:begin-context"
    let linterContextEnd = "// swift-lint:end-context"
  
  
    var contextDepth = 0
    var (contextStartingLineNumber, contextEndingLineNumber) = (0, 0)
    var currentLineNumber = 0
    var inContext = false
    
    typealias LinterRegion = (start: Int, exclusiveEnd: Int)
    let lines = self.context.region.contents.lines()
    
    var regions: [LinterRegion] = flatten(lines.map { (line: Line) -> (LinterRegion)? in
      if line.content.trim() == linterContextBegin {
        inContext = true
        contextDepth += 1
        contextStartingLineNumber = currentLineNumber + 1
      } else if line.content.trim() == linterContextEnd && inContext {
        contextDepth -= 1
        inContext = contextDepth != 0
        
        contextEndingLineNumber = currentLineNumber
        if !inContext {
          return (contextStartingLineNumber, contextEndingLineNumber)
        }
      }
      currentLineNumber += 1
      return nil
    })

    let linters = regions.map { (region: LinterRegion) -> Linter in
      let sublines: [String] = map((lines[region.start ..< region.exclusiveEnd])) {
        $0.content
      }
      
      let substring = "\n".join(sublines + [""]) // postpend the empty string to keep trailing newlines
      let region = File(contents: substring)
      let context = LinterContext(insideOf: self.context, file: region)
      return Linter(file: self.file, context: context)
    }
    
    return linters
  }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.file = file
        self.context = LinterContext(file: file)
    }
  
    /**
    Initialize a Linter by passing in a LinterContext.
    This is for having a child Linter inherit properties
    from their parent.
  
    :param: context LinterContext to inherit from
    */
  private init(file: File, context: LinterContext) {
      self.file = file
      self.context = context
    }
}
