//
//  ForceUnwrappingRule.swift
//  SwiftLint
//
//  Created by Benjamin Otto on 14/01/16.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ForceUnwrappingRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_unwrapping",
        name: "Force Unwrapping",
        description: "Force unwrapping should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "if let url = NSURL(string: query)",
            "navigationController?.pushViewController(viewController, animated: true)",
            "let s as! Test",
            "try! canThrowErrors()",
            "let object: Any!",
            "@IBOutlet var constraints: [NSLayoutConstraint]!",
            "setEditing(!editing, animated: true)",
            "navigationController.setNavigationBarHidden(!navigationController." +
                "navigationBarHidden, animated: true)",
            "if addedToPlaylist && (!self.selectedFilters.isEmpty || " +
                "self.searchBar?.text?.isEmpty == false) {}",
            "print(\"\\(xVar)!\")",
            "var test = (!bar)",
            "var a: [Int]!",
            "private var myProperty: (Void -> Void)!",
            "func foo(_ options: [AnyHashable: Any]!) {"
        ],
        triggeringExamples: [
            "let url = NSURL(string: query)↓!",
            "navigationController↓!.pushViewController(viewController, animated: true)",
            "let unwrapped = optional↓!",
            "return cell↓!",
            "let url = NSURL(string: \"http://www.google.com\")↓!",
            "let dict = [\"Boooo\": \"👻\"]func bla() -> String { return dict[\"Boooo\"]↓! }",
            "let dict = [\"Boooo\": \"👻\"]func bla() -> String { return dict[\"Boooo\"]↓!.contains(\"B\") }",
            "let a = dict[\"abc\"]↓!.contains(\"B\")",
            "dict[\"abc\"]↓!.bar(\"B\")",
            "if dict[\"a\"]↓!!!! {",
            "var foo: [Bool]! = dict[\"abc\"]↓!",
            "context(\"abc\") {\n" +
            "  var foo: [Bool]! = dict[\"abc\"]↓!\n" +
            "}",
            "open var computed: String { return foo.bar↓! }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // capture previous of "!"
    // http://userguide.icu-project.org/strings/regexp
    private static let pattern = "([^\\s\\p{Ps}])(!+)"
    // Match any variable declaration
    // Has a small bug in @IBOutlet due suffix "let"
    // But that does not compromise the filtering for var declarations
    private static let varDeclarationPattern = "\\s?(?:let|var)\\s+[^=\\v{]*!"

    private static let regularExpression = regex(pattern)
    private static let varDeclarationRegularExpression = regex(varDeclarationPattern)
    private static let excludingSyntaxKindsForFirstCapture =
        SyntaxKind.commentAndStringKinds.union([.keyword, .typeidentifier])
    private static let excludingSyntaxKindsForSecondCapture = SyntaxKind.commentAndStringKinds

    private func violationRanges(in file: File) -> [NSRange] {
        let contents = file.contents
        let nsstring = contents.bridge()
        let range = NSRange(location: 0, length: nsstring.length)
        let syntaxMap = file.syntaxMap

        let varDeclarationRanges = ForceUnwrappingRule.varDeclarationRegularExpression
            .matches(in: contents, options: [], range: range)
            .flatMap { match -> NSRange? in
                return match.range
            }

        return ForceUnwrappingRule.regularExpression
            .matches(in: contents, options: [], range: range)
            .flatMap { match -> NSRange? in
                if match.range.intersects(varDeclarationRanges) {
                    return nil
                }

                return violationRange(match: match, nsstring: nsstring, syntaxMap: syntaxMap, file: file)
            }
    }

    private func violationRange(match: NSTextCheckingResult, nsstring: NSString, syntaxMap: SyntaxMap,
                                file: File) -> NSRange? {
        if match.numberOfRanges < 3 { return nil }

        let firstRange = match.range(at: 1)
        let secondRange = match.range(at: 2)

        guard let matchByteFirstRange = nsstring
            .NSRangeToByteRange(start: firstRange.location, length: firstRange.length),
            let matchByteSecondRange = nsstring
                .NSRangeToByteRange(start: secondRange.location, length: secondRange.length)
            else { return nil }

        let kindsInFirstRange = syntaxMap.kinds(inByteRange: matchByteFirstRange)

        // check first captured range
        // If not empty, first captured range is comment, string, keyword or typeidentifier.
        // We checks "not empty" because kinds may empty without filtering.
        guard !kindsInFirstRange
            .contains(where: ForceUnwrappingRule.excludingSyntaxKindsForFirstCapture.contains) else {
                return nil
        }

        let violationRange = NSRange(location: NSMaxRange(firstRange), length: 0)

        // if first captured range is identifier, generate violation
        if kindsInFirstRange.contains(.identifier) {
            return violationRange
        }

        // check if firstCapturedString is either ")" or "]" 
        // and '!' is not within comment or string
        // and matchByteFirstRange is not a type annotation
        let firstCapturedString = nsstring.substring(with: firstRange)
        if [")", "]"].contains(firstCapturedString) {
            // check second capture '!'
            let kindsInSecondRange = syntaxMap.kinds(inByteRange: matchByteSecondRange)
            let forceUnwrapNotInCommentOrString = !kindsInSecondRange
                .contains(where: ForceUnwrappingRule.excludingSyntaxKindsForSecondCapture.contains)
            if forceUnwrapNotInCommentOrString &&
                !isTypeAnnotation(in: file, contents: nsstring, byteRange: matchByteFirstRange) {
                return violationRange
            }
        }

        return nil
    }

    // check deepest kind matching range in structure is a typeAnnotation
    private func isTypeAnnotation(in file: File, contents: NSString, byteRange: NSRange) -> Bool {
        let kinds = file.structure.kinds(forByteOffset: byteRange.location)
        guard let lastItem = kinds.last,
            let lastKind = SwiftDeclarationKind(rawValue: lastItem.kind),
            SwiftDeclarationKind.variableKinds.contains(lastKind) else {
                return false
        }

        // range is in some "source.lang.swift.decl.var.*"
        let byteOffset = lastItem.byteRange.location
        let byteLength = byteRange.location - byteOffset
        if let varDeclarationString = contents.substringWithByteRange(start: byteOffset, length: byteLength),
            varDeclarationString.contains("=") {
            // if declarations contains "=", range is not type annotation
            return false
        }

        // range is type annotation of declaration
        return true
    }
}
