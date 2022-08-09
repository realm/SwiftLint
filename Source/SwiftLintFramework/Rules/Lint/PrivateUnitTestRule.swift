import Foundation
import SourceKittenFramework

private extension SourceKittenDictionary {
    var superclass: String? {
        guard declarationKind == .class,
            let className = inheritedTypes.first else { return nil }
        return className
    }

    var parameters: [SourceKittenDictionary] {
        return substructure.filter { dict in
            guard let kind = dict.declarationKind else {
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
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            "class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            internal class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            public class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            @objc private class FooTest: XCTestCase {
                @objc private func test1() {}
                    internal func test2() {}
                    public func test3() {}
            }
            """),
            // Non-test classes
            Example("""
            private class Foo: NSObject {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            private class Foo {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            // Methods with params
            Example("""
            public class FooTest: XCTestCase {
                func test1(param: Int) {}
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            private ↓class FooTest: XCTestCase {
                func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private func test4() {}
            }
            """),
            Example("""
            class FooTest: XCTestCase {
                func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private ↓func test4() {}
            }
            """),
            Example("""
            internal class FooTest: XCTestCase {
                func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private ↓func test4() {}
            }
            """),
            Example("""
            public class FooTest: XCTestCase {
                func test1() {}
                    internal func test2() {}
                    public func test3() {}
                    private ↓func test4() {}
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
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

    private func isTestClass(_ dictionary: SourceKittenDictionary) -> Bool {
        guard let regex = configuration.regex, let superclass = dictionary.superclass else {
            return false
        }
        let range = superclass.fullNSRange
        return regex.matches(in: superclass, options: [], range: range).isNotEmpty
    }

    private func validateFunction(file: SwiftLintFile,
                                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let kind = dictionary.declarationKind,
            kind == .functionMethodInstance,
            let name = dictionary.name, name.hasPrefix("test"),
            dictionary.parameters.isEmpty else {
                return []
        }
        return validateAccessControlLevel(file: file, dictionary: dictionary)
    }

    private func validateAccessControlLevel(file: SwiftLintFile,
                                            dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let acl = dictionary.accessibility, acl.isPrivate,
            !dictionary.enclosedSwiftAttributes.contains(.objc)
            else { return [] }
        let offset = dictionary.offset ?? 0
        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file, byteOffset: offset),
                               reason: configuration.message)]
    }
}
