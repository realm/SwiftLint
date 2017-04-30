//
//  ExplicitInternalTopLevelRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 4/28/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitInternalTopLevelRule: OptInRule, ConfigurationProviderRule {
    public init() {}
    public var configuration = SeverityConfiguration(.warning)
        public static let description = RuleDescription(
        identifier: "explicit_internal_toplevel",
        name: "Explicit Internal Top-level Rule",
        description: "Top-level type declerations should specify Access Control Labels.",
        nonTriggeringExamples: [
            "internal enum A {}\n",
            "public final class B {}\n",
            "private struct C {}\n",
            "internal enum A {\n enum A {}\n}"
        ],
        triggeringExamples: [
            "enum A {}\n",
            "final class B {}\n",
            "struct C {}\n"
        ]
    )

    private func isAccessControl(_ label: SyntaxToken, in file: File ) -> Bool {
         let accessLabels = Set(["open", "public", "internal", "fileprivate", "private"])
         let attibute = file.contents.bridge().substringWithByteRange(start: label.offset, length: label.length) ?? ""
         return accessLabels.contains(attibute)
     }

    public func validate(file: File) -> [StyleViolation] {
        var internalStructures = [[String: SourceKitRepresentable]]()
        typealias ArrayDict = [[String: SourceKitRepresentable]]
        guard let structure = file.structure.dictionary["key.substructure"] as? ArrayDict else { return [] }

        // We collect all the implicit and explicit internal structures
        for each in structure {
            guard let access = each["key.accessibility"] as? String,
                access == "source.lang.swift.accessibility.internal"
                else { continue }
            internalStructures.append(each)
        }
        // Bail out if there are not implicit or explicit internal declarations
        guard !internalStructures.isEmpty else { return [] }

        // Find all top-level declarations with different whitespace including \n
        let pattern = "\\s*(?:class|(final\\s+class)|struct|enum)\\s+"
        let filterOut = SyntaxKind.commentAndStringKinds()
        let topLevelDeclByteRanges = file.match(pattern: pattern,
                            excludingSyntaxKinds: filterOut ).flatMap({
                            file.contents.bridge().NSRangeToByteRange(
                            start: $0.location, length: $0.length)
                            })
        // Find all implicitly internal or structures lacking ACL
        var implicitInternalByteRanges = [NSRange]()
        // We are ignoring violations starting at 0 index in order to simplify
        for each in topLevelDeclByteRanges where each.location > 0 {
             let tokens = file.syntaxMap.tokens(inByteRange: NSRange(location: each.location - 1, length: each.length))

            // Filter out explicit access control labels
            // This should also handle the case when empty
            let builtin = "source.lang.swift.syntaxtype.attribute.builtin"
            guard let label = tokens.first( where: { $0.type == builtin })
                else {
                // if it doesn't find a builtin label then internal is implicit
                        implicitInternalByteRanges.append(each)
                        continue
                     }

            if !isAccessControl(label, in: file) {
                // Assuming that the label found is not an ACL
                implicitInternalByteRanges.append(each)
                continue
            }
        } //end of topLevelDeclByteRanges loop

        // Match the implicit internal to the top-level declarations
        var violations = [StyleViolation]()
        for each in internalStructures {
            guard let start = each["key.offset"] as? NSNumber else { continue }
            let range = NSRange(location: start.intValue, length: 1)
            if range.intersects(implicitInternalByteRanges) {
                violations.append(StyleViolation(ruleDescription: ExplicitInternalTopLevelRule.description,
                severity: self.configuration.severity,
                location: Location(file: file, byteOffset: start.intValue)))
           }
        }
        return violations
    }
}
