//
//  Reporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public protocol Reporter: CustomStringConvertible {
    static var identifier: String { get }
    static func generateReport(_ violations: [StyleViolation]) -> String
    static var isRealtime: Bool { get }
}

public func reporterFrom(identifier: String) -> Reporter.Type {
    switch identifier {
    case XcodeReporter.identifier:
        return XcodeReporter.self
    case JSONReporter.identifier:
        return JSONReporter.self
    case CSVReporter.identifier:
        return CSVReporter.self
    case CheckstyleReporter.identifier:
        return CheckstyleReporter.self
    case JUnitReporter.identifier:
        return JUnitReporter.self
    case HTMLReporter.identifier:
        return HTMLReporter.self
    case EmojiReporter.identifier:
        return EmojiReporter.self
    default:
        fatalError("no reporter with identifier '\(identifier)' available.")
    }
}
