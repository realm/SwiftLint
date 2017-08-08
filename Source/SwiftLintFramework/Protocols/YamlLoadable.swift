//
//  YamlLoadable.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/08/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public protocol YamlLoadable {
    static func load(from node: Any) throws -> Self
}

extension Bool: YamlLoadable {
    public static func load(from node: Any) throws -> Bool {
        if let value = node as? Bool {
            return value
        }

        throw ConfigurationError.unknownConfiguration
    }
}

extension String: YamlLoadable {
    public static func load(from node: Any) throws -> String {
        if let value = node as? String {
            return value
        }

        throw ConfigurationError.unknownConfiguration
    }
}

extension Int: YamlLoadable {
    public static func load(from node: Any) throws -> Int {
        if let value = node as? Int {
            return value
        }

        throw ConfigurationError.unknownConfiguration
    }
}

public extension Optional where Wrapped: YamlLoadable {
    static func load(from node: Any) throws -> Optional<Wrapped> {
        if let value = node as? Wrapped {
            return value
        }

        // TODO: Should throw if a different type is found

        return .none
    }
}

extension ViolationSeverity: YamlLoadable {}

public extension YamlLoadable where Self: RawRepresentable {
    static func load(from node: Any) throws -> Self {
        guard let rawValue = node as? RawValue,
            let value = Self(rawValue: rawValue) else {
                throw ConfigurationError.unknownConfiguration
        }

        return value
    }
}

extension Array where Element: YamlLoadable {
    static func load(from node: Any) throws -> [Element] {
        if let value = node as? [YamlLoadable] {
            return try value.flatMap(Element.load(from:))
        }

        throw ConfigurationError.unknownConfiguration
    }
}
