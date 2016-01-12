//
//  YAMLLoader.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Yaml

// MARK: - YamlParsingError

public enum YamlParserError: ErrorType, Equatable {
    case YamlParsing(String)
    case YamlFlattening
}

public func == (lhs: YamlParserError, rhs: YamlParserError) -> Bool {
    switch (lhs, rhs) {
    case (.YamlFlattening, .YamlFlattening):
        return true
    case (.YamlParsing(let x), .YamlParsing(let y)):
        return x == y
    default:
        return false
    }
}

// MARK: - YamlParser

public struct YamlParser {
    public static func parse(contents: String) throws -> [String: AnyObject] {
        do {
            if let dict = try loadYaml(contents).flatDictionary {
                return dict
            } else {
                throw YamlParserError.YamlFlattening
            }
        }
    }

    private static func loadYaml(yaml: String) throws -> Yaml {
        let yamlResult = Yaml.load(yaml)
        if let yamlConfig = yamlResult.value {
            return yamlConfig
        } else {
            throw YamlParserError.YamlParsing(yamlResult.error!)
        }
    }
}
