//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

struct ColonRule: Rule {
    static let identifier = "colon"
    static let parameters = [RuleParameter<Void>]()

    static func validateFile(file: File) -> [StyleViolation] {
        let pattern1 = file.matchPattern("\\w+\\s+:\\s*\\S+",
            withSyntaxKinds: [.Identifier, .Typeidentifier])
        let pattern2 = file.matchPattern("\\w+:(?:\\s{0}|\\s{2,})\\S+",
            withSyntaxKinds: [.Identifier, .Typeidentifier])
        return (pattern1 + pattern2).map { range in
            return StyleViolation(type: .Colon,
                location: Location(file: file, offset: range.location),
                severity: .Low,
                reason: "When specifying a type, always associate the colon with the identifier")
        }
    }
}
