import Foundation
import SourceKittenFramework

private extension SwiftLintFile {
    func violatingRanges(for pattern: String) -> [NSRange] {
        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}

struct VerticalWhitespaceOpeningBracesRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    private static let nonTriggeringExamples = [
        Example("[1, 2].map { $0 }.foo()"),
        Example("[1, 2].map { $0 }.filter { num in true }"),
        Example("// [1, 2].map { $0 }.filter { num in true }"),
        Example("""
        /*
            class X {

                let x = 5

            }
        */
        """)
    ]

    private static let violatingToValidExamples: [Example: Example] = [
        Example("""
        if x == 5 {
        ↓
          print("x is 5")
        }
        """): Example("""
            if x == 5 {
              print("x is 5")
            }
            """),
        Example("""
        if x == 5 {
        ↓

          print("x is 5")
        }
        """): Example("""
            if x == 5 {
              print("x is 5")
            }
            """),
        Example("""
        struct MyStruct {
        ↓
          let x = 5
        }
        """): Example("""
            struct MyStruct {
              let x = 5
            }
            """),
        Example("""
        class X {
          struct Y {
        ↓
            class Z {
            }
          }
        }
        """): Example("""
            class X {
              struct Y {
                class Z {
                }
              }
            }
            """),
        Example("""
        [
        ↓
        1,
        2,
        3
        ]
        """): Example("""
            [
            1,
            2,
            3
            ]
            """),
        Example("""
        foo(
        ↓
          x: 5,
          y:6
        )
        """): Example("""
            foo(
              x: 5,
              y:6
            )
            """),
        Example("""
        func foo() {
        ↓
          run(5) { x in
            print(x)
          }
        }
        """): Example("""
            func foo() {
              run(5) { x in
                print(x)
              }
            }
            """),
        Example("""
        KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
        ↓
            guard let img = image else { return }
        }
        """): Example("""
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
                guard let img = image else { return }
            }
            """),
        Example("""
        foo({ }) { _ in
        ↓
          self.dismiss(animated: false, completion: {
          })
        }
        """): Example("""
            foo({ }) { _ in
              self.dismiss(animated: false, completion: {
              })
            }
            """)
    ]

    private let pattern = "([{(\\[][ \\t]*(?:[^\\n{]+ in[ \\t]*$)?)((?:\\n[ \\t]*)+)(\\n)"
}

extension VerticalWhitespaceOpeningBracesRule: OptInRule {
    init(configuration: Any) throws {}

    static let description = RuleDescription(
        identifier: "vertical_whitespace_opening_braces",
        name: "Vertical Whitespace after Opening Braces",
        description: "Don't include vertical whitespace (empty line) after opening braces",
        kind: .style,
        nonTriggeringExamples: (violatingToValidExamples.values + nonTriggeringExamples).sorted(),
        triggeringExamples: Array(violatingToValidExamples.keys).sorted(),
        corrections: violatingToValidExamples.removingViolationMarkers()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let patternRegex: NSRegularExpression = regex(pattern)

        return file.violatingRanges(for: pattern).map { violationRange in
            let substring = file.contents.substring(from: violationRange.location, length: violationRange.length)
            let substringRange = NSRange(location: 0, length: substring.count)
            let matchResult = patternRegex.firstMatch(in: substring, options: [], range: substringRange)!
            let violatingSubrange = matchResult.range(at: 2)
            let characterOffset = violationRange.location + violatingSubrange.location + 1

            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: characterOffset)
            )
        }
    }
}

extension VerticalWhitespaceOpeningBracesRule: CorrectableRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRanges(for: pattern), for: self)
        guard violatingRanges.isNotEmpty else { return [] }

        let patternRegex: NSRegularExpression = regex(pattern)
        let replacementTemplate = "$1$3"
        let description = Self.description

        var corrections = [Correction]()
        var fileContents = file.contents

        for violationRange in violatingRanges.reversed() {
            fileContents = patternRegex.stringByReplacingMatches(
                in: fileContents,
                options: [],
                range: violationRange,
                withTemplate: replacementTemplate
            )

            let location = Location(file: file, characterOffset: violationRange.location)
            let correction = Correction(ruleDescription: description, location: location)
            corrections.append(correction)
        }

        file.write(fileContents)
        return corrections
    }
}
