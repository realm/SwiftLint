//
//  ForceUnwrappingRule.swift
//  SwiftLint
//
//  Created by Benjamin Otto on 14/01/16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ForceUnwrappingRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_unwrapping",
        name: "Force Unwrapping",
        description: "Force unwrapping should be avoided.",
        nonTriggeringExamples: [
            "if let url = NSURL(string: query)",
            "navigationController?.pushViewController(viewController, animated: true)",
            "let s as! Test",
            "try! canThrowErrors()",
            "let object: AnyObject!",
            "@IBOutlet var constraints: [NSLayoutConstraint]!",
            "setEditing(!editing, animated: true)",
            "navigationController.setNavigationBarHidden(!navigationController." +
                "navigationBarHidden, animated: true)",
            "if addedToPlaylist && (!self.selectedFilters.isEmpty || " +
                "self.searchBar?.text?.isEmpty == false) {}",
        ],
        triggeringExamples: [
            "let url = NSURL(string: query)↓!",
            "navigationController↓!.pushViewController(viewController, animated: true)",
            "let unwrapped = optional↓!",
            "return cell↓!",
            "let url = NSURL(string: \"http://www.google.com\")↓!"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return violationRangesInFile(file).map {
            return StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    // capture previous and next of "!"
    // http://userguide.icu-project.org/strings/regexp
    private static let pattern = "(\\S)!(.?)"

    // swiftlint:disable:next force_try
    private static let regularExpression = try! NSRegularExpression(pattern: pattern,
        options: [.DotMatchesLineSeparators])
    private static let excludingSyntaxKindsForFirstCapture = SyntaxKind
        .commentKeywordStringAndTypeidentifierKinds().map { $0.rawValue }
    private static let excludingSyntaxKindsForSecondCapture = [SyntaxKind.Identifier.rawValue]

    private func violationRangesInFile(file: File) -> [NSRange] {
        let contents = file.contents
        let nsstring = contents as NSString
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntaxMap = file.syntaxMap
        return ForceUnwrappingRule.regularExpression
            .matchesInString(contents, options: [], range: range)
            .flatMap { match -> NSRange? in
                if match.numberOfRanges < 2 { return nil }

                // check first captured range
                let firstRange = match.rangeAtIndex(1)
                let violationRange = NSRange(location: NSMaxRange(firstRange), length: 0)

                guard let matchByteFirstRange = contents
                    .NSRangeToByteRange(start: firstRange.location, length: firstRange.length)
                    else { return nil }

                let tokensInFirstRange = syntaxMap.tokensIn(matchByteFirstRange)

                // If not empty, first captured range is comment, string, keyword or typeidentifier.
                // We checks "not empty" because tokens may empty without filtering.
                let tokensInFirstRangeExcludingSyntaxKindsOnly = tokensInFirstRange.filter({
                    ForceUnwrappingRule.excludingSyntaxKindsForFirstCapture.contains($0.type)
                })
                if !tokensInFirstRangeExcludingSyntaxKindsOnly.isEmpty { return nil }

                // if first captured range is identifier, generate violation
                if tokensInFirstRange.map({ $0.type }).contains(SyntaxKind.Identifier.rawValue) {
                    return violationRange
                }

                // check firstCapturedString is ")"
                let firstCapturedString = nsstring.substringWithRange(firstRange)
                if firstCapturedString == ")" { return violationRange }

                // check second capture
                if match.numberOfRanges == 3 {

                    // check second captured range
                    let secondRange = match.rangeAtIndex(2)
                    guard let matchByteSecondRange = contents
                        .NSRangeToByteRange(start: secondRange.location, length: secondRange.length)
                        else { return nil }

                    let tokensInSecondRange = syntaxMap.tokensIn(matchByteSecondRange).filter {
                        ForceUnwrappingRule.excludingSyntaxKindsForSecondCapture.contains($0.type)
                    }
                    // If not empty, second captured range is identifier.
                    // "!" is "operator prefix !".
                    if !tokensInSecondRange.isEmpty { return nil }
                }

                // check structure
                if checkStructure(file, byteRange: matchByteFirstRange) {
                    return violationRange
                } else {
                    return nil
                }
        }
    }

    // Returns if range should generate violation
    // check deepest kind matching range in structure
    private func checkStructure(file: File, byteRange: NSRange) -> Bool {
        let nsstring = file.contents as NSString
        let kinds = file.structure.kindsFor(byteRange.location)
        if let lastKind = kinds.last {
            switch lastKind.kind {
            // range is in some "source.lang.swift.decl.var.*"
            case SwiftDeclarationKind.VarClass.rawValue: fallthrough
            case SwiftDeclarationKind.VarGlobal.rawValue: fallthrough
            case SwiftDeclarationKind.VarInstance.rawValue: fallthrough
            case SwiftDeclarationKind.VarStatic.rawValue:
                let byteOffset = lastKind.byteRange.location
                let byteLength = byteRange.location - byteOffset
                if let varDeclarationString = nsstring
                    .substringWithByteRange(start: byteOffset, length: byteLength)
                    where varDeclarationString.containsString("=") {
                        // if declarations contains "=", range is not type annotation
                        return true
                } else {
                    // range is type annotation of declaration
                    return false
                }
            // followings have invalid "key.length" returned from SourceKitService w/ Xcode 7.2.1
//            case SwiftDeclarationKind.VarParameter.rawValue: fallthrough
//            case SwiftDeclarationKind.VarLocal.rawValue: fallthrough
            default:
                break
            }
        }
        return false
    }
}
