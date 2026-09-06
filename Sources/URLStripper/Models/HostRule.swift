//
//  HostRule.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  One of the shapes the rule tables are written in. Data only — matching
//  lives in Support/.
//

import Foundation
import URLCore

/// Tracking that only exists on particular hosts.
///
/// Host scope is the whole point: `ref` is tracking on Amazon and a git ref on
/// GitHub, so a rule that removed it everywhere would break real links.
public struct HostRule: Sendable {
    /// The hosts this rule applies to.
    public let hosts: [HostPattern]
    /// The parameter names it removes on those hosts.
    public let parameters: [ParameterPattern]
    /// What kind of tracking these parameters are.
    public let category: TrackingCategory
    /// Shown in a report — "Amazon", "YouTube".
    public let label: String
    /// Hosts the rule must NOT apply to even though they match `hosts` —
    /// Gmail under a Google rule, where `source` is not tracking.
    public let excluding: [HostPattern]

    /// - Parameters:
    ///   - hosts: The hosts this rule applies to.
    ///   - parameters: The names it removes on them.
    ///   - category: What kind of tracking they are.
    ///   - label: Shown in a report.
    ///   - excluding: Hosts to spare despite matching `hosts`.
    public init(hosts: [HostPattern], parameters: [ParameterPattern],
                category: TrackingCategory, label: String, excluding: [HostPattern] = []) {
        self.hosts = hosts
        self.parameters = parameters
        self.category = category
        self.label = label
        self.excluding = excluding
    }
}
