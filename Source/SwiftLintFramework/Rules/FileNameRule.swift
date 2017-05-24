//
//  FileNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

private let typeAndExtensionKinds = SwiftDeclarationKind.typeKinds() + [.extension]

extension Dictionary where Key: ExpressibleByStringLiteral {
    fileprivate func recursiveDeclaredTypeNames() -> [String] {
        let subNames = substructure.flatMap { $0.recursiveDeclaredTypeNames() }
        if let kindString = kind, let theKind = SwiftDeclarationKind(rawValue: kindString),
            typeAndExtensionKinds.contains(theKind), let theName = name {
            return [theName] + subNames
        }
        return subNames
    }
}

public struct FileNameRule: ConfigurationProviderRule, OptInRule {
    public var configuration = FileNameConfiguration(severity: .warning, excluded: ["main.swift"])

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_name",
        name: "File Name",
        description: "File name should match a type declared in the file (if any)."
    )

    public func validate(file: File) -> [StyleViolation] {
        guard let filePath = file.path,
            case let fileName = filePath.bridge().lastPathComponent,
            !configuration.excluded.contains(fileName) else {
            return []
        }

        let allDeclaredTypeNames = file.structure.dictionary.recursiveDeclaredTypeNames()
        guard !allDeclaredTypeNames.isEmpty,
            !allDeclaredTypeNames.contains(where: fileName.contains) else {
            return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity.severity,
                               location: Location(file: filePath, line: 1))]
    }
}

public struct FileNameConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "excluded: \(excluded.sorted())"
    }

    private(set) public var severity: SeverityConfiguration
    private(set) public var excluded: Set<String>

    public init(severity: ViolationSeverity, excluded: [String] = []) {
        self.severity = SeverityConfiguration(severity)
        self.excluded = Set(excluded)
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityConfiguration = configurationDict["severity"] {
            try severity.apply(configuration: severityConfiguration)
        }
        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excluded = Set(excluded)
        }
    }
}

public func == (lhs: FileNameConfiguration, rhs: FileNameConfiguration) -> Bool {
    return lhs.severity == rhs.severity &&
        lhs.excluded == rhs.excluded
}
