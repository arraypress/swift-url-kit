//
//  TrackingRule.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  The shapes the rule tables are written in. Data only — matching lives in
//  Support/.
//

import Foundation
import URLCore

/// How a parameter name is recognised. Names are compared lowercased.
public enum ParameterPattern: Sendable, Hashable {
    /// The whole name, e.g. `gclid`.
    case exact(String)
    /// Any name starting with this, e.g. `utm_` catches `utm_source` and every
    /// variant a marketing team invents next year.
    case prefix(String)

    /// The lowercased text of the pattern, for listings.
    public var text: String {
        switch self {
        case .exact(let name): return name
        case .prefix(let name): return name + "*"
        }
    }
}

/// Tracking that only exists on particular hosts.
public struct HostRule: Sendable {
    public let hosts: [HostPattern]
    public let parameters: [ParameterPattern]
    public let category: TrackingCategory
    /// Shown in a report — "Amazon", "YouTube".
    public let label: String
    /// Hosts the rule must NOT apply to even though they match `hosts` —
    /// Gmail under a Google rule, where `source` is not tracking.
    public let excluding: [HostPattern]

    public init(hosts: [HostPattern], parameters: [ParameterPattern],
                category: TrackingCategory, label: String, excluding: [HostPattern] = []) {
        self.hosts = hosts
        self.parameters = parameters
        self.category = category
        self.label = label
        self.excluding = excluding
    }
}
