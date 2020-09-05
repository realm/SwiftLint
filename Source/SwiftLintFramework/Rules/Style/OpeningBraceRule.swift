import Foundation
import SourceKittenFramework

private let whitespaceAndNewlineCharacterSet = CharacterSet.whitespacesAndNewlines

private extension SwiftLintFile {
    func violatingOpeningBraceRanges() -> [(range: NSRange, location: Int)] {
        return match(pattern: "(?:[^( ]|[\\s(][\\s]+)\\{",
                     excludingSyntaxKinds: SyntaxKind.commentAndStringKinds,
                     excludingPattern: "(?:(?:if|guard|while)\\n[^\\{]+?\\s|\\{\\s*)\\{").compactMap {
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
            Example("func abc() {\n}"),
            Example("[].map() { $0 }"),
            Example("[].map({ })"),
            Example("if let a = b { }"),
            Example("while a == b { }"),
            Example("guard let a = b else { }"),
            Example("if\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }"),
            Example("while\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }"),
            Example("guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else\n{ }"),
            Example("struct Rule {}\n"),
            Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n"),
            Example("""
                    func f(rect: CGRect) {
                        {
                            let centre = CGPoint(x: rect.midX, y: rect.midY)
                            print(centre)
                        }()
                    }
                    """),
            Example("""
                    func f(rect: CGRect) -> () -> Void {
                        {
                            let centre = CGPoint(x: rect.midX, y: rect.midY)
                            print(centre)
                        }
                    }
                    """),
            Example("""
                    func f() -> () -> Void {
                        {}
                    }
                    """)
        ],
        triggeringExamples: [
            Example("func abc()↓{\n}"),
            Example("func abc()\n\t↓{ }"),
            Example("[].map()↓{ $0 }"),
            Example("[].map( ↓{ } )"),
            Example("if let a = b↓{ }"),
            Example("while a == b↓{ }"),
            Example("guard let a = b else↓{ }"),
            Example("if\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
            Example("while\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
            Example("guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else↓{ }"),
            Example("struct Rule↓{}\n"),
            Example("struct Rule\n↓{\n}\n"),
            Example("struct Rule\n\n\t↓{\n}\n"),
            Example("struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}\n"),
            Example("""
            // Get the current thread's TLS pointer. On first call for a given thread,
            // creates and initializes a new one.
            internal static func getPointer()
              -> UnsafeMutablePointer<_ThreadLocalStorage>
            { // <- here
              return _swift_stdlib_threadLocalStorageGet().assumingMemoryBound(
                to: _ThreadLocalStorage.self)
            }
            """),
            Example("""
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
            """)
        ],
        corrections: [
            Example("struct Rule↓{}\n"): Example("struct Rule {}\n"),
            Example("struct Rule\n↓{\n}\n"): Example("struct Rule {\n}\n"),
            Example("struct Rule\n\n\t↓{\n}\n"): Example("struct Rule {\n}\n"),
            Example("struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}\n"):
                Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n"),
            Example("[].map()↓{ $0 }\n"): Example("[].map() { $0 }\n"),
            Example("[].map( ↓{ })\n"): Example("[].map({ })\n"),
            Example("if a == b↓{ }\n"): Example("if a == b { }\n"),
            Example("if\n\tlet a = b,\n\tlet c = d↓{ }\n"): Example("if\n\tlet a = b,\n\tlet c = d { }\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.violatingOpeningBraceRanges().map {
            StyleViolation(ruleDescription: Self.description,
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
            Correction(ruleDescription: Self.description,
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
