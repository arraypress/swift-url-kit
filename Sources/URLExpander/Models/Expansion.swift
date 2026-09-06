//
//  Expansion.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Where a link goes, and the road it took.
public struct Expansion: Sendable, Codable, Equatable {
    /// The link as it was given, before any hop.
    public let original: String
    /// Every URL visited after the original, in order. Empty means the
    /// original was already the destination.
    public let hops: [Hop]
    /// The last URL reached.
    public let finalURL: String
    /// The status the destination answered with — 200 for a page, 404 for a
    /// dead link. Nil when the chain ended offline (`offlineOnly`).
    public let finalStatus: Int?

    /// - Parameters:
    ///   - original: The link as given.
    ///   - hops: Every URL visited after it, in order.
    ///   - finalURL: The last URL reached.
    ///   - finalStatus: What the destination answered, or nil when offline.
    public init(original: String, hops: [Hop], finalURL: String, finalStatus: Int?) {
        self.original = original
        self.hops = hops
        self.finalURL = finalURL
        self.finalStatus = finalStatus
    }

    /// How many redirects were followed.
    public var hopCount: Int { hops.count }
    /// Whether the link went anywhere other than itself.
    public var didRedirect: Bool { !hops.isEmpty }
    /// Whether the destination answered as a page that exists. Nil when the
    /// chain ended offline and nothing was asked.
    public var destinationExists: Bool? { finalStatus.map { (200...299).contains($0) } }
}
