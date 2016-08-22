//
//  MissingDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/15/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

private func mappedDictValues(dictionary: [String: SourceKitRepresentable], key: String,
                              subKey: String) -> [String] {
    return (dictionary[key] as? [SourceKitRepresentable])?.flatMap({
        ($0 as? [String: SourceKitRepresentable]) as? [String: String]
    }).flatMap({ $0[subKey] }) ?? []
}

private func declarationOverrides(dictionary: [String: SourceKitRepresentable]) -> Bool {
    return mappedDictValues(dictionary, key: "key.attributes", subKey: "key.attribute")
        .contains("source.decl.attribute.override")
}

private func inheritedMembersForDictionary(dictionary: [String: SourceKitRepresentable]) ->
                                           [String] {
    return mappedDictValues(dictionary, key: "key.inheritedtypes", subKey: "key.name").flatMap {
        File.allDeclarationsByType[$0] ?? []
    }
}

extension File {
    private func missingDocOffsets(dictionary: [String: SourceKitRepresentable],
                                   acl: [AccessControlLevel], skipping: [String] = []) -> [Int] {
        if declarationOverrides(dictionary) {
            return []
        }
        if let name = dictionary["key.name"] as? String where skipping.contains(name) {
            return []
        }
        let inheritedMembers = inheritedMembersForDictionary(dictionary)
        let substructureOffsets = (dictionary["key.substructure"] as? [SourceKitRepresentable])?
            .flatMap { $0 as? [String: SourceKitRepresentable] }
            .flatMap({ self.missingDocOffsets($0, acl: acl, skipping: inheritedMembers) }) ?? []
        guard let _ = (dictionary["key.kind"] as? String).flatMap(SwiftDeclarationKind.init),
            offset = dictionary["key.offset"] as? Int64,
            accessibility = dictionary["key.accessibility"] as? String
            where acl.map({ $0.rawValue }).contains(accessibility) else {
                return substructureOffsets
        }
        if getDocumentationCommentBody(dictionary, syntaxMap: syntaxMap) != nil {
            return substructureOffsets
        }
        return substructureOffsets + [Int(offset)]
    }
}

public enum AccessControlLevel: String, CustomStringConvertible {
    case Private = "source.lang.swift.accessibility.private"
    case Internal = "source.lang.swift.accessibility.internal"
    case Public = "source.lang.swift.accessibility.public"

    internal init?(description value: String) {
        switch value {
        case "private": self = .Private
        case "internal": self = .Internal
        case "public": self = .Public
        default: return nil
        }
    }

    public var description: String {
        switch self {
        case Private: return "private"
        case Internal: return "internal"
        case Public: return "public"
        }
    }
}

public struct MissingDocsRule: OptInRule {
    public init(configuration: AnyObject) throws {
        guard let array = [String].arrayOf(configuration) else {
            throw ConfigurationError.UnknownConfiguration
        }
        let acl = array.flatMap(AccessControlLevel.init(description:))
        parameters = zip([.Warning, .Error], acl).map(RuleParameter<AccessControlLevel>.init)
    }

    public var configurationDescription: String {
        return parameters.map({
            "\($0.severity.rawValue.lowercaseString): \($0.value.rawValue)"
        }).joinWithSeparator(", ")
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

    public func isEqualTo(rule: Rule) -> Bool {
        if let rule = rule as? MissingDocsRule {
            return rule.parameters == self.parameters
        }
        return false
    }
}
