//
//  ASTRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol ASTRule: Rule {
    associatedtype KindType: RawRepresentable
    func validateFile(_ file: File, kind: KindType,
                      dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]
}

extension ASTRule where KindType.RawValue == String {
    public func validateFile(_ file: File) -> [StyleViolation] {
        return validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(_ file: File, dictionary: [String: SourceKitRepresentable]) ->
                             [StyleViolation] {
        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { subItem -> [StyleViolation] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                let kindString = subDict["key.kind"] as? String,
                let kind = KindType(rawValue: kindString) else {
                    return []
            }
            return validateFile(file, dictionary: subDict) +
                validateFile(file, kind: kind, dictionary: subDict)
        }
    }
}
