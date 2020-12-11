// swiftlint:disable type_body_length

struct UnusedDeclarationRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        let kConstant = 0
        _ = kConstant
        """),
        Example("""
        enum Change<T> {
          case insert(T)
          case delete(T)
        }

        extension Sequence {
          func deletes<T>() -> [T] where Element == Change<T> {
            return compactMap { operation in
              if case .delete(let value) = operation {
                return value
              } else {
                return nil
              }
            }
          }
        }

        let changes = [Change.insert(0), .delete(0)]
        changes.deletes()
        """),
        Example("""
        struct Item {}
        struct ResponseModel: Codable {
            let items: [Item]

            enum CodingKeys: String, CodingKey {
                case items = "ResponseItems"
            }
        }

        _ = ResponseModel(items: [Item()]).items
        """),
        Example("""
        class ResponseModel {
            @objc func foo() {
            }
        }
        _ = ResponseModel()
        """),
        Example("""
        public func foo() {}
        """),
        Example("""
        protocol Foo {}

        extension Foo {
            func bar() {}
        }

        struct MyStruct: Foo {}
        MyStruct().bar()
        """),
        Example("""
        import XCTest
        class MyTests: XCTestCase {
            func testExample() {}
        }
        """),
        Example("""
        import XCTest
        open class BestTestCase: XCTestCase {}
        class MyTests: BestTestCase {
            func testExample() {}
        }
        """)
    ] + platformSpecificNonTriggeringExamples

    static let triggeringExamples = [
        Example("""
        let ↓kConstant = 0
        """),
        Example("""
        struct Item {}
        struct ↓ResponseModel: Codable {
            let ↓items: [Item]

            enum ↓CodingKeys: String {
                case items = "ResponseItems"
            }
        }
        """),
        Example("""
        class ↓ResponseModel {
            func ↓foo() {
            }
        }
        """),
        Example("""
        public func ↓foo() {}
        """, configuration: ["include_public_and_open": true]),
        Example("""
        protocol Foo {
            func ↓bar1()
        }

        extension Foo {
            func bar1() {}
            func ↓bar2() {}
        }

        struct MyStruct: Foo {}
        _ = MyStruct()
        """),
        Example("""
        import XCTest
        class ↓MyTests: NSObject {
            func ↓testExample() {}
        }
        """)
    ] + platformSpecificTriggeringExamples

#if os(macOS)
    private static let platformSpecificNonTriggeringExamples = [
        Example("""
        import Cocoa

        @NSApplicationMain
        final class AppDelegate: NSObject, NSApplicationDelegate {
            func applicationWillFinishLaunching(_ notification: Notification) {}
            func applicationWillBecomeActive(_ notification: Notification) {}
        }
        """),
        Example("""
        import Foundation

        public final class Foo: NSObject {
            @IBAction private func foo() {}
        }
        """),
        Example("""
        import Foundation

        public final class Foo: NSObject {
            @objc func foo() {}
        }
        """),
        Example("""
        import Foundation

        public final class Foo: NSObject {
            @IBInspectable private var innerPaddingWidth: Int {
                set { self.backgroundView.innerPaddingWidth = newValue }
                get { return self.backgroundView.innerPaddingWidth }
            }
        }
        """),
        Example("""
        import Foundation

        public final class Foo: NSObject {
            @IBOutlet private var bar: NSObject! {
                set { fatalError() }
                get { fatalError() }
            }

            @IBOutlet private var baz: NSObject! {
                willSet { print("willSet") }
            }

            @IBOutlet private var buzz: NSObject! {
                didSet { print("didSet") }
            }
        }
        """)
    ]

    private static let platformSpecificTriggeringExamples = [
        Example("""
        import Cocoa

        @NSApplicationMain
        final class AppDelegate: NSObject, NSApplicationDelegate {
            func ↓appWillFinishLaunching(_ notification: Notification) {}
            func applicationWillBecomeActive(_ notification: Notification) {}
        }
        """),
        Example("""
        import Cocoa

        final class ↓AppDelegate: NSObject, NSApplicationDelegate {
            func applicationWillFinishLaunching(_ notification: Notification) {}
            func applicationWillBecomeActive(_ notification: Notification) {}
        }
        """),
        Example("""
        import Foundation

        public final class Foo: NSObject {
            @IBOutlet var ↓bar: NSObject!
        }
        """),
        Example("""
        import Foundation

        public final class Foo: NSObject {
            @IBInspectable var ↓bar: String!
        }
        """)
    ]
#else
    private static let platformSpecificNonTriggeringExamples = [Example]()
    private static let platformSpecificTriggeringExamples = [Example]()
#endif
}
