//
//  MissingDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/15/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

private func mappedDictValues(fromDictionary dictionary: [String: SourceKitRepresentable], key: String,
                              subKey: String) -> [String] {
    return (dictionary[key] as? [SourceKitRepresentable])?.flatMap({
        ($0 as? [String: SourceKitRepresentable]) as? [String: String]
    }).flatMap({ $0[subKey] }) ?? []
}

private func declarationOverrides(in dictionary: [String: SourceKitRepresentable]) -> Bool {
    return dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.override")
}

private func inheritedMembers(for dictionary: [String: SourceKitRepresentable]) -> [String] {
    return mappedDictValues(fromDictionary: dictionary, key: "key.inheritedtypes", subKey: "key.name").flatMap {
        File.allDeclarationsByType[$0] ?? []
    }
}

extension File {
    fileprivate func missingDocOffsets(in dictionary: [String: SourceKitRepresentable],
                                       acl: [AccessControlLevel], skipping: [String] = []) -> [Int] {
        if declarationOverrides(in: dictionary) {
            return []
        }
        if let name = dictionary.name, skipping.contains(name) {
            return []
        }
        let inherited = inheritedMembers(for: dictionary)
        let substructureOffsets = dictionary.substructure.flatMap {
            missingDocOffsets(in: $0, acl: acl, skipping: inherited)
        }
        guard (dictionary.kind).flatMap(SwiftDeclarationKind.init) != nil,
            let offset = dictionary.offset,
            let accessibility = dictionary.accessibility,
            acl.map({ $0.rawValue }).contains(accessibility) else {
                return substructureOffsets
        }
        if parseDocumentationCommentBody(dictionary, syntaxMap: syntaxMap) != nil {
            return substructureOffsets
        }
        return substructureOffsets + [offset]
    }
}

public enum AccessControlLevel: String, CustomStringConvertible {
    case Private = "source.lang.swift.accessibility.private"
    case FilePrivate = "source.lang.swift.accessibility.fileprivate"
    case Internal = "source.lang.swift.accessibility.internal"
    case Public = "source.lang.swift.accessibility.public"
    case Open = "source.lang.swift.accessibility.open"

    internal init?(description value: String) {
        switch value {
        case "private": self = .Private
        case "fileprivate": self = .FilePrivate
        case "internal": self = .Internal
        case "public": self = .Public
        case "open": self = .Open
        default: return nil
        }
    }

    init?(identifier value: String) {
        self.init(rawValue: value)
    }

    public var description: String {
        switch self {
        case .Private: return "private"
        case .FilePrivate: return "fileprivate"
        case .Internal: return "internal"
        case .Public: return "public"
        case .Open: return "open"
        }
    }

    // Returns true if is `private` or `fileprivate`
    var isPrivate: Bool {
        return self == .Private || self == .FilePrivate
    }

}

public struct MissingDocsRule: OptInRule {
    public init(configuration: Any) throws {
        guard let array = [String].array(of: configuration) else {
            throw ConfigurationError.unknownConfiguration
        }
        let acl = array.flatMap(AccessControlLevel.init(description:))
        parameters = zip([.warning, .error], acl).map(RuleParameter<AccessControlLevel>.init)
    }

    public var configurationDescription: String {
        return parameters.map({
            "\($0.severity.rawValue): \($0.value.rawValue)"
        }).joined(separator: ", ")
    }

    public init() {
        parameters = [RuleParameter(severity: .warning, value: .Public),
                      RuleParameter(severity: .warning, value: .Open)]
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

    public func validate(file: File) -> [StyleViolation] {
        let acl = parameters.map { $0.value }
        return file.missingDocOffsets(in: file.structure.dictionary, acl: acl).map {
            StyleViolation(ruleDescription: type(of: self).description,
                location: Location(file: file, byteOffset: $0))
        }
    }

    public func isEqualTo(_ rule: Rule) -> Bool {
        if let rule = rule as? MissingDocsRule {
            return rule.parameters == parameters
        }
        return false
    }
}
