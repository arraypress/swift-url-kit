//
//  ExpandOptions.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How far to follow, and how.
public struct ExpandOptions: Sendable {
    /// Redirect chains longer than this are a loop or an abuse. Ten is generous.
    public var maxHops: Int = 10
    /// Per request.
    public var timeout: TimeInterval = 8
    /// Only peel wrappers whose destination is in the URL; make no request.
    public var offlineOnly: Bool = false
    /// Some shorteners answer an empty agent with an interstitial or a 403.
    public var userAgent: String = ExpandOptions.defaultUserAgent
    /// How many links a batch follows at once. Only read by the batch entry
    /// point; a single expansion is one chain and cannot be parallelised.
    public var maxConcurrency: Int = 6

    /// Sent on every request, so hosts that refuse an empty agent still answer.
    public static let defaultUserAgent = "url-kit/1.0 (+https://github.com/arraypress/swift-url-kit)"

    /// - Parameters:
    ///   - maxHops: Give up after this many redirects.
    ///   - timeout: Seconds to wait for each host.
    ///   - offlineOnly: Peel known wrappers only; make no request.
    ///   - userAgent: Sent on every request.
    ///   - maxConcurrency: How many links a batch follows at once.
    public init(maxHops: Int = 10, timeout: TimeInterval = 8, offlineOnly: Bool = false,
                userAgent: String = ExpandOptions.defaultUserAgent, maxConcurrency: Int = 6) {
        self.maxHops = maxHops
        self.timeout = timeout
        self.offlineOnly = offlineOnly
        self.userAgent = userAgent
        self.maxConcurrency = maxConcurrency
    }
}
