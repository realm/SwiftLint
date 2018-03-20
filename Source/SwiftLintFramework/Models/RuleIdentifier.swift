//
//  RuleIdentifier.swift
//  SwiftLint
//
//  Created by Frederick Pietschmann on 3/5/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation

public enum RuleIdentifier: Hashable, ExpressibleByStringLiteral {
    case all
    case explicit(identifier: String)

    private static let allStringRepresentation = "all"

    public var hashValue: Int {
        return stringRepresentation.hashValue
    }

    public var stringRepresentation: String {
        switch self {
        case .all:
            return RuleIdentifier.allStringRepresentation

        case .explicit(let identifier):
            return identifier
        }
    }

    public init(_ value: String) {
        self = value == RuleIdentifier.allStringRepresentation ? .all : .explicit(identifier: value)
    }

    public init(stringLiteral value: String) {
        self = RuleIdentifier(value)
    }

    public static func == (lhs: RuleIdentifier, rhs: RuleIdentifier) -> Bool {
        return lhs.stringRepresentation == rhs.stringRepresentation
    }
}
