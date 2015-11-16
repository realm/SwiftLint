//
//  MissingDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/15/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

private func missingDocOffsets(dictionary: XPCDictionary) -> [Int] {
    let substructureOffsets = (dictionary["key.substructure"] as? XPCArray)?
        .flatMap { $0 as? XPCDictionary }
        .flatMap(missingDocOffsets) ?? []
    let docAttribute = "source.decl.attribute.__raw_doc_comment"
    guard let _ = (dictionary["key.kind"] as? String).flatMap(SwiftDeclarationKind.init),
        offset = dictionary["key.offset"] as? Int64,
        accessibility = dictionary["key.accessibility"] as? String
        where accessibility == "source.lang.swift.accessibility.public" &&
            String(dictionary["key.attributes"]).rangeOfString(docAttribute) == nil else {
                return substructureOffsets
    }
    return substructureOffsets + [Int(offset)]
}

public struct MissingDocsRule: Rule {
    public init() {}

    public static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Public declarations should be documented.",
        nonTriggeringExamples: [
            "/// docs\npublic func a() {}\n",
            "/** docs */\npublic func a() {}\n",
            "// regular comment\nfunc a() {}\n",
            "/* regular comment */\nfunc a() {}\n",
            "func a() {}\n",
            "internal func a() {}\n",
            "private func a() {}\n"
        ],
        triggeringExamples: [
            "public func a() {}\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return missingDocOffsets(Structure(file: file).dictionary).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, byteOffset: $0))
        }
    }
}
