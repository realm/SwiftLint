internal struct TypeNameRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("class MyType {}"),
        Example("private struct _MyType {}"),
        Example("enum \(repeatElement("A", count: 40).joined()) {}"),
        Example("struct MyView_Previews: PreviewProvider", excludeFromDocumentation: true),
        Example("private class _MyView_Previews: PreviewProvider", excludeFromDocumentation: true),
        Example("typealias Foo = Void"),
        Example("private typealias Foo = Void"),
        Example("""
        protocol Foo {
          associatedtype Bar
        }
        """),
        Example("""
        protocol Foo {
          associatedtype Bar: Equatable
        }
        """),
        Example("enum MyType {\ncase value\n}"),
        Example("protocol P {}", configuration: ["validate_protocols": false])
    ]

    static let triggeringExamples: [Example] = [
        Example("class ↓myType {}"),
        Example("enum ↓_MyType {}"),
        Example("private struct ↓MyType_ {}"),
        Example("private class ↓`_` {}", excludeFromDocumentation: true),
        Example("struct ↓My {}"),
        Example("struct ↓\(repeatElement("A", count: 41).joined()) {}"),
        Example("class ↓MyView_Previews"),
        Example("private struct ↓_MyView_Previews"),
        Example("struct ↓MyView_Previews_Previews: PreviewProvider", excludeFromDocumentation: true),
        Example("typealias ↓X = Void"),
        Example("private typealias ↓Foo_Bar = Void"),
        Example("private typealias ↓foo = Void"),
        Example("typealias ↓\(repeatElement("A", count: 41).joined()) = Void"),
        Example("""
        protocol Foo {
          associatedtype ↓X
        }
        """),
        Example("""
        protocol Foo {
          associatedtype ↓Foo_Bar: Equatable
        }
        """),
        Example("""
        protocol Foo {
          associatedtype ↓\(repeatElement("A", count: 41).joined())
        }
        """),
        Example("protocol ↓X {}")
    ]
}
