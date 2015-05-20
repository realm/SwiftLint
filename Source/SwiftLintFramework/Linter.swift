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
    
    typealias LinterRegion = (start: Int, end: Int)
    
    var regions: [LinterRegion] = flatten(self.context.file.contents.lines().map { (line: Line) -> (LinterRegion)? in
      if line.content == linterContextBegin {
        let startingNewContext = !inContext
        
        inContext = true
        contextDepth += 1
        contextStartingLineNumber = currentLineNumber + 1
        
        if startingNewContext { // starting a new context, so we need the region for the code BEFORE this
          return (contextEndingLineNumber, currentLineNumber - 1)
        }
        
      } else if line.content == linterContextEnd && inContext {
        contextDepth -= 1
        inContext = contextDepth != 0
        
        contextEndingLineNumber = currentLineNumber - 1
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
    let lastRegion: LinterRegion = (contextEndingLineNumber, max(self.context.file.contents.lines().count - 1, 0))
    regions.append(lastRegion)
    
    
    let linters = regions.map { (region: LinterRegion) -> Linter in
      let file = File(contents: (self.context.file.contents as NSString).substringWithRange(NSMakeRange(region.start, region.end - region.start)))
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
