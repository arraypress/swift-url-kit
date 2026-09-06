//
//  CleanReport.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  What a clean did, so a caller can show it rather than just trust it.
//

import Foundation
import URLCore

/// Everything a clean changed.
public struct CleanReport: Sendable, Codable {
    /// The link as it was given.
    public let original: String
    /// The link with the tracking gone.
    public let cleaned: String
    /// Every parameter removed, in the order they were found.
    public let removed: [RemovedParameter]
    /// The redirect services that were unwrapped, outermost first —
    /// `["Google", "Outlook Safe Links"]` for a Gmail link to a SafeLink.
    public let unwrapped: [String]
    /// Human-readable path changes, e.g. "removed /ref=sr_1_3", "canonicalised to /dp/B08N5WRWNW".
    public let pathChanges: [String]
    /// Whether a tracking `#fragment` was dropped.
    public let fragmentRemoved: Bool

    /// - Parameters:
    ///   - original: The link as given.
    ///   - cleaned: The link with the tracking gone.
    ///   - removed: Every parameter removed.
    ///   - unwrapped: Redirect services peeled, outermost first.
    ///   - pathChanges: Human-readable path changes.
    ///   - fragmentRemoved: Whether a tracking fragment was dropped.
    public init(original: String, cleaned: String, removed: [RemovedParameter] = [],
                unwrapped: [String] = [], pathChanges: [String] = [], fragmentRemoved: Bool = false) {
        self.original = original
        self.cleaned = cleaned
        self.removed = removed
        self.unwrapped = unwrapped
        self.pathChanges = pathChanges
        self.fragmentRemoved = fragmentRemoved
    }

    /// Whether anything changed at all.
    public var didChange: Bool { original != cleaned }

    /// The removed names grouped by category, for a summary line.
    public var removedByCategory: [TrackingCategory: [String]] {
        var out: [TrackingCategory: [String]] = [:]
        for r in removed { if let c = r.category { out[c, default: []].append(r.name) } }
        return out
    }
}
