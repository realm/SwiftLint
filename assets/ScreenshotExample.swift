import Foundation

class MyViewController : UIViewController { // space before colon
    var userName:String? = "" // no space after colon; redundant type
    let x = 5 // short variable name

    func doSomething(arg: Int) { // unused parameter
        let result = userName as! String // force cast

        if(result.count > 0 && x > 1) { // control statement parentheses; use !isEmpty; prefer condition list
            print("User name is not empty")
            return
        } else { // unnecessary else
            print("User name is empty")
        }

        // try! someOperation() // SwiftLint is syntax-aware -> no violation here
        try! MyViewController.someOperation() // force try; prefer Self
    }

    final class func someOperation() async throws { // final class -> static; unnecessary async; unnecessary throws
        if let userName = userName {} // shorthand optional binding; empty block
    }
}

