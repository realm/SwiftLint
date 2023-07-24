import Foundation
import SwiftSyntax
import SwiftIDEUtils

struct CommentStyleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
	typealias ConfigurationType = CommentStyleConfiguration
	var configuration = ConfigurationType()

	static let description = RuleDescription(
		identifier: "comment_style",
		name: "Comment Style",
		description: """
			Allows for options to enforce styling of comments. Should all comments be multiline comments? Should they be single
			line? Or should there be a threshhold, where if x number of single line comments are in a row, should they be
			multiline?
			""",
		kind: .style,
		minSwiftVersion: .current,
		nonTriggeringExamples: CommentStyleRuleExamples.generateExamples(),
		triggeringExamples: [])

	func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
		Visitor(file: file)
	}
}

extension CommentStyleRule {
	class Visitor: ViolationsSyntaxVisitor {
		private let allCommentGroupings: [[SyntaxClassifiedRange]]
		let file: SwiftLintFile

		init(file: SwiftLintFile) {
			self.file = file

			var rangeGroupings: [[SyntaxClassifiedRange]] = []
			var commentsAccumulator: [SyntaxClassifiedRange] = []

			func appendCommentsAccumulator() {
				guard commentsAccumulator.isEmpty == false else { return }

				rangeGroupings.append(commentsAccumulator)
				commentsAccumulator.removeAll()
			}

			for classificationRange in file.syntaxClassifications {
				switch classificationRange.kind {
				case _ where classificationRange.kind.isComment == true:
					if commentsAccumulator.last?.kind != classificationRange.kind {
						appendCommentsAccumulator()
					}
					commentsAccumulator.append(classificationRange)
				case .none:
					if
						let text = Self.convertToString(from: classificationRange, withOriginalString: file.contents),
						text.countOccurrences(of: "\n") > 1 {

						appendCommentsAccumulator()
					}
				default:
					appendCommentsAccumulator()
				}
			}
			appendCommentsAccumulator()

			self.allCommentGroupings = rangeGroupings
			super.init(viewMode: .sourceAccurate)
		}

		override func visitPost(_ node: SourceFileSyntax) {
//			for range in allCommentRanges {
//				switch range.kind {
//				case .lineComment:
//					visitPostComment(range)
//				case .blockComment:
//					visitPostBlockComment(range)
//					//				case .docLineComment:
//					//					docCommentRanges.append(classificationRange)
//					//				case .docBlockComment:
//					//					blockDocCommentRanges.append(classificationRange)
//				case .none:
//					break
//				default: break
//				}
//			}
		}

		func visitPostComment(_ commentRange: SyntaxClassifiedRange) {

		}

		func visitPostBlockComment(_ commentRange: SyntaxClassifiedRange) {

		}

		private static func convertToString(from range: SyntaxClassifiedRange, withOriginalString originalString: String) -> String? {
			let content = Data(originalString.utf8)[range.range.dataRange]
			return String(data: content, encoding: .utf8)
		}

		func replaceRangeWithHyphen(_ range: SyntaxClassifiedRange, originalString: String) -> String? {
			var content = Data(originalString.utf8)
			for i in range.range.dataRange {
				content[i] = "_".utf8.first!
			}
			return String(data: content, encoding: .utf8)
		}
	}
}

extension ByteSourceRange {
	var dataRange: Range<Int> {
		offset..<endOffset
	}
}
