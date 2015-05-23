//
//  ViolationSeverity.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public enum ViolationSeverity: Int, Printable, Comparable {
    case VeryLow
    case Low
    case Medium
    case High
    case VeryHigh

    public var description: String {
        switch self {
        case .VeryLow:
            return "Very Low"
        case .Low:
            return "Low"
        case .Medium:
            return "Medium"
        case .High:
            return "High"
        case .VeryHigh:
            return "Very High"
        }
    }

    public var isError: Bool {
        return self > Medium
    }

    public var xcodeSeverityDescription: String {
        return isError ? "error" : "warning"
    }
}

// MARK: Comparable

public func == (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
public func < (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
