//
//  Array+URLValidator.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

/// Batch helpers: the same questions asked of a whole list of links at once.
extension Array where Element == String {

    /// The links belonging to one platform.
    public func filterURLs(platform: Platform) -> [String] { filter { $0.urlPlatform == platform } }
    /// The links belonging to one kind of platform.
    public func filterURLs(category: PlatformCategory) -> [String] { filter { $0.urlPlatformCategory == category } }
    /// The links pointing at one kind of file.
    public func filterURLs(mediaType: MediaType) -> [String] { filter { $0.urlMediaType == mediaType } }

    /// Every link bucketed by platform. Unrecognised links land under `.unknown`.
    public func groupURLsByPlatform() -> [Platform: [String]] {
        Dictionary(grouping: self) { URLValidator.detectPlatform(from: $0) }
    }
    /// Every link bucketed by platform category.
    public func groupURLsByCategory() -> [PlatformCategory: [String]] {
        Dictionary(grouping: self) { $0.urlPlatformCategory ?? .unknown }
    }
    /// Every link bucketed by the kind of file it points at.
    public func groupURLsByMediaType() -> [MediaType: [String]] {
        Dictionary(grouping: self) { URLValidator.detectMediaType(from: $0) }
    }

    /// The links that parse as URLs.
    public var validURLs: [String] { filter { $0.isValidURL } }
    /// The links served over HTTPS.
    public var httpsURLs: [String] { filter { $0.isHTTPS } }
    /// The links that go through a shortener — the ones worth expanding.
    public var shortenedURLs: [String] { filter { $0.isShortenedURL } }
    /// The links with a shape phishing and tracking tend to use.
    public var suspiciousURLs: [String] { filter { $0.isSuspiciousURL } }
    /// The links on federated and alternative platforms.
    public var alternativePlatformURLs: [String] { filter { $0.isAlternativePlatformURL } }
    /// The links on web3 platforms.
    public var web3URLs: [String] { filter { $0.isWeb3PlatformURL } }
    /// The links on gaming platforms.
    public var gamingURLs: [String] { filter { $0.isGamingPlatformURL } }
    /// The links on dating platforms.
    public var datingURLs: [String] { filter { $0.isDatingPlatformURL } }
}
