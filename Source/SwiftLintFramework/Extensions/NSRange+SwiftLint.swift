import Foundation

extension NSRange {
    func intersects(_ range: NSRange) -> Bool {
        return NSIntersectionRange(self, range).length > 0
    }

    func intersects(_ ranges: [NSRange]) -> Bool {
        for range in ranges where intersects(range) {
            return true
        }
        return false
    }
}
