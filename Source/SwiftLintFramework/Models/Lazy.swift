// extracted from https://forums.swift.org/t/pitch-declaring-local-variables-as-lazy/9287/3
internal class Lazy<Result> {
    private var computation: () -> Result
    private(set) lazy var value: Result = computation()

    init(_ computation: @escaping @autoclosure () -> Result) {
        self.computation = computation
    }
}
