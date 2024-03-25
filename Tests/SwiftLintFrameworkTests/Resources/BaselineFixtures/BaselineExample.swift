import Foundation
import SwiftLintFramework

class Example: NSObject {
    private var foo: Int
    private var bar: String

    init(foo: Int, bar: String) {
        self.foo = foo
        self.bar = bar
    } // init
    func someFunction() -> Int {
        foo * 10
    } // someFunction
    func someOtherFunction() -> String {
        bar
    } // someOtherFunction
    func yetAnotherFunction() -> (Int, String) {
        (foo, bar)
    } // yetAnotherFunction
}
