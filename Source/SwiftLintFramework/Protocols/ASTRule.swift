//
//  ASTRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol ASTRule: Rule {
    associatedtype KindType: RawRepresentable
    func validateFile(file: File, kind: KindType,
                      dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]
}

extension ASTRule where KindType.RawValue == String {
    public func validateFile(file: File) -> [StyleViolation] {
        return validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(file: File, dictionary: [String: SourceKitRepresentable]) ->
                             [StyleViolation] {
        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { subItem -> [StyleViolation] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                kindString = subDict["key.kind"] as? String,
                kind = KindType(rawValue: kindString) else {
                    return []
            }
            return self.validateFile(file, dictionary: subDict) +
                self.validateFile(file, kind: kind, dictionary: subDict)
        }
    }
}

extension String: RawRepresentable {
    public init?(rawValue: String) {
        self.init(rawValue)
    }

    public var rawValue: String {
        return self
    }
}
