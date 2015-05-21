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

    public var styleViolations: [StyleViolation] {
      if self.linters.count == 1 { // Terminal case
        return context.enabledRules.flatMap {
          $0.validateFile(self.context.file)
        }
      }
      
      return self.linters.flatMap {
        $0.styleViolations
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
    let lines = self.context.file.contents.lines()
    
    var regions: [LinterRegion] = flatten(lines.map { (line: Line) -> (LinterRegion)? in
      if line.content == linterContextBegin {
        let startingNewContext = !inContext
        
        inContext = true
        contextDepth += 1
        contextStartingLineNumber = currentLineNumber + 1
        
        if startingNewContext { // starting a new context, so we need the region for the code BEFORE this
          return (contextEndingLineNumber, currentLineNumber)
        }
        
      } else if line.content == linterContextEnd && inContext {
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
    
    // regions now contains all the regions except
    // potentially the last, if there is code after the last linterContextEnd
    // let's add that region to regions
    if contextEndingLineNumber <= lines.count {
      regions.append((start: contextEndingLineNumber,
                      exclusiveEnd: lines.count))
    }

    let linters = regions.map { (region: LinterRegion) -> Linter in
      let sublines: [String] = map((lines[region.start ..< region.exclusiveEnd])) {
        $0.content
      }
      
      let substring = "\n".join(sublines + [""]) // postpend the empty string to keep trailing newlines
      let file = File(contents: substring)
      return Linter(file: file)
    }
    
    return linters
  }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.context = LinterContext(file: file)
    }
}
