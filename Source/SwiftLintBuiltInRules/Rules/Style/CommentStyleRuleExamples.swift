import Foundation

struct CommentStyleRuleExamples {
	static func generateExamples() -> [Example] {
		generatedExampleCode()
			.map { Example($0) }
	}

	static let exampleComments = [
			"""
			// This is a comment
			""",
			"""
			/* This is a comment */
			""",
			"""
			// This is
			// three lines
			// of comments
			""",
			"""
			// This is
			// three lines
			// of comments

			// which then get separated by a single line
			// before more comments
			""",
			"""
			// This is
			// three lines
			// of comments



			// which then get separated by a three lines
			// before more comments
			""",
			"""
			/* This is a
			three line
			comment */
			""",
			"""
			/*
			This is a
			multiline
			comment
			*/
			""",
		]

	private static func generatedExampleCode() -> [String] {
		exampleComments
			.flatMap { comment in
				let naked = """
					\(comment)
					"""
				let inClass = """
					class Foo {
					\(comment.appendIndentation(level: 1))
					}
					"""
				let inFunction = """
					class Foo {
						func bar() {
					\(comment.appendIndentation(level: 2))
						}
					}
					"""
				let inClosure = """
					class Foo {
						let bar = {
					\(comment.appendIndentation(level: 2))
						}
					}
					"""
				let inString = """
					class Bar {
						let mahString = \"""
							// A Comment!
							// But not really
							/*
							It's actually a string!
							tricksies and should not get triggered
							*/
					\(comment.appendIndentation(level: 2))
							\"""
					}
					"""
				let inAll = """
					class FooBar {
					\(comment.appendIndentation(level: 1))
						let bar = {
					\(comment.appendIndentation(level: 2))
						}

						func bar() {
					\(comment.appendIndentation(level: 2))
						}
					}
					"""
				return [naked, inClass, inFunction, inClosure, inString, inAll]
			}
	}
}

private extension String {
	func appendIndentation(level: Int) -> String {
		let tabs = Array(repeating: "\t", count: level)
			.joined()

		return split(separator: "\n", omittingEmptySubsequences: false)
			.map { "\(tabs)\(String($0))\n" }
			.joined()
	}
}
