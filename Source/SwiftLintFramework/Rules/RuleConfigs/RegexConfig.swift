//
//  RegexConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct RegexConfig: RuleConfig, Equatable {
    let identifier: String
    var message = "Regex matched."
    var regex = NSRegularExpression()
    var matchTokens = [SyntaxKind]()
    var severity = SeverityConfig(.Warning)

    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func setConfig(config: AnyObject) throws {
        //
    }
}

public func == (lhs: RegexConfig, rhs: RegexConfig) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.message == rhs.message &&
        lhs.regex == rhs.regex &&
        lhs.matchTokens == rhs.matchTokens &&
        lhs.severity == rhs.severity
}
