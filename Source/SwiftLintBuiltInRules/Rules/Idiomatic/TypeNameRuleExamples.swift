import SwiftLintCore

internal struct TypeNameRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
        "class MyType {}",
        "private struct _MyType {}",
        "private class `_` {}".configuration(["excluded": ["`_`"]]).excludeFromDocumentation(),
        "struct `My Struct` {}".configuration(["excluded": ["`.+`"]]),
        "enum \(repeatElement("A", count: 40).joined()) {}",
        "struct MyView_Previews: PreviewProvider".excludeFromDocumentation(),
        "private class _MyView_Previews: PreviewProvider".excludeFromDocumentation(),
        "typealias Foo = Void",
        "private typealias Foo = Void",
        """
        protocol Foo {
          associatedtype Bar
        }
        """,
        """
        protocol Foo {
          associatedtype Bar: Equatable
        }
        """,
        "enum MyType {\ncase value\n}",
        "protocol P {}".configuration(["validate_protocols": false]),
        """
        struct SomeStruct {
          enum `Type` {
            case x, y, z
          }
        }
        """,
    ])

    static let triggeringExamples: [Example] = #examples([
        "class ↓myType {}",
        "enum ↓_MyType {}",
        "class ↓`My Class` {}",
        "private struct ↓MyType_ {}",
        "private class ↓`_` {}".excludeFromDocumentation(),
        "struct ↓My {}",
        "struct ↓\(repeatElement("A", count: 41).joined()) {}",
        "class ↓MyView_Previews",
        "private struct ↓_MyView_Previews",
        "struct ↓MyView_Previews_Previews: PreviewProvider".excludeFromDocumentation(),
        "typealias ↓X = Void",
        "private typealias ↓Foo_Bar = Void",
        "private typealias ↓foo = Void",
        "typealias ↓\(repeatElement("A", count: 41).joined()) = Void",
        """
        protocol Foo {
          associatedtype ↓X
        }
        """,
        """
        protocol Foo {
          associatedtype ↓Foo_Bar: Equatable
        }
        """,
        """
        protocol Foo {
          associatedtype ↓\(repeatElement("A", count: 41).joined())
        }
        """,
        "protocol ↓X {}",
    ])
}
