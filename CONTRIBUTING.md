## Rules

New rules should be added in the `Source/SwiftLintFramework/Rules` directory.

Rules should conform to either the `Rule`, `ASTRule` or `ParameterizedRule`
protocols.

All new rules or changes to existing rules should be accompanied by unit tests.

Whenever possible, prefer adding tests via the `triggeringExamples` and
`nonTriggeringExamples` properties of a rule's `description` rather than adding
those test cases in the unit tests directly. This makes it easier to understand
what rules do by reading their source, and simplifies adding more test cases
over time.

## Tracking changes

All changes should be made via pull requests on GitHub.

When issuing a pull request, please add a summary of your changes to
the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. One Markdown unnumbered list item describing the change.
2. 2 trailing spaces on the last line describing the change.
3. A list of Markdown hyperlinks to the contributors to the change. One entry
   per line. Usually just one.
4. A list of Markdown hyperlinks to the issues the change addresses. One entry
   per line. Usually just one.
5. All CHANGELOG.md content is hard-wrapped at 80 characters.
