//
//  URLParts.swift
//  URLCore
//
//  Created by David Sherlock on 2026.
//
//  A URL taken apart once, so every extractor and signal reads the same
//  pieces instead of re-parsing.
//

import Foundation

public struct URLParts: Sendable {
    public let url: URL
    /// Lowercased, without a leading `www.`.
    public let host: String
    /// The host exactly as given, lowercased — `www.` kept.
    public let rawHost: String
    public let path: String
    /// Path split on `/`, empty segments dropped.
    public let segments: [String]
    /// First value for each query name, percent-decoded. Names case-sensitive,
    /// as platforms treat them.
    public let query: [String: String]
    public let fragment: String?
    public let port: Int?
    public let scheme: String?
    /// `user` from `user:pass@host`, if any.
    public let user: String?

    public init?(_ url: URL) {
        guard let rawHost = url.host?.lowercased(), !rawHost.isEmpty else { return nil }
        self.url = url
        self.rawHost = rawHost
        self.host = rawHost.hasPrefix("www.") ? String(rawHost.dropFirst(4)) : rawHost
        self.path = url.path
        self.segments = url.path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        var query: [String: String] = [:]
        for item in URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [] where query[item.name] == nil {
            query[item.name] = item.value ?? ""
        }
        self.query = query
        self.fragment = url.fragment
        self.port = url.port
        self.scheme = url.scheme?.lowercased()
        self.user = url.user
    }

    /// The segment after the first occurrence of `marker`, if there is one.
    public func segment(after marker: String) -> String? {
        guard let i = segments.firstIndex(of: marker), i + 1 < segments.count else { return nil }
        return segments[i + 1]
    }

    /// The first segment made only of digits, at least `minimumDigits` long.
    public func firstNumericSegment(minimumDigits: Int = 1) -> String? {
        segments.first { $0.count >= minimumDigits && $0.allSatisfy(\.isNumber) }
    }

    /// The last segment, minus a trailing file extension.
    public var lastSegmentStem: String? {
        guard let last = segments.last else { return nil }
        if let dot = last.lastIndex(of: "."), dot != last.startIndex { return String(last[..<dot]) }
        return last
    }
}
