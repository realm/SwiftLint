import Foundation
import SourceKittenFramework

private let whitespaceAndNewlineCharacterSet = CharacterSet.whitespacesAndNewlines

private extension SwiftLintFile {
    func violatingOpeningBraceRanges() -> [(range: NSRange, location: Int)] {
        return match(pattern: "(?:[^( ]|[\\s(][\\s]+)\\{",
                     excludingSyntaxKinds: SyntaxKind.commentAndStringKinds,
                     excludingPattern: "(?:if|guard|while)\\n[^\\{]+?[\\s\\t\\n]\\{").compactMap {
            if isAnonimousClosure(range: $0) {
                return nil
            }
            let branceRange = contents.bridge().range(of: "{", options: .literal, range: $0)
            return ($0, branceRange.location)
        }
    }

    func isAnonimousClosure(range: NSRange) -> Bool {
        let contentsBridge = contents.bridge()
        guard range.location != NSNotFound else {
            return false
        }
        let closureCode = contentsBridge.substring(from: range.location)
        guard let closingBracketPosition = closingBracket(closureCode) else {
            return false
        }
        let lengthAfterClosingBracket = closureCode.count - closingBracketPosition - 1
        if lengthAfterClosingBracket <= 0 {
            return false
        }

        //First non-whitespace character should be "(" - otherwise it is not an anonymous closure
        let afterBracketCode = closureCode.substring(from: closingBracketPosition + 1)
                                            .trimmingCharacters(in: .whitespaces)
        return afterBracketCode.first == "("
    }

    func closingBracket(_ closureCode: String) -> Int? {
        var bracketCount = 0
        var location = 0
        for letter in closureCode {
            if letter == "{" {
                bracketCount += 1
            } else if letter == "}" {
                if bracketCount == 1 {
                    // The closing bracket found
                    return location
                }
                bracketCount -= 1
            }
            location += 1
        }
        return nil
    }
}

public struct OpeningBraceRule: CorrectableRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "opening_brace",
        name: "Opening Brace Spacing",
        description: "Opening braces should be preceded by a single space and on the same line " +
                     "as the declaration.",
        kind: .style,
        nonTriggeringExamples: [
            "func abc() {\n}",
            "[].map() { $0 }",
            "[].map({ })",
            "if let a = b { }",
            "while a == b { }",
            "guard let a = b else { }",
            "if\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }",
            "while\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }",
            "guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else\n{ }",
            "struct Rule {}\n",
            "struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n",
            """
            func f(rect: CGRect) {
               {
                  let centre = CGPoint(x: rect.midX, y: rect.midY)
                  print(centre)
               }()
            }
            """
        ],
        triggeringExamples: [
            "func abc()↓{\n}",
            "func abc()\n\t↓{ }",
            "[].map()↓{ $0 }",
            "[].map( ↓{ } )",
            "if let a = b↓{ }",
            "while a == b↓{ }",
            "guard let a = b else↓{ }",
            "if\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }",
            "while\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }",
            "guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else↓{ }",
            "struct Rule↓{}\n",
            "struct Rule\n↓{\n}\n",
            "struct Rule\n\n\t↓{\n}\n",
            "struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}\n",
            """
            // Get the current thread's TLS pointer. On first call for a given thread,
            // creates and initializes a new one.
            internal static func getPointer()
              -> UnsafeMutablePointer<_ThreadLocalStorage>
            { // <- here
              return _swift_stdlib_threadLocalStorageGet().assumingMemoryBound(
                to: _ThreadLocalStorage.self)
            }
            """,
            """
            func run_Array_method1x(_ N: Int) {
              let existentialArray = array!
              for _ in 0 ..< N * 100 {
                for elt in existentialArray {
                  if !elt.doIt()  {
                    fatalError("expected true")
                  }
                }
              }
            }

            func run_Array_method2x(_ N: Int) {

            }
            """
        ],
        corrections: [
            "struct Rule↓{}\n": "struct Rule {}\n",
            "struct Rule\n↓{\n}\n": "struct Rule {\n}\n",
            "struct Rule\n\n\t↓{\n}\n": "struct Rule {\n}\n",
            "struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}\n":
                "struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n",
            "[].map()↓{ $0 }\n": "[].map() { $0 }\n",
            "[].map( ↓{ })\n": "[].map({ })\n",
            "if a == b↓{ }\n": "if a == b { }\n",
            "if\n\tlet a = b,\n\tlet c = d↓{ }\n": "if\n\tlet a = b,\n\tlet c = d { }\n"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.violatingOpeningBraceRanges().map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = file.violatingOpeningBraceRanges().filter {
            !file.ruleEnabled(violatingRanges: [$0.range], for: self).isEmpty
        }
        var correctedContents = file.contents
        var adjustedLocations = [Location]()

        for (violatingRange, location) in violatingRanges.reversed() {
            correctedContents = correct(contents: correctedContents, violatingRange: violatingRange)
            adjustedLocations.insert(Location(file: file, characterOffset: location), at: 0)
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: $0)
        }
    }

    private func correct(contents: String,
                         violatingRange: NSRange) -> String {
        guard let indexRange = contents.nsrangeToIndexRange(violatingRange) else {
            return contents
        }

        let capturedString = String(contents[indexRange])
        var adjustedRange = violatingRange
        var correctString = " {"

        // "struct Command{" has violating string = "d{", so ignore first "d"
        if capturedString.count == 2 &&
            capturedString.rangeOfCharacter(from: whitespaceAndNewlineCharacterSet) == nil {
            adjustedRange = NSRange(
                location: violatingRange.location + 1,
                length: violatingRange.length - 1
            )
        }

        // "[].map( { } )" has violating string = "( {",
        // so ignore first "(" and use "{" as correction string instead
        if capturedString.hasPrefix("(") {
            adjustedRange = NSRange(
                location: violatingRange.location + 1,
                length: violatingRange.length - 1
            )
            correctString = "{"
        }

        if let indexRange = contents.nsrangeToIndexRange(adjustedRange) {
            let correctedContents = contents
                .replacingCharacters(in: indexRange, with: correctString)
            return correctedContents
        } else {
            return contents
        }
    }
}
