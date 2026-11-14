import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif
import Testing

@testable import SwiftLintFramework

/// Renders hostile text with every XML reporter and checks that the report parses, and pins down exactly what
/// `escapedForXML()` writes.
struct XMLReporterWellFormedTests {
    private static var reporters: [any Reporter.Type] {
        [
            CheckstyleReporter.self,
            JUnitReporter.self,
            GitLabJUnitReporter.self,
        ]
    }

    @Test(arguments: [
        "TODOs should be resolved (\u{1B}[1mbold\u{1B}[0m later)", // ANSI escape, as `todo` copies it from a comment
        "Avoid print\u{1}",
        "a\u{FFFE}b",
        "use a <\u{301} b", // `<` + U+0301 COMBINING ACUTE ACCENT is a single `Character`
        "x &\u{301} y",
        "say \"\u{301}hi\"",
        "it'\u{301}s",
        "x ]]>\u{301} y", // `]]>` is not allowed in element content
        "a < b & \"c\" 'd' > e",
    ])
    func reasonKeepsReportWellFormed(reason: String) {
        for reporter in Self.reporters {
            let report = reporter.generateReport([Self.violation(reason: reason)])
            #expect(Self.isWellFormed(report), "\(reporter.identifier): \(report)")
        }
    }

    @Test
    func filePathKeepsReportWellFormed() {
        let file = URL.cwd.appending(path: "a\u{1}<\u{301}b.swift", directoryHint: .notDirectory)
        for reporter in Self.reporters {
            let report = reporter.generateReport([Self.violation(reason: "Reason", file: file)])
            #expect(Self.isWellFormed(report), "\(reporter.identifier): \(report)")
        }
    }

    /// A `custom_rules` key becomes the rule identifier unchanged.
    @Test(arguments: ["a<b", "a&b", "it's", "a'\u{301}b"])
    func ruleIdentifierKeepsReportWellFormed(identifier: String) {
        for reporter in Self.reporters {
            let report = reporter.generateReport([Self.violation(identifier: identifier, reason: "Avoid print")])
            #expect(Self.isWellFormed(report), "\(reporter.identifier): \(report)")
        }
    }

    @Test
    func escapingReplacesCharactersXMLCannotHold() {
        #expect(Self.scalars(
            escaping: "a\u{0}b\u{8}c\u{B}d\u{C}e\u{1B}f\u{1F}g",
            equal: "a\u{FFFD}b\u{FFFD}c\u{FFFD}d\u{FFFD}e\u{FFFD}f\u{FFFD}g"
        ))
        #expect(Self.scalars(escaping: "a\u{FFFE}b\u{FFFF}c", equal: "a\u{FFFD}b\u{FFFD}c"))
        #expect(Self.scalars(escaping: "a\tb\nc\rd\r\ne", equal: "a\tb\nc\rd\r\ne"))
        #expect(Self.scalars(escaping: "\u{7F}\u{85}\u{FFFD}\u{1FFFE}", equal: "\u{7F}\u{85}\u{FFFD}\u{1FFFE}"))
    }

    @Test
    func escapingHandlesMarkupBeforeCombiningMarks() {
        // Kept out of `#expect`, whose expansion does not compile with `\"` + U+0301 in a call argument.
        let markup = "<\u{301}&\u{301}\"\u{301}'\u{301}>\u{301}"
        let escapedMarkup = "&lt;\u{301}&amp;\u{301}&quot;\u{301}&apos;\u{301}&gt;\u{301}"
        #expect(Self.scalars(escaping: markup, equal: escapedMarkup))
        // U+226E NOT LESS-THAN is canonically equivalent to `<` + U+0338, but is not markup.
        #expect(Self.scalars(escaping: "\u{226E} <\u{338}", equal: "\u{226E} &lt;\u{338}"))
    }

    @Test
    func escapingLeavesOtherTextUnchanged() {
        #expect(Self.scalars(
            escaping: "a < b & \"c\" 'd' > e",
            equal: "a &lt; b &amp; &quot;c&quot; &apos;d&apos; &gt; e"
        ))
        #expect(Self.scalars(escaping: "&amp;", equal: "&amp;amp;"))
        #expect(Self.scalars(escaping: "cafe\u{301} caf\u{E9} 🍰 👨‍👩‍👧", equal: "cafe\u{301} caf\u{E9} 🍰 👨‍👩‍👧"))
        #expect(Self.scalars(escaping: "", equal: ""))
    }

    /// Compares Unicode scalars, because `String`'s `==` treats canonically equivalent text as equal.
    private static func scalars(escaping input: String, equal expected: String) -> Bool {
        input.escapedForXML().unicodeScalars.elementsEqual(expected.unicodeScalars)
    }

    /// Builds a violation for a rule identifier that no built-in rule registers.
    private static func violation(
        identifier: String = "xml_reporter_test",
        reason: String,
        file: URL = URL.cwd.appending(path: "Test.swift", directoryHint: .notDirectory)
    ) -> StyleViolation {
        StyleViolation(
            ruleDescription: RuleDescription(identifier: identifier, name: "Test", description: "", kind: .lint),
            location: Location(file: file, line: 1, character: 4),
            reason: reason
        )
    }

    private static func isWellFormed(_ report: String) -> Bool {
        XMLParser(data: Data(report.utf8)).parse()
    }
}
