//
//  ForceCastRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

struct ForceCastRule: Rule {
    let identifier = "force_cast"
    let parameters = [RuleParameter<Void>]()

    func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("as!", withSyntaxKinds: [.Keyword]).map { range in
            return StyleViolation(type: .ForceCast,
                location: Location(file: file, offset: range.location),
                severity: .High,
                reason: "Force casts should be avoided")
        }
    }
}
