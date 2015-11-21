//
//  ValidDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-21.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

extension File {
    private func invalidDocOffsets(dictionary: XPCDictionary) -> [Int] {
        let substructure = (dictionary["key.substructure"] as? XPCArray)?
            .flatMap { $0 as? XPCDictionary }
        let substructureOffsets = substructure?.flatMap(invalidDocOffsets) ?? []
        guard let kind = (dictionary["key.kind"] as? String).flatMap(SwiftDeclarationKind.init),
            offset = dictionary["key.offset"] as? Int64,
            bodyOffset = dictionary["key.bodyoffset"] as? Int64
            where kind != .VarParameter else {
                return substructureOffsets
        }
        let declaration = contents[Int(offset)..<Int(bodyOffset)]
        if let comment = getDocumentationCommentBody(dictionary, syntaxMap: syntaxMap)
            where !comment.containsString(":nodoc:") {
            let parameterNames = substructure?.filter {
                ($0["key.kind"] as? String).flatMap(SwiftDeclarationKind.init) == .VarParameter
            }.filter { subDict in
                return (subDict["key.offset"] as? Int64).map({ $0 < bodyOffset }) ?? false
            }.flatMap {
                $0["key.name"] as? String
            } ?? []
            let parameters = parameterNames.map { parameter -> (label: String, parameter: String) in
                let fullRange = NSRange(location: 0, length: Int(bodyOffset - offset))
                let firstMatch = regex("([^,\\s(]+)\\s+\(parameter)\\s*:")
                    .firstMatchInString(declaration, options: [], range: fullRange)
                if let match = firstMatch {
                    let label = (declaration as NSString).substringWithRange(match.rangeAtIndex(1))
                    return (label, parameter)
                }
                return (parameter, parameter)
            }
            let undocumentedParameters = parameters.filter {
                !comment.containsString("- parameter \($0.label):") &&
                    !comment.containsString("- parameter \($0.parameter):")
            }
            if !undocumentedParameters.isEmpty {
                return substructureOffsets + [Int(offset)]
            }
        }
        return substructureOffsets
    }
}

public struct ValidDocsRule: Rule {
    public static let description = RuleDescription(
        identifier: "valid_docs",
        name: "Valid Docs",
        description: "Documented declarations should be valid.",
        nonTriggeringExamples: [
            "/// docs\npublic func a() {}\n",
            "/// docs\n/// - parameter param: this is void\npublic func a(param: Void) {}\n",
            "/// docs\n/// - parameter label: this is void\npublic func a(label param: Void) {}",
            "/// docs\n/// - parameter param: this is void\npublic func a(label param: Void) {}",
        ],
        triggeringExamples: [
            "/// docs\npublic func a(param: Void) {}\n",
            "/// docs\n/// - parameter invalid: this is void\npublic func a(label param: Void) {}",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.invalidDocOffsets(file.structure.dictionary).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: $0))
        }
    }
}
