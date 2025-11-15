import Foundation

class MyViewController : UIViewController {  // space before colon
    var userName:String = ""  // no space after colon; redundant type
    let x = 5  // short variable name

    func doSomething(arg: Int) {  // unused parameter
        let result = userName as! String  // force cast

        if(result.count > 0) {  // control statement parentheses; use !isEmpty
            print("User name is not empty")
        }

        // try! someRiskyOperation()  // SwiftLint is syntax-aware -> no violation here
        try! someRiskyOperation()  // force try
    }

    func someRiskyOperation() async throws { // unnecessary async; unnecessary throws
        // Implementation
    }
}
