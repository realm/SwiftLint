import Foundation

class OutsideRangesPair {
    func pair(ranges: [NSRange]) -> (first: NSRange, last: NSRange)? {
        guard let firstRange = validRangeItem(ranges.first),
            let lastRange = validRangeItem(ranges.last) else {
                return nil
        }
        return (first: firstRange, last: lastRange)
    }

    private func validRangeItem(_ item: NSRange?) -> NSRange? {
        guard item != nil,
            item?.location != NSNotFound,
            item?.length != NSNotFound else {
                return nil
        }
        return item
    }
}
