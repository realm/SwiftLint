/// Interface providing access to a cache description.
public protocol CacheDescriptionProvider {
    /// The cache description which will be used to determine if a previous
    /// cached value is still valid given the new cache value.
    var cacheDescription: String { get }
}
