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
  private let rulePalette: RulePalette

    public var styleViolations: [StyleViolation] {
      let styleViolations: [[StyleViolation]] = map(rulePalette.enabledRules) {
        return $0.validateFile(self.file)
      }
        return reduce(styleViolations, [], +)
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File, rulePalette: RulePalette = RulePalette()) {
        (self.file, self.rulePalette) = (file, rulePalette)
    }
}
