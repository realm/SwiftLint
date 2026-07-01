import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ColonRuleTests {
    @Test
    func colonWithFlexibleRightSpace() {
        // Verify Colon rule with test values for when flexible_right_spacing
        // is true.
        let nonTriggeringExamples = ColonRule.description.nonTriggeringExamples + #examples([
            "let abc:  Void\n",
            "let abc:  (Void, String, Int)\n",
            "let abc:  ([Void], String, Int)\n",
            "let abc:  [([Void], String, Int)]\n",
            "func abc(def:  Void) {}\n",
            "let abc = [Void:  Void]()\n",
        ])
        let triggeringExamples = #examples([
            "let abc↓:Void\n",
            "let abc↓ :Void\n",
            "let abc↓ : Void\n",
            "let abc↓ : [Void: Void]\n",
            "let abc↓ : (Void, String, Int)\n",
            "let abc↓ : ([Void], String, Int)\n",
            "let abc↓ : [([Void], String, Int)]\n",
            "let abc↓ :String=\"def\"\n",
            "let abc↓ :Int=0\n",
            "let abc↓ :Int = 0\n",
            "let abc↓:Int=0\n",
            "let abc↓:Int = 0\n",
            "let abc↓:Enum=Enum.Value\n",
            "func abc(def↓:Void) {}\n",
            "func abc(def↓ :Void) {}\n",
            "func abc(def↓ : Void) {}\n",
            "func abc(def: Void, ghi↓ :Void) {}\n",
            "let abc = [Void↓:Void]()\n",
            "let abc = [Void↓ : Void]()\n",
            "let abc = [Void↓ :  Void]()\n",
            "let abc = [1: [3↓ : 2], 3: 4]\n",
            "let abc = [1: [3↓ : 2], 3:  4]\n",
        ])
        let corrections = #corrections([
            "let abc↓:Void\n": "let abc: Void\n",
            "let abc↓ :Void\n": "let abc: Void\n",
            "let abc↓ : Void\n": "let abc: Void\n",
            "let abc↓ : [Void: Void]\n": "let abc: [Void: Void]\n",
            "let abc↓ : (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let abc↓ : ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let abc↓ : [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let abc↓ :String=\"def\"\n": "let abc: String=\"def\"\n",
            "let abc↓ :Int=0\n": "let abc: Int=0\n",
            "let abc↓ :Int = 0\n": "let abc: Int = 0\n",
            "let abc↓:Int=0\n": "let abc: Int=0\n",
            "let abc↓:Int = 0\n": "let abc: Int = 0\n",
            "let abc↓:Enum=Enum.Value\n": "let abc: Enum=Enum.Value\n",
            "func abc(def↓:Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def↓ :Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def↓ : Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def: Void, ghi↓ :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n",
            "let abc = [Void↓:Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓ : Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓ :  Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [1: [3↓ : 2], 3: 4]\n": "let abc = [1: [3: 2], 3: 4]\n",
            "let abc = [1: [3↓ : 2], 3:  4]\n": "let abc = [1: [3: 2], 3:  4]\n",
        ])
        let description = ColonRule.description.with(triggeringExamples: triggeringExamples)
                                               .with(nonTriggeringExamples: nonTriggeringExamples)
                                               .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["flexible_right_spacing": true])
    }

    @Test
    func colonWithoutApplyToDictionaries() {
        let nonTriggeringExamples = ColonRule.description.nonTriggeringExamples + #examples([
            "let abc = [Void:Void]()\n",
            "let abc = [Void : Void]()\n",
            "let abc = [Void:  Void]()\n",
            "let abc = [Void :  Void]()\n",
            "let abc = [1: [3 : 2], 3: 4]\n",
            "let abc = [1: [3 : 2], 3:  4]\n",
        ])
        let triggeringExamples = #examples([
            "let abc↓:Void\n",
            "let abc↓:  Void\n",
            "let abc↓ :Void\n",
            "let abc↓ : Void\n",
            "let abc↓ : [Void: Void]\n",
            "let abc↓ : (Void, String, Int)\n",
            "let abc↓ : ([Void], String, Int)\n",
            "let abc↓ : [([Void], String, Int)]\n",
            "let abc↓:  (Void, String, Int)\n",
            "let abc↓:  ([Void], String, Int)\n",
            "let abc↓:  [([Void], String, Int)]\n",
            "let abc↓ :String=\"def\"\n",
            "let abc↓ :Int=0\n",
            "let abc↓ :Int = 0\n",
            "let abc↓:Int=0\n",
            "let abc↓:Int = 0\n",
            "let abc↓:Enum=Enum.Value\n",
            "func abc(def↓:Void) {}\n",
            "func abc(def↓:  Void) {}\n",
            "func abc(def↓ :Void) {}\n",
            "func abc(def↓ : Void) {}\n",
            "func abc(def: Void, ghi↓ :Void) {}\n",
        ])
        let corrections = #corrections([
            "let abc↓:Void\n": "let abc: Void\n",
            "let abc↓:  Void\n": "let abc: Void\n",
            "let abc↓ :Void\n": "let abc: Void\n",
            "let abc↓ : Void\n": "let abc: Void\n",
            "let abc↓ : [Void: Void]\n": "let abc: [Void: Void]\n",
            "let abc↓ : (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let abc↓ : ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let abc↓ : [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let abc↓:  (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let abc↓:  ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let abc↓:  [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let abc↓ :String=\"def\"\n": "let abc: String=\"def\"\n",
            "let abc↓ :Int=0\n": "let abc: Int=0\n",
            "let abc↓ :Int = 0\n": "let abc: Int = 0\n",
            "let abc↓:Int=0\n": "let abc: Int=0\n",
            "let abc↓:Int = 0\n": "let abc: Int = 0\n",
            "let abc↓:Enum=Enum.Value\n": "let abc: Enum=Enum.Value\n",
            "func abc(def↓:Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def↓:  Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def↓ :Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def↓ : Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def: Void, ghi↓ :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n",
        ])

        let description = ColonRule.description.with(triggeringExamples: triggeringExamples)
                                               .with(nonTriggeringExamples: nonTriggeringExamples)
                                               .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["apply_to_dictionaries": false])
    }
}
