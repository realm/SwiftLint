internal struct MarkRuleExamples {
    static let nonTriggeringExamples = #examples([
        "// MARK: good",
        "// MARK: - good",
        "// MARK: -",
        "// MARK: - ",
        "// BOOKMARK",
        "//BOOKMARK",
        "// BOOKMARKS",
        "// MARK: This is good.",
        "// MARK: - This is good.",
        "// MARK: --- This is good. ---",
        "// MARK: – This is dash separator",
        "// Mark text",
        "//  MarkdownText.swift",
        """
        // MARK: good
        func foo() {
            let bar = 0
              // MARK: good
        }
        """,
        """
        /// Comment
        /// `xxx://marketingOptIn`
        struct S {}

          ///  //marketingOptIn
        struct T {}
        """.excludeFromDocumentation(),
        issue1749Example,
    ])

    static let triggeringExamples = #examples([
        "↓//MARK: bad",
        "↓// MARK:bad",
        "↓//MARK:bad",
        "↓//  MARK: bad",
        "↓// MARK:  bad",
        "↓// MARK: -bad",
        "↓// MARK:- bad",
        "↓// MARK:-bad",
        "↓//MARK: - bad",
        "↓//MARK:- bad",
        "↓//MARK: -bad",
        "↓//MARK:-bad",
        "↓//Mark: bad",
        "↓// Mark: bad",
        "↓// MARK bad",
        "↓//MARK bad",
        "↓// MARK - bad",
        "↓//MARK : bad",
        "↓// MARKL:",
        "↓// MARKR ",
        "↓// MARKK -",
        "↓/// MARK:",
        "↓/// MARK bad",
        """
        // MARK: good
        func foo() {
            let bar = 0
              ↓//MARK: bad
        }
        """,
        issue1029Example,
    ])

    static let corrections = #examplesDictionary([
        "↓//MARK: comment": "// MARK: comment",
        "↓// MARK:  comment": "// MARK: comment",
        "↓// MARK:comment": "// MARK: comment",
        "↓//  MARK: comment": "// MARK: comment",
        "↓//MARK: - comment": "// MARK: - comment",
        "↓// MARK:- comment": "// MARK: - comment",
        "↓// MARK: -comment": "// MARK: - comment",
        "↓// MARK: -  comment": "// MARK: - comment",
        "↓// Mark: comment": "// MARK: comment",
        "↓// Mark: - comment": "// MARK: - comment",
        "↓// MARK - comment": "// MARK: - comment",
        "↓// MARK : comment": "// MARK: comment",
        "↓// MARKL:": "// MARK:",
        "↓// MARKL: -": "// MARK: -",
        "↓// MARKK ": "// MARK: ",
        "↓// MARKK -": "// MARK: -",
        "↓/// MARK:": "// MARK:",
        "↓/// MARK comment": "// MARK: comment",
        issue1029Example: issue1029Correction,
        issue1749Example: issue1749Correction,
    ])
}

// This example should not trigger changes
private let issue1749Correction = issue1749Example

private let issue1029Example = Example("""
    ↓//MARK:- Top-Level bad mark
    ↓//MARK:- Another bad mark
    struct MarkTest {}
    ↓// MARK:- Bad mark
    extension MarkTest {}
    """)

private let issue1029Correction = Example("""
    // MARK: - Top-Level bad mark
    // MARK: - Another bad mark
    struct MarkTest {}
    // MARK: - Bad mark
    extension MarkTest {}
    """)

// https://github.com/realm/SwiftLint/issues/1749
// https://github.com/realm/SwiftLint/issues/3841
private let issue1749Example = Example(
    """
    /*
    func test1() {
    }
    //MARK: mark
    func test2() {
    }
    */
    """
)
