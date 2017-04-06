//
//  YAMLLoader.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Yams

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
    public static func parse(_ yaml: String) throws -> [String: Any] {
        do {
            if let obj = try Yams.load(yaml: yaml) {
                if let dic = obj as? [String: Any] {
                    return dic
                }
            }
            return [:]
        } catch {
            throw YamlParserError.yamlParsing("\(error)")
        }
    }
}
