//
//  MissingDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/15/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

private func dictArrayForDictionary(dictionary: XPCDictionary, key: String) -> [[String: String]]? {
    return (dictionary[key] as? XPCArray)?.flatMap {
        ($0 as? XPCDictionary) as? [String: String]
    }
}

private func declarationOverrides(dictionary: XPCDictionary) -> Bool {
    return dictArrayForDictionary(dictionary, key: "key.attributes")?.flatMap {
        $0["key.attribute"]
    }.contains("source.decl.attribute.override") ?? false
}

private func inheritedMembersForDictionary(dictionary: XPCDictionary) -> [String] {
    return dictArrayForDictionary(dictionary, key: "key.inheritedtypes")?.flatMap {
        $0["key.name"]
    }.flatMap { File.allDeclarationsByType[$0] ?? [] } ?? []
}

extension File {
    private func missingDocOffsets(dictionary: XPCDictionary, acl: [AccessControlLevel],
                                   skipping: [String] = []) -> [Int] {
        if declarationOverrides(dictionary) {
            return []
        }
        if let name = dictionary["key.name"] as? String where skipping.contains(name) {
            return []
        }
        let inheritedMembers = inheritedMembersForDictionary(dictionary)
        let substructureOffsets = (dictionary["key.substructure"] as? XPCArray)?
            .flatMap { $0 as? XPCDictionary }
            .flatMap({ self.missingDocOffsets($0, acl: acl, skipping: inheritedMembers) }) ?? []
        guard let _ = (dictionary["key.kind"] as? String).flatMap(SwiftDeclarationKind.init),
            offset = dictionary["key.offset"] as? Int64,
            accessibility = dictionary["key.accessibility"] as? String
            where acl.map({ $0.sourcekitValue() }).contains(accessibility) else {
                return substructureOffsets
        }
        if getDocumentationCommentBody(dictionary, syntaxMap: syntaxMap) != nil {
            return substructureOffsets
        }
        return substructureOffsets + [Int(offset)]
    }
}

public enum AccessControlLevel: String {
    case Private = "private"
    case Internal = "internal"
    case Public = "public"

    private func sourcekitValue() -> String {
        switch self {
            case Private: return "source.lang.swift.accessibility.private"
            case Internal: return "source.lang.swift.accessibility.internal"
            case Public: return "source.lang.swift.accessibility.public"
        }
    }
}

public struct MissingDocsRule: ConfigurableRule, OptInRule {
    public init?(config: AnyObject) {
        guard let array = [String].arrayOf(config) else {
            return nil
        }
        let acl = array.flatMap(AccessControlLevel.init)
        parameters = zip([.Warning, .Error], acl).map(RuleParameter<AccessControlLevel>.init)
    }

    public init() {
        parameters = [RuleParameter(severity: .Warning, value: .Public)]
    }

    public let parameters: [RuleParameter<AccessControlLevel>]

    public static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Public declarations should be documented.",
        nonTriggeringExamples: [
            // public, documented using /// docs
            "/// docs\npublic func a() {}\n",
            // public, documented using /** docs */
            "/** docs */\npublic func a() {}\n",
            // internal (implicit), undocumented
            "func a() {}\n",
            // internal (explicit), undocumented
            "internal func a() {}\n",
            // private, undocumented
            "private func a() {}\n",
            // internal (implicit), undocumented
            "// regular comment\nfunc a() {}\n",
            // internal (implicit), undocumented
            "/* regular comment */\nfunc a() {}\n",
            // protocol member is documented, but inherited member is not
            "/// docs\npublic protocol A {\n/// docs\nvar b: Int { get } }\n" +
                "/// docs\npublic struct C: A {\npublic let b: Int\n}",
            // locally-defined superclass member is documented, but subclass member is not
            "/// docs\npublic class A {\n/// docs\npublic func b() {}\n}\n" +
                "/// docs\npublic class B: A { override public func b() {} }\n",
            // externally-defined superclass member is documented, but subclass member is not
            "import Foundation\n/// docs\npublic class B: NSObject {\n" +
                "// no docs\noverride public var description: String { fatalError() } }\n"
        ],
        triggeringExamples: [
            // public, undocumented
            "public func a() {}\n",
            // public, undocumented
            "// regular comment\npublic func a() {}\n",
            // public, undocumented
            "/* regular comment */\npublic func a() {}\n",
            // protocol member and inherited member are both undocumented
            "/// docs\npublic protocol A {\n// no docs\nvar b: Int { get } }\n" +
                "/// docs\npublic struct C: A {\n\npublic let b: Int\n}"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let acl = parameters.map { $0.value }
        return file.missingDocOffsets(file.structure.dictionary, acl: acl).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, byteOffset: $0))
        }
    }

    public func isEqualTo(rule: ConfigurableRule) -> Bool {
        if let rule = rule as? MissingDocsRule {
            return rule.parameters == self.parameters
        }
        return false
    }
}
