//
//  ClassVisibilityRule.swift
//  SwiftLint
//
//  Created by Cristian Filipov on 8/3/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private extension AccessControlLevel {
    init?(_ dictionary: [String: SourceKitRepresentable]) {
        guard let accessibility = dictionary.accessibility,
            let acl = AccessControlLevel(rawValue: accessibility) else { return nil }
        self = acl
    }
}

private extension Dictionary where Key: ExpressibleByStringLiteral {
    var superclass: String? {
        guard let kindString = self.kind,
            let kind = SwiftDeclarationKind(rawValue: kindString), kind == .class,
            let className = inheritedTypes.first else { return nil }
        return className
    }

    var parameters: [[String: SourceKitRepresentable]] {
        return substructure.filter { dict in
            guard let kind = dict.kind.flatMap(SwiftDeclarationKind.init) else {
                return false
            }

            return kind == .varParameter
        }
    }
}

public struct PrivateUnitTestRule: ASTRule, ConfigurationProviderRule, CacheDescriptionProvider {

    public var configuration: PrivateUnitTestConfiguration = {
        var configuration = PrivateUnitTestConfiguration(identifier: "private_unit_test")
        configuration.message = "Unit test marked `private` will not be run by XCTest."
        configuration.regex = regex("XCTestCase")
        return configuration
    }()

    internal var cacheDescription: String {
        return configuration.cacheDescription
    }

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_unit_test",
        name: "Private Unit Test",
        description: "Unit tests marked private are silently skipped.",
        nonTriggeringExamples: [
            "class FooTest: XCTestCase { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
            "}",
            "internal class FooTest: XCTestCase { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
            "}",
            "public class FooTest: XCTestCase { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
            "}",
            // Non-test classes
            "private class Foo: NSObject { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
            "}",
            "private class Foo { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
            "}",
            // Methods with params
            "public class FooTest: XCTestCase { " +
                "func test1(param: Int) {}\n " +
            "}"
        ],
        triggeringExamples: [
            "private ↓class FooTest: XCTestCase { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
                "private func test4() {}\n " +
            "}",
            "class FooTest: XCTestCase { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
                "private ↓func test4() {}\n " +
            "}",
            "internal class FooTest: XCTestCase { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
                "private ↓func test4() {}\n " +
            "}",
            "public class FooTest: XCTestCase { " +
                "func test1() {}\n " +
                "internal func test2() {}\n " +
                "public func test3() {}\n " +
                "private ↓func test4() {}\n " +
            "}"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .class && isTestClass(dictionary) else { return [] }

        /* It's not strictly necessary to check for `private` on classes because a
         private class will result in `private` on all its members in the AST.
         However, it's still useful to check the class explicitly because this
         gives us a more clear error message. If we check only methods, the line
         number of the error will be that of the function, which may not
         necessarily be marked `private` but inherited it from the class access
         modifier. By checking the class we ensure the line nuber we report for
         the violation will match the line that must be edited.
         */

        let classViolations = validateAccessControlLevel(file: file, dictionary: dictionary)
        guard classViolations.isEmpty else { return classViolations }

        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            return validateFunction(file: file, dictionary: subDict)
        }
    }

    private func isTestClass(_ dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard let regex = configuration.regex, let superclass = dictionary.superclass else {
            return false
        }
        let range = NSRange(location: 0, length: superclass.bridge().length)
        return !regex.matches(in: superclass, options: [], range: range).isEmpty
    }

    private func validateFunction(file: File,
                                  dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let kind = dictionary.kind.flatMap(SwiftDeclarationKind.init),
            kind == .functionMethodInstance,
            let name = dictionary.name, name.hasPrefix("test"),
            dictionary.parameters.isEmpty else {
                return []
        }
        return validateAccessControlLevel(file: file, dictionary: dictionary)
    }

    private func validateAccessControlLevel(file: File,
                                            dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let acl = AccessControlLevel(dictionary), acl.isPrivate else { return [] }
        let offset = dictionary.offset ?? 0
        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file, byteOffset: offset),
                               reason: configuration.message)]
    }
}
