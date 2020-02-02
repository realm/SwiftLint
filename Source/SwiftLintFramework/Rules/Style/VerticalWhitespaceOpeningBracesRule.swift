import Foundation
import SourceKittenFramework

private extension SwiftLintFile {
    func violatingRanges(for pattern: String) -> [NSRange] {
        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }
}

public struct VerticalWhitespaceOpeningBracesRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let nonTriggeringExamples = [
        Example("[1, 2].map { $0 }.foo()"),
        Example("[1, 2].map { $0 }.filter { num in"),
        Example("// [1, 2].map { $0 }.filter { num in"),
        Example("""
        /*
            class X {

                let x = 5

            }
        */
        """)
    ]

    private static let violatingToValidExamples: [Example: Example] = [
        Example("if x == 5 {\n↓\n    print(\"x is 5\")"): Example("if x == 5 {\n    print(\"x is 5\")"),
        Example("if x == 5 {\n↓\n\n    print(\"x is 5\")"): Example("if x == 5 {\n    print(\"x is 5\")"),
        Example("if x == 5 {\n↓\n  print(\"x is 5\")"): Example("if x == 5 {\n  print(\"x is 5\")"),
        Example("if x == 5 {\n↓\n\tprint(\"x is 5\")"): Example("if x == 5 {\n\tprint(\"x is 5\")"),
        Example("struct MyStruct {\n↓\n    let x = 5"): Example("struct MyStruct {\n    let x = 5"),
        Example("struct MyStruct {\n↓\n  let x = 5"): Example("struct MyStruct {\n  let x = 5"),
        Example("struct MyStruct {\n↓\n\tlet x = 5"): Example("struct MyStruct {\n\tlet x = 5"),
        Example("class X {\n    struct Y {\n↓\n    class Z {\n"): Example("class X {\n    struct Y {\n    class Z {\n"),
        Example("[\n↓\n1,\n2,\n3\n]"): Example("[\n1,\n2,\n3\n]"),
        Example("foo(\n↓\nx: 5,\ny:6\n)"): Example("foo(\nx: 5,\ny:6\n)"),
        Example("class Name {\n↓\n    run(5) { x in print(x) }\n}"):
            Example("class Name {\n    run(5) { x in print(x) }\n}"),
        Example("""
        KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
        ↓
            guard let img = image else { return }
        """): Example("""
        KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
            guard let img = image else { return }
        """),
        Example("""
        }) { _ in
        ↓
            self.dismiss(animated: false, completion: {
        """): Example("""
        }) { _ in
            self.dismiss(animated: false, completion: {
        """)
    ]

    private let pattern = "([{(\\[][ \\t]*(?:[^\\n{]+ in[ \\t]*$)?)((?:\\n[ \\t]*)+)(\\n)"
}

extension VerticalWhitespaceOpeningBracesRule: OptInRule, AutomaticTestableRule {
    public var configurationDescription: String { return "N/A" }

    public init(configuration: Any) throws {}

    public static let description = RuleDescription(
        identifier: "vertical_whitespace_opening_braces",
        name: "Vertical Whitespace after Opening Braces",
        description: "Don't include vertical whitespace (empty line) after opening braces.",
        kind: .style,
        nonTriggeringExamples: (violatingToValidExamples.values + nonTriggeringExamples).sorted(),
        triggeringExamples: Array(violatingToValidExamples.keys).sorted(),
        corrections: violatingToValidExamples.removingViolationMarkers()
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let patternRegex: NSRegularExpression = regex(pattern)

        return file.violatingRanges(for: pattern).map { violationRange in
            let substring = file.contents.substring(from: violationRange.location, length: violationRange.length)
            let substringRange = NSRange(location: 0, length: substring.count)
            let matchResult = patternRegex.firstMatch(in: substring, options: [], range: substringRange)!
            let violatingSubrange = matchResult.range(at: 2)
            let characterOffset = violationRange.location + violatingSubrange.location + 1

            return StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: characterOffset)
            )
        }
    }
}

extension VerticalWhitespaceOpeningBracesRule: CorrectableRule {
    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRanges(for: pattern), for: self)
        guard !violatingRanges.isEmpty else { return [] }

        let patternRegex: NSRegularExpression = regex(pattern)
        let replacementTemplate = "$1$3"
        let description = type(of: self).description

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
