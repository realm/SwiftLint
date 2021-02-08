import Dispatch

extension Array {
    func parallelCompactMap<T>(transform: (Element) -> T?) -> [T] {
        return parallelMap(transform: transform).compactMap { $0 }
    }

    func parallelMap<T>(transform: (Element) -> T) -> [T] {
        return [T](unsafeUninitializedCapacity: count) { buffer, initializedCount in
            let baseAddress = buffer.baseAddress!
            DispatchQueue.concurrentPerform(iterations: count) { index in
                // Using buffer[index] does assignWithTake which tries
                // to read the uninitialized value (to release it) and crashes
                (baseAddress + index).initialize(to: transform(self[index]))
            }
            initializedCount = count
        }
    }
}
