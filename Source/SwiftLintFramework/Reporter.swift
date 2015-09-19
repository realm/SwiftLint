//
//  Reporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public protocol Reporter: CustomStringConvertible {
    static var identifier: String { get }
    static func generateReport(violations: [StyleViolation]) -> String
}
