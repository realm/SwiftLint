//
//  ViolationSeverity.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public enum ViolationSeverity: String, Comparable {
    case Warning
    case Error
}

// MARK: Comparable

public func < (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
    return lhs == .Warning && rhs == .Error
}
