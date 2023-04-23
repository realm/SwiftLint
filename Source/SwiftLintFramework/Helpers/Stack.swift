/// A basic stack type implementing the LIFO principle - only the last inserted element can be accessed and removed.
struct Stack<Element> {
    private var elements = [Element]()

    var isEmpty: Bool {
        elements.isEmpty
    }

    var count: Int {
        elements.count
    }

    mutating func push(_ element: Element) {
        elements.append(element)
    }

    @discardableResult
    mutating func pop() -> Element? {
        elements.popLast()
    }

    func peek() -> Element? {
        elements.last
    }
}

extension Stack: CustomDebugStringConvertible where Element == CustomDebugStringConvertible {
    var debugDescription: String {
        let intermediateElements = count > 1 ? elements[1 ..< count - 1] : []
        return """
            Stack with \(count) elements:
                first: \(elements.first?.debugDescription ?? "")
                intermediate: \(intermediateElements.map(\.debugDescription).joined(separator: ", "))
                last: \(peek()?.debugDescription ?? "")
            """
    }
}
