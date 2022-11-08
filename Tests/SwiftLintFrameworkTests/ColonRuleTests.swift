@testable import SwiftLintFramework

class ColonRuleTests: SwiftLintTestCase {
    // swiftlint:disable:next function_body_length
    func testColonWithFlexibleRightSpace() {
        // Verify Colon rule with test values for when flexible_right_spacing
        // is true.
        let nonTriggeringExamples = ColonRule.description.nonTriggeringExamples + [
            Example("let abc:  Void\n"),
            Example("let abc:  (Void, String, Int)\n"),
            Example("let abc:  ([Void], String, Int)\n"),
            Example("let abc:  [([Void], String, Int)]\n"),
            Example("func abc(def:  Void) {}\n"),
            Example("let abc = [Void:  Void]()\n")
        ]
        let triggeringExamples: [Example] = [
            Example("let abc↓:Void\n"),
            Example("let abc↓ :Void\n"),
            Example("let abc↓ : Void\n"),
            Example("let abc↓ : [Void: Void]\n"),
            Example("let abc↓ : (Void, String, Int)\n"),
            Example("let abc↓ : ([Void], String, Int)\n"),
            Example("let abc↓ : [([Void], String, Int)]\n"),
            Example("let abc↓ :String=\"def\"\n"),
            Example("let abc↓ :Int=0\n"),
            Example("let abc↓ :Int = 0\n"),
            Example("let abc↓:Int=0\n"),
            Example("let abc↓:Int = 0\n"),
            Example("let abc↓:Enum=Enum.Value\n"),
            Example("func abc(def↓:Void) {}\n"),
            Example("func abc(def↓ :Void) {}\n"),
            Example("func abc(def↓ : Void) {}\n"),
            Example("func abc(def: Void, ghi↓ :Void) {}\n"),
            Example("let abc = [Void↓:Void]()\n"),
            Example("let abc = [Void↓ : Void]()\n"),
            Example("let abc = [Void↓ :  Void]()\n"),
            Example("let abc = [1: [3↓ : 2], 3: 4]\n"),
            Example("let abc = [1: [3↓ : 2], 3:  4]\n")
        ]
        let corrections: [Example: Example] = [
            Example("let abc↓:Void\n"): Example("let abc: Void\n"),
            Example("let abc↓ :Void\n"): Example("let abc: Void\n"),
            Example("let abc↓ : Void\n"): Example("let abc: Void\n"),
            Example("let abc↓ : [Void: Void]\n"): Example("let abc: [Void: Void]\n"),
            Example("let abc↓ : (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
            Example("let abc↓ : ([Void], String, Int)\n"): Example("let abc: ([Void], String, Int)\n"),
            Example("let abc↓ : [([Void], String, Int)]\n"): Example("let abc: [([Void], String, Int)]\n"),
            Example("let abc↓ :String=\"def\"\n"): Example("let abc: String=\"def\"\n"),
            Example("let abc↓ :Int=0\n"): Example("let abc: Int=0\n"),
            Example("let abc↓ :Int = 0\n"): Example("let abc: Int = 0\n"),
            Example("let abc↓:Int=0\n"): Example("let abc: Int=0\n"),
            Example("let abc↓:Int = 0\n"): Example("let abc: Int = 0\n"),
            Example("let abc↓:Enum=Enum.Value\n"): Example("let abc: Enum=Enum.Value\n"),
            Example("func abc(def↓:Void) {}\n"): Example("func abc(def: Void) {}\n"),
            Example("func abc(def↓ :Void) {}\n"): Example("func abc(def: Void) {}\n"),
            Example("func abc(def↓ : Void) {}\n"): Example("func abc(def: Void) {}\n"),
            Example("func abc(def: Void, ghi↓ :Void) {}\n"): Example("func abc(def: Void, ghi: Void) {}\n"),
            Example("let abc = [Void↓:Void]()\n"): Example("let abc = [Void: Void]()\n"),
            Example("let abc = [Void↓ : Void]()\n"): Example("let abc = [Void: Void]()\n"),
            Example("let abc = [Void↓ :  Void]()\n"): Example("let abc = [Void: Void]()\n"),
            Example("let abc = [1: [3↓ : 2], 3: 4]\n"): Example("let abc = [1: [3: 2], 3: 4]\n"),
            Example("let abc = [1: [3↓ : 2], 3:  4]\n"): Example("let abc = [1: [3: 2], 3:  4]\n")
        ]
        let description = ColonRule.description.with(triggeringExamples: triggeringExamples)
                                               .with(nonTriggeringExamples: nonTriggeringExamples)
                                               .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["flexible_right_spacing": true])
    }

    // swiftlint:disable:next function_body_length
    func testColonWithoutApplyToDictionaries() {
        let nonTriggeringExamples = ColonRule.description.nonTriggeringExamples + [
            Example("let abc = [Void:Void]()\n"),
            Example("let abc = [Void : Void]()\n"),
            Example("let abc = [Void:  Void]()\n"),
            Example("let abc = [Void :  Void]()\n"),
            Example("let abc = [1: [3 : 2], 3: 4]\n"),
            Example("let abc = [1: [3 : 2], 3:  4]\n")
        ]
        let triggeringExamples: [Example] = [
            Example("let abc↓:Void\n"),
            Example("let abc↓:  Void\n"),
            Example("let abc↓ :Void\n"),
            Example("let abc↓ : Void\n"),
            Example("let abc↓ : [Void: Void]\n"),
            Example("let abc↓ : (Void, String, Int)\n"),
            Example("let abc↓ : ([Void], String, Int)\n"),
            Example("let abc↓ : [([Void], String, Int)]\n"),
            Example("let abc↓:  (Void, String, Int)\n"),
            Example("let abc↓:  ([Void], String, Int)\n"),
            Example("let abc↓:  [([Void], String, Int)]\n"),
            Example("let abc↓ :String=\"def\"\n"),
            Example("let abc↓ :Int=0\n"),
            Example("let abc↓ :Int = 0\n"),
            Example("let abc↓:Int=0\n"),
            Example("let abc↓:Int = 0\n"),
            Example("let abc↓:Enum=Enum.Value\n"),
            Example("func abc(def↓:Void) {}\n"),
            Example("func abc(def↓:  Void) {}\n"),
            Example("func abc(def↓ :Void) {}\n"),
            Example("func abc(def↓ : Void) {}\n"),
            Example("func abc(def: Void, ghi↓ :Void) {}\n")
        ]
        let corrections: [Example: Example] = [
            Example("let abc↓:Void\n"): Example("let abc: Void\n"),
            Example("let abc↓:  Void\n"): Example("let abc: Void\n"),
            Example("let abc↓ :Void\n"): Example("let abc: Void\n"),
            Example("let abc↓ : Void\n"): Example("let abc: Void\n"),
            Example("let abc↓ : [Void: Void]\n"): Example("let abc: [Void: Void]\n"),
            Example("let abc↓ : (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
            Example("let abc↓ : ([Void], String, Int)\n"): Example("let abc: ([Void], String, Int)\n"),
            Example("let abc↓ : [([Void], String, Int)]\n"): Example("let abc: [([Void], String, Int)]\n"),
            Example("let abc↓:  (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
            Example("let abc↓:  ([Void], String, Int)\n"): Example("let abc: ([Void], String, Int)\n"),
            Example("let abc↓:  [([Void], String, Int)]\n"): Example("let abc: [([Void], String, Int)]\n"),
            Example("let abc↓ :String=\"def\"\n"): Example("let abc: String=\"def\"\n"),
            Example("let abc↓ :Int=0\n"): Example("let abc: Int=0\n"),
            Example("let abc↓ :Int = 0\n"): Example("let abc: Int = 0\n"),
            Example("let abc↓:Int=0\n"): Example("let abc: Int=0\n"),
            Example("let abc↓:Int = 0\n"): Example("let abc: Int = 0\n"),
            Example("let abc↓:Enum=Enum.Value\n"): Example("let abc: Enum=Enum.Value\n"),
            Example("func abc(def↓:Void) {}\n"): Example("func abc(def: Void) {}\n"),
            Example("func abc(def↓:  Void) {}\n"): Example("func abc(def: Void) {}\n"),
            Example("func abc(def↓ :Void) {}\n"): Example("func abc(def: Void) {}\n"),
            Example("func abc(def↓ : Void) {}\n"): Example("func abc(def: Void) {}\n"),
            Example("func abc(def: Void, ghi↓ :Void) {}\n"): Example("func abc(def: Void, ghi: Void) {}\n")
        ]

        let description = ColonRule.description.with(triggeringExamples: triggeringExamples)
                                               .with(nonTriggeringExamples: nonTriggeringExamples)
                                               .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["apply_to_dictionaries": false])
    }
}
