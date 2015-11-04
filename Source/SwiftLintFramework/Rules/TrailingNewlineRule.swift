//
//  TrailingNewlineRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TrailingNewlineRule: Rule {
    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_newline",
        name: "Trailing Newline",
        description: "Files should have a single trailing newline."
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let string = file.contents
        let start = string.endIndex.advancedBy(-2, limit: string.startIndex)
        let range = Range(start: start, end: string.endIndex)
        let substring = string[range].utf16
        let newLineSet = NSCharacterSet.newlineCharacterSet()
        let slices = substring.split(allowEmptySlices: true) { !newLineSet.characterIsMember($0) }

        guard let slice = slices.last where slice.count != 1 else { return [] }

        return [StyleViolation(ruleDescription: self.dynamicType.description,
            location: Location(file: file.path, line: max(file.lines.count, 1)),
            reason: "File should have a single trailing newline")]
    }
}
