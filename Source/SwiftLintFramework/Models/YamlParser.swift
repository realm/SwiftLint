//
//  YAMLLoader.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Yaml

// MARK: - YamlParsingError

internal enum YamlParserError: Error, Equatable {
    case yamlParsing(String)
    case yamlFlattening
}

internal func == (lhs: YamlParserError, rhs: YamlParserError) -> Bool {
    switch (lhs, rhs) {
    case (.yamlFlattening, .yamlFlattening):
        return true
    case (.yamlParsing(let x), .yamlParsing(let y)):
        return x == y
    default:
        return false
    }
}

// MARK: - YamlParser

public struct YamlParser {
    public static func parse(_ contents: String) throws -> [String: Any] {
        do {
            if let dict = try loadYaml(contents).flatDictionary {
                return dict
            } else {
                throw YamlParserError.yamlFlattening
            }
        }
    }

    fileprivate static func loadYaml(_ yaml: String) throws -> Yaml {
        do {
            return try Yaml.load(yaml)
        } catch Yaml.ResultError.message(let message) {
            throw YamlParserError.yamlParsing(message ?? "Unknown Yaml Error")
        }
    }
}
