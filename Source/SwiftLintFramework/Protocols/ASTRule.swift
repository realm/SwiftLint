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
    func validate(file: File, kind: KindType, dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]
}

extension ASTRule where KindType.RawValue == String {
    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structure.dictionary)
    }

    public func validate(file: File, dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict)

            if let kindString = subDict.kind,
                let kind = KindType(rawValue: kindString) {
                violations += validate(file: file, kind: kind, dictionary: subDict)
            }

            return violations
        }
    }
}
