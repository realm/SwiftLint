internal struct MarkRuleExamples {
    static let nonTriggeringExamples = [
        Example("// MARK: good"),
        Example("// MARK: - good"),
        Example("// MARK: -"),
        Example("// MARK: - "),
        Example("// BOOKMARK"),
        Example("//BOOKMARK"),
        Example("// BOOKMARKS"),
        Example("// MARK: This is good."),
        Example("// MARK: - This is good."),
        Example("// MARK: --- This is good. ---"),
        Example("// MARK: – This is dash separator"),
        Example("// Mark text"),
        Example("//  MarkdownText.swift"),
        Example("""
        // MARK: good
        func foo() {
            let bar = 0
              // MARK: good
        }
        """),
        Example("""
        /// Comment
        /// `xxx://marketingOptIn`
        struct S {}

          ///  //marketingOptIn
        struct T {}
        """, excludeFromDocumentation: true),
        issue1749Example,
    ]

    static let triggeringExamples = [
        Example("↓//MARK: bad"),
        Example("↓// MARK:bad"),
        Example("↓//MARK:bad"),
        Example("↓//  MARK: bad"),
        Example("↓// MARK:  bad"),
        Example("↓// MARK: -bad"),
        Example("↓// MARK:- bad"),
        Example("↓// MARK:-bad"),
        Example("↓//MARK: - bad"),
        Example("↓//MARK:- bad"),
        Example("↓//MARK: -bad"),
        Example("↓//MARK:-bad"),
        Example("↓//Mark: bad"),
        Example("↓// Mark: bad"),
        Example("↓// MARK bad"),
        Example("↓//MARK bad"),
        Example("↓// MARK - bad"),
        Example("↓//MARK : bad"),
        Example("↓// MARKL:"),
        Example("↓// MARKR "),
        Example("↓// MARKK -"),
        Example("↓/// MARK:"),
        Example("↓/// MARK bad"),
        Example("""
        // MARK: good
        func foo() {
            let bar = 0
              ↓//MARK: bad
        }
        """),
        issue1029Example,
    ]

    static let corrections = [
        Example("↓//MARK: comment"): Example("// MARK: comment"),
        Example("↓// MARK:  comment"): Example("// MARK: comment"),
        Example("↓// MARK:comment"): Example("// MARK: comment"),
        Example("↓//  MARK: comment"): Example("// MARK: comment"),
        Example("↓//MARK: - comment"): Example("// MARK: - comment"),
        Example("↓// MARK:- comment"): Example("// MARK: - comment"),
        Example("↓// MARK: -comment"): Example("// MARK: - comment"),
        Example("↓// MARK: -  comment"): Example("// MARK: - comment"),
        Example("↓// Mark: comment"): Example("// MARK: comment"),
        Example("↓// Mark: - comment"): Example("// MARK: - comment"),
        Example("↓// MARK - comment"): Example("// MARK: - comment"),
        Example("↓// MARK : comment"): Example("// MARK: comment"),
        Example("↓// MARKL:"): Example("// MARK:"),
        Example("↓// MARKL: -"): Example("// MARK: -"),
        Example("↓// MARKK "): Example("// MARK: "),
        Example("↓// MARKK -"): Example("// MARK: -"),
        Example("↓/// MARK:"): Example("// MARK:"),
        Example("↓/// MARK comment"): Example("// MARK: comment"),
        issue1029Example: issue1029Correction,
        issue1749Example: issue1749Correction,
    ]
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
