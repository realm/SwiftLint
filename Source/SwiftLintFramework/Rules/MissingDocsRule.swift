//
//  MissingDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 11/15/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

internal extension File {
    func missingDocOffsets(in dictionary: [String: SourceKitRepresentable],
                           acls: [AccessControlLevel]) -> [(Int, AccessControlLevel)] {
        if dictionary.enclosedSwiftAttributes.contains(.override) ||
            !dictionary.inheritedTypes.isEmpty {
            return []
        }
        let substructureOffsets = dictionary.substructure.flatMap {
            missingDocOffsets(in: $0, acls: acls)
        }
        guard (dictionary.kind).flatMap(SwiftDeclarationKind.init) != nil,
            let offset = dictionary.offset,
            let accessibility = dictionary.accessibility,
            let acl = AccessControlLevel(identifier: accessibility),
            acls.contains(acl) else {
                return substructureOffsets
        }
        if dictionary.docLength != nil {
            return substructureOffsets
        }
        return substructureOffsets + [(offset, acl)]
    }
}

public struct MissingDocsRule: OptInRule {
    public init(configuration: Any) throws {
        guard let dict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        parameters = try dict.flatMap { (key: String, value: Any) -> [RuleParameter<AccessControlLevel>] in
            guard let severity = ViolationSeverity(rawValue: key) else {
                throw ConfigurationError.unknownConfiguration
            }
            if let array = [String].array(of: value) {
                return try array.map {
                    guard let acl = AccessControlLevel(description: $0) else {
                        throw ConfigurationError.unknownConfiguration
                    }
                    return RuleParameter<AccessControlLevel>(severity: severity, value: acl)
                }
            } else if let string = value as? String, let acl = AccessControlLevel(description: string) {
                return [RuleParameter<AccessControlLevel>(severity: severity, value: acl)]
            }
            throw ConfigurationError.unknownConfiguration
        }
    }

    public var configurationDescription: String {
        return parameters.map({
            "\($0.severity.rawValue): \($0.value.rawValue)"
        }).joined(separator: ", ")
    }

    public init() {
        parameters = [RuleParameter(severity: .warning, value: .public),
                      RuleParameter(severity: .warning, value: .open)]
    }

    public let parameters: [RuleParameter<AccessControlLevel>]

    public static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Declarations should be documented.",
        kind: .lint,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
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
        let acls = parameters.map { $0.value }
        return file.missingDocOffsets(in: file.structure.dictionary,
                                      acls: acls).map { (offset: Int, acl: AccessControlLevel) in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: parameters.first { $0.value == acl }?.severity ?? .warning,
                           location: Location(file: file, byteOffset: offset),
                           reason: "\(acl.description) declarations should be documented.")
        }
    }

    public func isEqualTo(_ rule: Rule) -> Bool {
        if let rule = rule as? MissingDocsRule {
            return rule.parameters == parameters
        }
        return false
    }
}
