//
//  LineLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LineLengthRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityLevelsConfiguration(warning: 100, error: 200)

    public init() {}

    public static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Lines should not span too many characters.",
        nonTriggeringExamples: [
            Repeat(count: 100, repeatedValue: "/").joinWithSeparator("") + "\n",
            Repeat(count: 100, repeatedValue: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)").joinWithSeparator("") + "\n",
            Repeat(count: 100, repeatedValue: "#imageLiteral(resourceName: \"image.jpg\")").joinWithSeparator("") + "\n"
        ],
        triggeringExamples: [
            Repeat(count: 101, repeatedValue: "/").joinWithSeparator("") + "\n",
            Repeat(count: 101, repeatedValue: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)").joinWithSeparator("") + "\n",
            Repeat(count: 101, repeatedValue: "#imageLiteral(resourceName: \"image.jpg\")").joinWithSeparator("") + "\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let minValue = configuration.params.map({ $0.value }).minElement(<)
        return file.lines.flatMap { line in
            // `line.content.characters.count` <= `line.range.length` is true.
            // So, `check line.range.length` is larger than minimum parameter value.
            // for avoiding using heavy `line.content.characters.count`.
            if line.range.length < minValue {
                return nil
            }

            var strippedString = line.content
            strippedString = stripLiterals(fromSourceString: strippedString,
                withDelimiter: "#colorLiteral")
            strippedString = stripLiterals(fromSourceString: strippedString,
                withDelimiter: "#imageLiteral")

            let length = strippedString.characters.count

            for param in configuration.params where length > param.value {
                return StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: param.severity,
                    location: Location(file: file.path, line: line.index),
                    reason: "Line should be \(configuration.warning) characters or less: " +
                        "currently \(length) characters")
            }
            return nil
        }
    }

    /// Takes a string and replaces any literals specified by the `delimiter` parameter with `#`
    ///
    /// - parameter sourceString: Original string, possibly containing literals
    /// - parameter delimiter:    Delimiter of the literal
    ///     (characters before the parentheses, e.g. `#colorLiteral`)
    ///
    /// - returns: sourceString with the given literals replaced by `#`
    private func stripLiterals(fromSourceString sourceString: String,
                                                withDelimiter delimiter: String) -> String {
        var modifiedString = sourceString

        // While copy of content contains literal, replace with a single character
        while modifiedString.containsString("\(delimiter)(") {
            if let rangeStart = modifiedString.rangeOfString("\(delimiter)("),
                let rangeEnd = modifiedString.rangeOfString(")",
                                                            options: .LiteralSearch,
                                                            range:
                    rangeStart.startIndex..<modifiedString.endIndex,
                                                            locale: nil) {
                modifiedString.replaceRange(rangeStart.startIndex..<rangeEnd.endIndex, with: "#")

            } else { // Should never be the case, but break to avoid accidental infinity loop
                break
            }
        }

        return modifiedString
    }

}
