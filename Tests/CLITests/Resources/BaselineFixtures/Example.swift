import Foundation
import SwiftLintFramework

class Example: NSObject {
    private var foo: Int
    private var bar: String

    init(foo: Int, bar: String) {
        self.foo = foo
        self.bar = bar
    }

    func someFunction() -> Int {
        foo * 10
    }

    func someOtherFunction() -> String {
        bar
    }
}
