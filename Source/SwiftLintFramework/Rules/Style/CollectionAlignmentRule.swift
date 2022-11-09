import SwiftSyntax

struct CollectionAlignmentRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = CollectionAlignmentConfiguration()

    init() {}

    static var description = RuleDescription(
        identifier: "collection_alignment",
        name: "Collection Element Alignment",
        description: "All elements in a collection literal should be vertically aligned",
        kind: .style,
        nonTriggeringExamples: Examples(alignColons: false).nonTriggeringExamples,
        triggeringExamples: Examples(alignColons: false).triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(alignColons: configuration.alignColons, locationConverter: file.locationConverter)
    }
}

private extension CollectionAlignmentRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let alignColons: Bool
        private let locationConverter: SourceLocationConverter

        init(alignColons: Bool, locationConverter: SourceLocationConverter) {
            self.alignColons = alignColons
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ArrayExprSyntax) {
            let locations = node.elements.map { element in
                locationConverter.location(for: element.positionAfterSkippingLeadingTrivia)
            }
            violations.append(contentsOf: validate(keyLocations: locations))
        }

        override func visitPost(_ node: DictionaryElementListSyntax) {
            let locations = node.map { element in
                let position = alignColons ? element.colon.positionAfterSkippingLeadingTrivia :
                                             element.keyExpression.positionAfterSkippingLeadingTrivia
                return locationConverter.location(for: position)
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
                    guard let previousLine = previousLocation.line,
                          let locationLine = location.line,
                          let firstKeyColumn = firstKeyLocation.column,
                          let locationColumn = location.column,
                          previousLine < locationLine,
                          firstKeyColumn != locationColumn else {
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
            return [
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
                """)
            ]
        }

        private var alignColonsNonTriggeringExamples: [Example] {
            return [
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
                """)
            ]
        }

        private var alignLeftTriggeringExamples: [Example] {
            return [
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
                """)
            ]
        }

        private var alignLeftNonTriggeringExamples: [Example] {
            return [
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
                """)
            ]
        }

        private var sharedTriggeringExamples: [Example] {
            return [
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
                """)
            ]
        }

        private var sharedNonTriggeringExamples: [Example] {
            return [
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
                """)
            ]
        }
    }
}
