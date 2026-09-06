//
//  RemovedParameter.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One parameter that was removed, and why.
public struct RemovedParameter: Sendable, Codable, Hashable {
    /// The parameter name as it appeared in the URL.
    public let name: String
    /// What kind of tracking it was, when the rule that matched said so.
    public let category: TrackingCategory?
    /// "global" for parameters that are tracking anywhere; otherwise the
    /// host rule that matched — "Amazon", "YouTube"; "custom" for a caller's
    /// own list.
    public let scope: String

    /// - Parameters:
    ///   - name: The parameter name as it appeared.
    ///   - category: What kind of tracking it was, if known.
    ///   - scope: Which rule removed it.
    public init(name: String, category: TrackingCategory?, scope: String) {
        self.name = name
        self.category = category
        self.scope = scope
    }
}
