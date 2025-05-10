import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct CollectionAlignmentRule: Rule {
    var configuration = CollectionAlignmentConfiguration()

    static let description = RuleDescription(
        identifier: "collection_alignment",
        name: "Collection Element Alignment",
        description: "All elements in a collection literal should be vertically aligned",
        kind: .style,
        nonTriggeringExamples: Examples(alignColons: false).nonTriggeringExamples,
        triggeringExamples: Examples(alignColons: false).triggeringExamples
    )
}

private extension CollectionAlignmentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ArrayExprSyntax) {
            let locations = node.elements.map { element in
                locationConverter.location(for: element.positionAfterSkippingLeadingTrivia)
            }
            violations.append(contentsOf: validate(keyLocations: locations))
        }

        override func visitPost(_ node: DictionaryElementListSyntax) {
            let locations = node.map { element in
                let position = configuration.alignColons ? element.colon.positionAfterSkippingLeadingTrivia :
                element.key.positionAfterSkippingLeadingTrivia
                let location = locationConverter.location(for: position)

                let graphemeColumn: Int
                let graphemeClusters = String(
                    locationConverter.sourceLines[location.line - 1].utf8.prefix(location.column - 1)
                )
                if let graphemeClusters {
                    graphemeColumn = graphemeClusters.count + 1
                } else {
                    graphemeColumn = location.column
                }

                return SourceLocation(
                    line: location.line,
                    column: graphemeColumn,
                    offset: location.offset,
                    file: location.file
                )
            }
            violations.append(contentsOf: validate(keyLocations: locations))
        }

        private func validate(keyLocations: [SourceLocation]) -> [AbsolutePosition] {
            guard keyLocations.count >= 2 else {
                return []
            }

            let firstKeyLocation = keyLocations[0]
            let remainingKeyLocations = keyLocations[1...]

            return zip(remainingKeyLocations.indices, remainingKeyLocations)
                .compactMap { index, location -> AbsolutePosition? in
                    let previousLocation = keyLocations[index - 1]
                    let previousLine = previousLocation.line
                    let locationLine = location.line
                    let firstKeyColumn = firstKeyLocation.column
                    let locationColumn = location.column
                    guard previousLine < locationLine, firstKeyColumn != locationColumn else {
                        return nil
                    }

                    return locationConverter.position(ofLine: locationLine, column: locationColumn)
                }
        }
    }
}

extension CollectionAlignmentRule {
    struct Examples {
        private let alignColons: Bool

        init(alignColons: Bool) {
            self.alignColons = alignColons
        }

        var triggeringExamples: [Example] {
            let examples = alignColons ? alignColonsTriggeringExamples : alignLeftTriggeringExamples
            return examples + sharedTriggeringExamples
        }

        var nonTriggeringExamples: [Example] {
            let examples = alignColons ? alignColonsNonTriggeringExamples : alignLeftNonTriggeringExamples
            return examples + sharedNonTriggeringExamples
        }

        private var alignColonsTriggeringExamples: [Example] {
            [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                    "fizz"↓: 2,
                    "buzz"↓: 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                    "beta"↓: "b",
                    "gamma": "c",
                    "delta": "d",
                    "epsilon"↓: "e"
                ]
                """),
                Example("""
                var weirdColons = [
                    "a"    :  1,
                    "b"  ↓:2,
                    "c"    :      3
                ]
                """),
            ]
        }

        private var alignColonsNonTriggeringExamples: [Example] {
            [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                   "fizz": 2,
                   "buzz": 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                     "beta": "b",
                    "gamma": "g",
                    "delta": "d",
                  "epsilon": "e"
                ]
                """),
                Example("""
                var weirdColons = [
                    "a"    :  1,
                      "b"  :2,
                       "c" :      3
                ]
                """),
                Example("""
                NSAttributedString(string: "…", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular),
                                                  .foregroundColor: UIColor(white: 0, alpha: 0.2)])
                """),
            ]
        }

        private var alignLeftTriggeringExamples: [Example] {
            [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                   ↓"fizz": 2,
                   ↓"buzz": 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                     ↓"beta": "b",
                    "gamma": "g",
                    "delta": "d",
                  ↓"epsilon": "e"
                ]
                """),
                Example("""
                let meals = [
                                "breakfast": "oatmeal",
                                "lunch": "sandwich",
                    ↓"dinner": "burger"
                ]
                """),
            ]
        }

        private var alignLeftNonTriggeringExamples: [Example] {
            [
                Example("""
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                    "fizz": 2,
                    "buzz": 2
                ])
                """),
                Example("""
                let abc = [
                    "alpha": "a",
                    "beta": "b",
                    "gamma": "g",
                    "delta": "d",
                    "epsilon": "e"
                ]
                """),
                Example("""
                let meals = [
                                "breakfast": "oatmeal",
                                "lunch": "sandwich",
                                "dinner": "burger"
                ]
                """),
                Example("""
                NSAttributedString(string: "…", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular),
                                                             .foregroundColor: UIColor(white: 0, alpha: 0.2)])
                """),
            ]
        }

        private var sharedTriggeringExamples: [Example] {
            [
                Example("""
                let coordinates = [
                    CLLocationCoordinate2D(latitude: 0, longitude: 33),
                        ↓CLLocationCoordinate2D(latitude: 0, longitude: 66),
                    CLLocationCoordinate2D(latitude: 0, longitude: 99)
                ]
                """),
                Example("""
                var evenNumbers: Set<Int> = [
                    2,
                  ↓4,
                    6
                ]
                """),
            ]
        }

        private var sharedNonTriggeringExamples: [Example] {
            [
                Example("""
                let coordinates = [
                    CLLocationCoordinate2D(latitude: 0, longitude: 33),
                    CLLocationCoordinate2D(latitude: 0, longitude: 66),
                    CLLocationCoordinate2D(latitude: 0, longitude: 99)
                ]
                """),
                Example("""
                var evenNumbers: Set<Int> = [
                    2,
                    4,
                    6
                ]
                """),
                Example("""
                let abc = [1, 2, 3, 4]
                """),
                Example("""
                let abc = [
                    1, 2, 3, 4
                ]
                """),
                Example("""
                let abc = [
                    "foo": "bar", "fizz": "buzz"
                ]
                """),
            ]
        }
    }
}
