import Foundation
import SwiftLintCore

struct CommentStyleConfiguration: RuleConfiguration, Equatable {
	typealias Parent = CommentStyleRule

	@ConfigurationElement(key: "comment_style")
	private(set) var commentStyle: Style? = .multiline

	mutating func apply(configuration: Any) throws {
		guard
			let configurationDict = configuration as? [String: Any]
		else { throw ConfigurationError.incorrectlyFormattedConfigurationDictionary }

		if let commentStyleString: String = configurationDict[key: $commentStyle] {
			let style = Style(rawValue: commentStyleString)
			style != nil ? () : print("'\(commentStyleString)' invalid for comment style. No style enforce.")
			self.commentStyle = commentStyle
		}
	}
}

extension CommentStyleConfiguration {
	enum Style: String, AcceptableByConfigurationElement {
		case multiline
		case singleline

		func asOption() -> SwiftLintCore.OptionType { .string(rawValue) }
	}

	enum ConfigurationError: Error {
		case incorrectlyFormattedConfigurationDictionary
	}
}


extension Dictionary where Key == String, Value == Any {
	subscript<T>(key key: String) -> T? {
		self[key] as? T
	}
}
