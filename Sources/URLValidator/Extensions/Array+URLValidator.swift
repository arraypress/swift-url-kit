//
//  Array+URLValidator.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

extension Array where Element == String {

    public func filterURLs(platform: Platform) -> [String] { filter { $0.urlPlatform == platform } }
    public func filterURLs(category: PlatformCategory) -> [String] { filter { $0.urlPlatformCategory == category } }
    public func filterURLs(mediaType: MediaType) -> [String] { filter { $0.urlMediaType == mediaType } }

    public func groupURLsByPlatform() -> [Platform: [String]] {
        Dictionary(grouping: self) { URLValidator.detectPlatform(from: $0) }
    }
    public func groupURLsByCategory() -> [PlatformCategory: [String]] {
        Dictionary(grouping: self) { $0.urlPlatformCategory ?? .unknown }
    }
    public func groupURLsByMediaType() -> [MediaType: [String]] {
        Dictionary(grouping: self) { URLValidator.detectMediaType(from: $0) }
    }

    public var validURLs: [String] { filter { $0.isValidURL } }
    public var httpsURLs: [String] { filter { $0.isHTTPS } }
    public var shortenedURLs: [String] { filter { $0.isShortenedURL } }
    public var suspiciousURLs: [String] { filter { $0.isSuspiciousURL } }
    public var alternativePlatformURLs: [String] { filter { $0.isAlternativePlatformURL } }
    public var web3URLs: [String] { filter { $0.isWeb3PlatformURL } }
    public var gamingURLs: [String] { filter { $0.isGamingPlatformURL } }
    public var datingURLs: [String] { filter { $0.isDatingPlatformURL } }
}
