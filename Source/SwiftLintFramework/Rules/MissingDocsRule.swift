//
//  MissingDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/15/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

extension File {
    private func missingDocOffsets(dictionary: XPCDictionary, acl: [AccessControlLevel]) -> [Int] {
        let substructureOffsets = (dictionary["key.substructure"] as? XPCArray)?
            .flatMap { $0 as? XPCDictionary }
            .flatMap({ self.missingDocOffsets($0, acl: acl) }) ?? []
        guard let _ = (dictionary["key.kind"] as? String).flatMap(SwiftDeclarationKind.init),
            offset = dictionary["key.offset"] as? Int64,
            accessibility = dictionary["key.accessibility"] as? String
            where acl.map({ $0.rawValue }).contains(accessibility) else {
                return substructureOffsets
        }
        if let comment = getDocumentationCommentBody(dictionary, syntaxMap: syntaxMap) {
            return substructureOffsets
        }
        return substructureOffsets + [Int(offset)]
    }
}

public enum AccessControlLevel: String {
    case Private = "source.lang.swift.accessibility.private"
    case Internal = "source.lang.swift.accessibility.internal"
    case Public = "source.lang.swift.accessibility.public"
}

public struct MissingDocsRule: ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: .Public),
        ])
    }

    public init(parameters: [RuleParameter<AccessControlLevel>]) {
        self.parameters = parameters
    }

    public let parameters: [RuleParameter<AccessControlLevel>]

    public static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Public declarations should be documented.",
        nonTriggeringExamples: [
            "/// docs\npublic func a() {}\n",
            "/** docs */\npublic func a() {}\n",
            "func a() {}\n",
            "internal func a() {}\n",
            "private func a() {}\n",
            "// regular comment\nfunc a() {}\n",
            "/* regular comment */\nfunc a() {}\n"
        ],
        triggeringExamples: [
            "public func a() {}\n",
            "// regular comment\npublic func a() {}\n",
            "/* regular comment */\npublic func a() {}\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let acl = parameters.map({$0.value})
        return file.missingDocOffsets(file.structure.dictionary, acl: acl).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, byteOffset: $0))
        }
    }
}
