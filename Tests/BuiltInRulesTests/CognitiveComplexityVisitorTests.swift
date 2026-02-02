@testable import SwiftLintBuiltInRules
import SwiftParser
import TestHelpers
import XCTest

// FIXME: delete this file once visitor behavior is agreed

final class CognitiveComplexityVisitorTests: XCTestCase {
    func testExamples() {
        let tree1 = Parser.parse(source: """
        class c1 {
            func f1(b1: Bool, b2: Bool, e1: SomeEnum) -> Int {
                if b1 { // +1
                    return 1
                }

                var sum = 0
                for i in 0..<10 { // +1
                    if i % 2,     // +2 (nesting = 1)
                        i > 3 {   // +1

                        switch e1 {  // +3 (nesting = 2)
                            case opt1:
                                print("abc")
                            case opt2:
                                print("def")
                            default:
                                continue
                        }

                        do {          // +3 (nesting = 2)
                            print("in do")
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        """)

        XCTAssertEqual(11, ComplexityVisitor(ignoresLogicalOperatorSequences: false)
            .walk(tree: tree1, handler: \.complexity))

        let tree2 = Parser.parse(source: """
            class c2 {
                func f1() -> Int {
                    while true {          // +1
                        if true {         // +1 + 1
                            if inner {    // +1 + 2
                                print("this is internal")
                            } else {      // +1
                                print("this is the other")
                            }
                            return 1
                        } else if false { // +1
                            return 0
                        } else {          // +1
                            return 2
                        }
                    }
                }
            }
            """)

        XCTAssertEqual(9, ComplexityVisitor(ignoresLogicalOperatorSequences: false)
            .walk(tree: tree2, handler: \.complexity))

        let tree3 = Parser.parse(source: """
            class c3 {
                func overriddenSymbol(from classType: ClassJavaType,
                                      name: String) -> MethodJavaSymbol {
                    if classType.isUnknown() {                           // +1
                        return Symbols.unknownMethodSymbol
                    }

                    var unknownFound = false

                    let symbols = classType.getSymbol().members().lookup(name)

                    for overrideSymbol in symbols {                      // +1
                        if overrideSymbol.kind == .method,               // +2 (nesting = 1)
                              !overrideSymbol.isStatic {                 // +1
                            if canOverride(methodSymbol) {               // +3 (nesting = 2)
                                let overriding = checkOverridingParameters(methodSymbol, classType)
                                if overriding == nil {                   // +4 (nesting = 3)
                                    if !unknownFound {                   // +5 (nesting = 4)
                                        unknownFound = true
                                    }
                                } else if overriding == true {           // +1
                                    return methodSymbol
                                }
                            }
                        }
                    }

                    if unknownFound {                                    // +1
                        return Symbols.unknownMethodSymbol
                    }

                    return nil
                }
            }
            // total complexity = 19
            """)

        XCTAssertEqual(19, ComplexityVisitor(ignoresLogicalOperatorSequences: false)
            .walk(tree: tree3, handler: \.complexity))

        let tree4 = Parser.parse(source: """
            class c1 {
                func addVersion(entry: inout Entry,
                                txn: Transaction) throws {
                    let ti = _persistit.getTransactionIndex()

                    while true {                                    // +1
                        do {
                            if first != nil {                       // +2 (nesting = 1)
                                if first.getVersion() > entry.getVersion() { // +3 (nesting = 2)
                                    throw RollbackError()
                                }
                                if txn.isActive() {                 // +3 (nesting = 2)
                                    for e in entries {              // +4 (nesting = 3)
                                        if depends == TIMED_OUT {   // +5 (nesting = 4)
                                            throw RetryException()
                                        }
                                        if depends != 0             // +5 (nesting = 4)
                                            && depends != ABORTED { // +1
                                            throw RollbackError()
                                        }
                                    }
                                }
                            }
                            entry.setPrevious(first)
                            first = entry
                            break
                        } catch let error as ErrorOne {             // +2 (nesting = 1)
                            do {
                                let depends = 123
                                if depends != 0                     // +3 (nesting = 2)
                                    && depends != ABORTED {         // +1
                                    throw RollbackError()
                                }
                            } catch {                               // +3 (nesting = 2)
                                throw SomeError()
                            }
                        } catch {                                   // +2 (nesting = 1)
                            throw SomeOtherError()
                        }
                    }
                }
            }
            // total complexity = 35
            """)

        XCTAssertEqual(35, ComplexityVisitor(ignoresLogicalOperatorSequences: false)
            .walk(tree: tree4, handler: \.complexity))

        let tree5 = Parser.parse(source: """
            class c1 {
                func f1() -> Int {
                    outerLoop: while true {      // +1
                        for i in 0..<100 {       // +2 (nesting = 1)
                            guard i >= 0,        // +3 (nesting = 2)
                                  i != -1 else { // +1
                                if i % 2 == 0 {  // +4 (nesting = 3)
                                    return 0
                                } else {         // +1
                                    return 1
                                }
                            }

                            if i > 50 {         // +3 (nesting = 2)
                                break outerLoop // +1
                            }
                        }
                    }
                }
            }
            """)

        XCTAssertEqual(16, ComplexityVisitor(ignoresLogicalOperatorSequences: false)
            .walk(tree: tree5, handler: \.complexity))

        let tree6 = Parser.parse(source: """
            struct ComplexityView: View {
                var body: some View {
                    VStack(alignment: .center) {                     // nesting +1
                        Text("Stuff")
                        ForEach(items) { item in                     // nesting +1
                            HStack {                                 // nesting +1
                                if let name = item.name {            // +4 (nesting = 3)
                                    Text(name)
                                } else {                             // +1
                                    Image(systemName: "exclamation")
                                }
                                Image(item.image)
                            }
                        }
                    }
                }
            }
            """)

        XCTAssertEqual(5, ComplexityVisitor(ignoresLogicalOperatorSequences: false)
            .walk(tree: tree6, handler: \.complexity))
    }
}
