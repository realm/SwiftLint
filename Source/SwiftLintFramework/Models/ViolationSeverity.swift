//
//  ViolationSeverity.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public enum ViolationSeverity: String, Comparable {
    case warning
    case error
}

// MARK: Comparable

public func < (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
    return lhs == .warning && rhs == .error
}
