//
//  RuleParameter.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public struct RuleParameter<T: Equatable>: Equatable {
    public let severity: ViolationSeverity
    public let value: T

    public init(severity: ViolationSeverity, value: T) {
        self.severity = severity
        self.value = value
    }
}

// MARK: - Equatable

public func ==<T> (lhs: RuleParameter<T>, rhs: RuleParameter<T>) -> Bool {
    return lhs.value == rhs.value && lhs.severity == rhs.severity
}

public protocol ParameterDefinition {
    var key: String { get }
    var parameterDescription: String { get }
    var description: String { get }
    var defaultValueDescription: String { get }
}

public protocol ParameterProtocol: ParameterDefinition {
    mutating func parse(from configuration: [String: Any]) throws
}

public struct Parameter<T: YamlLoadable & Equatable>: ParameterProtocol, Equatable {
    public let key: String
    public let `default`: T
    public let description: String
    public var value: T {
        return _value ?? `default`
    }

    private var _value: T?

    public var parameterDescription: String {
        return "\(key): \(value)"
    }

    public var defaultValueDescription: String {
        return "\(`default`)"
    }

    public init(key: String, default: T, description: String) {
        self.key = key
        self.default = `default`
        self.description = description
    }

    public mutating func parse(from configuration: [String: Any]) throws {
        if configuration[key] != nil {
            _value = try T.load(from: configuration[key] as Any)
        }
    }

    public static func == <T>(lhs: Parameter<T>, rhs: Parameter<T>) -> Bool {
        return lhs.key == rhs.key && lhs.description == rhs.description && lhs.value == rhs.value
    }
}

public struct OptionalParameter<T: YamlLoadable & Equatable>: ParameterProtocol, Equatable {
    public let key: String
    public let `default`: T?
    public let description: String
    public var value: T? {
        return _value
    }

    private var _value: T?

    public var parameterDescription: String {
        let value: Any = self.value ?? "<null>"
        return "\(key): \(value)"
    }

    public var defaultValueDescription: String {
        let value: Any = `default` ?? "<null>"
        return "\(value)"
    }

    public init(key: String, default: T?, description: String) {
        self.key = key
        self.default = `default`
        self.description = description
        _value = `default`
    }

    public mutating func parse(from configuration: [String: Any]) throws {
        if configuration[key] != nil {
            _value = try T?.load(from: configuration[key] as Any)
        }
    }

    public static func == <T>(lhs: OptionalParameter<T>, rhs: OptionalParameter<T>) -> Bool {
        return lhs.key == rhs.key && lhs.description == rhs.description && lhs.value == rhs.value
    }
}

struct ArrayParameter<T: YamlLoadable & Equatable>: ParameterProtocol, Equatable {
    public let key: String
    public let `default`: [T]
    public let description: String
    public var value: [T] {
        return _value ?? `default`
    }

    private var _value: [T]?

    public var parameterDescription: String {
        return "\(key): \(value)"
    }

    public var defaultValueDescription: String {
        return "\(`default`)"
    }

    public init(key: String, default: [T], description: String) {
        self.key = key
        self.default = `default`
        self.description = description
    }

    public mutating func parse(from configuration: [String: Any]) throws {
        if configuration[key] != nil {
            _value = try [T].load(from: configuration[key] as Any)
        }
    }

    public static func == <T>(lhs: ArrayParameter<T>, rhs: ArrayParameter<T>) -> Bool {
        return lhs.key == rhs.key && lhs.description == rhs.description && lhs.value == rhs.value
    }
}
