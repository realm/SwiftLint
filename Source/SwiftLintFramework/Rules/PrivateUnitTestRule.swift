//
//  ClassVisibilityRule.swift
//  SwiftLint
//
//  Created by Cristian Filipov on 8/3/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension AccessControlLevel {
    init?(_ dictionary: [String: SourceKitRepresentable]) {
        guard let
            accessibility = dictionary["key.accessibility"] as? String,
            acl = AccessControlLevel(rawValue: accessibility)
            else { return nil }
        self = acl
    }
}

func superclass(dictionary: [String: SourceKitRepresentable]) -> String? {
    typealias SKArray = [SourceKitRepresentable]
    typealias SKDict = [String: SourceKitRepresentable]
    guard let
        kindString = dictionary["key.kind"] as? String,
        kind = SwiftDeclarationKind(rawValue: kindString)
        where kind == .Class
        else { return nil }
    guard let
        inheritedTypes = dictionary["key.inheritedtypes"] as? SKArray,
        className = (inheritedTypes[0] as? SKDict)?["key.name"] as? String
        else { return nil }
    return className
}

public class FooTest: NSObject {  }

public struct PrivateUnitTestRule: ASTRule, ConfigurationProviderRule {

    public var configuration: PrivateUnitTestConfiguration = {
        var configuration = PrivateUnitTestConfiguration(identifier: "private_unit_test")
        configuration.message = "Unit test marked `private` will be silently skipped."
        configuration.regex = regex("XCTestCase")
        return configuration
    }()

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_unit_test",
        name: "Private Unit Test",
        description: "Unit tests marked private are silently skipped.",
        nonTriggeringExamples: [
            "class FooTest: XCTestCase { " +
                "func test1() {}; " +
                "internal func test2() {}; " +
                "public func test3() {}; " +
            "}",
            "internal class FooTest: XCTestCase { " +
                "func test1() {}; " +
                "internal func test2() {}; " +
                "public func test3() {}; " +
            "}",
            "public class FooTest: XCTestCase { " +
                "func test1() {}; " +
                "internal func test2() {}; " +
                "public func test3() {}; " +
            "}"
        ],
        triggeringExamples: [
            "private ↓class FooTest: XCTestCase { " +
                "func test1() {}; " +
                "internal func test2() {}; " +
                "public func test3() {}; " +
                "private func test4() {}; " +
            "}",
            "class FooTest: XCTestCase { " +
                "func test1() {}; " +
                "internal func test2() {}; " +
                "public func test3() {}; " +
                "private ↓func test4() {}; " +
            "}",
            "internal class FooTest: XCTestCase { " +
                "func test1() {}; " +
                "internal func test2() {}; " +
                "public func test3() {}; " +
                "private ↓func test4() {}; " +
            "}",
            "public class FooTest: XCTestCase { " +
                "func test1() {}; " +
                "internal func test2() {}; " +
                "public func test3() {}; " +
                "private ↓func test4() {}; " +
            "}",
        ]
    )

    public func validateFile(
        file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable])
        -> [StyleViolation] {

            guard kind == .Class else { return [] }
            let classViolations = validateClass(file, kind: kind, dictionary: dictionary)
            guard classViolations.isEmpty else { return classViolations }

            let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
            return substructure.flatMap { subItem -> [StyleViolation] in
                guard
                    let subDict = subItem as? [String: SourceKitRepresentable],
                    kindString = subDict["key.kind"] as? String,
                    kind = KindType(rawValue: kindString)
                    where kind == .FunctionMethodInstance
                    else { return [] }
                return self.validateFunction(file, kind: kind, dictionary: subDict)
            }

    }

    /* It's not strictly necessary to check for `private` on classes because a
     private class will result in `private` on all its members in the AST.
     However, it's still useful to check the class explicitly because this
     gives us a more clear error message. If we check only methods, the line
     number of the error will be that of the function, which may not
     necessarily be marked `private` but inhereted it from the class access
     modifier. By checking the class we ensure the line nuber we report for
     the violation will match the line that must be edited.
     */
    private func validateClass(
        file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable])
        -> [StyleViolation] {

            assert(kind == .Class)
            guard let superclass = superclass(dictionary) else { return [] }
            let pathMatch = configuration.regex.matchesInString(
                superclass,
                options: [],
                range: NSRange(location: 0, length: (superclass as NSString).length))
            guard !pathMatch.isEmpty else { return [] }
            return validateAccessControlLevel(file, dictionary: dictionary)

    }

    private func validateFunction(
        file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable])
        -> [StyleViolation] {

            assert(kind == .FunctionMethodInstance)
            guard
                let name = dictionary["key.name"] as? NSString
                where name.hasPrefix("test")
                else { return [] }
            return validateAccessControlLevel(file, dictionary: dictionary)

    }

    private func validateAccessControlLevel(
        file: File,
        dictionary: [String: SourceKitRepresentable])
        -> [StyleViolation] {

            guard let acl = AccessControlLevel(dictionary) else { return [] }
            switch acl {
            case .Private:
                let offset = Int(dictionary["key.offset"] as? Int64 ?? 0)
                return [StyleViolation(
                    ruleDescription: self.dynamicType.description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: configuration.message)]
            default: return []
            }

    }

}
