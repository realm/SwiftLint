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
        protocol Foo {
            func ↓bar1()
        }

        extension Foo {
            func bar1() {}
            func ↓bar2() {}
        }

        struct MyStruct: Foo {}
        _ = MyStruct()
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
        """)
    ]
#else
    private static let platformSpecificNonTriggeringExamples = [Example]()
    private static let platformSpecificTriggeringExamples = [Example]()
#endif
}
