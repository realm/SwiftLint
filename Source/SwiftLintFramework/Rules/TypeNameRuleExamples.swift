//
//  TypeNameRuleExamples.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 30/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

internal struct TypeNameRuleExamples {

    private static let types = ["class", "struct", "enum"]

    static let nonTriggeringExamples: [String] = {
        let typeExamples: [String] = types.flatMap { (type: String) -> [String] in
            [
                "\(type) MyType {}",
                "private \(type) _MyType {}",
                "\(type) \(repeatElement("A", count: 40).joined()) {}"
            ]
        }
        let typeAliasAndAssociatedTypeExamples = [
            "typealias Foo = Void",
            "private typealias Foo = Void",
            "protocol Foo {\n associatedtype Bar\n }",
            "protocol Foo {\n associatedtype Bar: Equatable\n }"
        ]

        return typeExamples + typeAliasAndAssociatedTypeExamples + ["enum MyType {\ncase value\n}"]
    }()

    static let triggeringExamples: [String] = {
        let typeExamples: [String] = types.flatMap { (type: String) -> [String] in
            [
                "↓\(type) myType {}",
                "↓\(type) _MyType {}",
                "private ↓\(type) MyType_ {}",
                "↓\(type) My {}",
                "↓\(type) \(repeatElement("A", count: 41).joined()) {}"
            ]
        }
        let typeAliasAndAssociatedTypeExamples: [String] = [
            "typealias ↓X = Void",
            "private typealias ↓Foo_Bar = Void",
            "private typealias ↓foo = Void",
            "typealias ↓\(repeatElement("A", count: 41).joined()) = Void",
            "protocol Foo {\n associatedtype ↓X\n }",
            "protocol Foo {\n associatedtype ↓Foo_Bar: Equatable\n }",
            "protocol Foo {\n associatedtype ↓\(repeatElement("A", count: 41).joined())\n }"
        ]

        return typeExamples + typeAliasAndAssociatedTypeExamples
    }()
}
