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

/// One parameter that was removed, and why.
public struct RemovedParameter: Sendable, Codable, Hashable {
    public let name: String
    public let category: TrackingCategory?
    /// "global" for parameters that are tracking anywhere; otherwise the
    /// host rule that matched — "Amazon", "YouTube"; "custom" for a caller's
    /// own list.
    public let scope: String

    public init(name: String, category: TrackingCategory?, scope: String) {
        self.name = name
        self.category = category
        self.scope = scope
    }
}

/// Everything a clean changed.
public struct CleanReport: Sendable, Codable {
    public let original: String
    public let cleaned: String
    public let removed: [RemovedParameter]
    /// The redirect services that were unwrapped, outermost first —
    /// `["Google", "Outlook Safe Links"]` for a Gmail link to a SafeLink.
    public let unwrapped: [String]
    /// Human-readable path changes, e.g. "removed /ref=sr_1_3", "canonicalised to /dp/B08N5WRWNW".
    public let pathChanges: [String]
    public let fragmentRemoved: Bool

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
