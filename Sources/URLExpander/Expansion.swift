//
//  Expansion.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One step on the way from a link to where it really goes.
public struct Hop: Sendable, Codable, Equatable {
    /// The URL this hop arrived at.
    public let url: String
    /// The HTTP status that sent us here — nil for an offline unwrap.
    public let status: Int?
    /// How: `"301"`, `"302 (GET)"` when HEAD was refused, `"offline: Google"`
    /// when the destination was read out of the URL without a request.
    public let via: String

    public init(url: String, status: Int?, via: String) {
        self.url = url
        self.status = status
        self.via = via
    }
}

/// Where a link goes, and the road it took.
public struct Expansion: Sendable, Codable, Equatable {
    public let original: String
    /// Every URL visited after the original, in order. Empty means the
    /// original was already the destination.
    public let hops: [Hop]
    /// The last URL reached.
    public let finalURL: String
    /// The status the destination answered with — 200 for a page, 404 for a
    /// dead link. Nil when the chain ended offline (`offlineOnly`).
    public let finalStatus: Int?

    public init(original: String, hops: [Hop], finalURL: String, finalStatus: Int?) {
        self.original = original
        self.hops = hops
        self.finalURL = finalURL
        self.finalStatus = finalStatus
    }

    public var hopCount: Int { hops.count }
    /// Whether the link went anywhere other than itself.
    public var didRedirect: Bool { !hops.isEmpty }
    /// Whether the destination answered as a page that exists.
    public var destinationExists: Bool? { finalStatus.map { (200...299).contains($0) } }
}

/// How far to follow, and how.
public struct ExpandOptions: Sendable {
    /// Redirect chains longer than this are a loop or an abuse. Ten is generous.
    public var maxHops: Int = 10
    /// Per request.
    public var timeout: TimeInterval = 8
    /// Only peel wrappers whose destination is in the URL; make no request.
    public var offlineOnly: Bool = false
    /// Some shorteners answer an empty agent with an interstitial or a 403.
    public var userAgent: String = "url-kit/1.0 (+https://github.com/arraypress/swift-url-kit)"

    public init(maxHops: Int = 10, timeout: TimeInterval = 8, offlineOnly: Bool = false,
                userAgent: String = "url-kit/1.0 (+https://github.com/arraypress/swift-url-kit)") {
        self.maxHops = maxHops
        self.timeout = timeout
        self.offlineOnly = offlineOnly
        self.userAgent = userAgent
    }
}

/// Why a link could not be followed.
public enum ExpandError: Error, LocalizedError, Sendable, Equatable {
    case notAURL(String)
    /// `mailto:`, `javascript:` and friends are not followed.
    case unsupportedScheme(String)
    case tooManyHops(Int)
    /// A redirect returned to a URL already visited.
    case redirectLoop(String)
    case timedOut(String)
    case network(String)

    public var errorDescription: String? {
        switch self {
        case .notAURL(let s): return "not a URL: \(s)"
        case .unsupportedScheme(let s): return "only http and https links are followed, not \(s):"
        case .tooManyHops(let n): return "still redirecting after \(n) hops"
        case .redirectLoop(let url): return "redirect loop at \(url)"
        case .timedOut(let url): return "no answer in time from \(url)"
        case .network(let why): return why
        }
    }
}
