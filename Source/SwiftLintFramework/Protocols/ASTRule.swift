//
//  ASTRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol ASTBaseRule: Rule {
    func validateFile(file: File, kind: String,
                      dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]
}

extension ASTBaseRule {
    public func validateFile(file: File) -> [StyleViolation] {
        return validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(file: File, dictionary: [String: SourceKitRepresentable]) ->
                             [StyleViolation] {
        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { subItem -> [StyleViolation] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                kindString = subDict["key.kind"] as? String else {
                    return []
            }
            return self.validateFile(file, dictionary: subDict) +
                self.validateFile(file, kind: kindString, dictionary: subDict)
        }
    }
}

public protocol ASTRule: ASTBaseRule {
    func validateFile(file: File, kind: SwiftDeclarationKind,
                      dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]
}

extension ASTRule {
    public func validateFile(file: File, kind: String,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let kind = SwiftDeclarationKind(rawValue: kind) else {
            return []
        }
        return self.validateFile(file, kind: kind, dictionary: dictionary)
    }

}
