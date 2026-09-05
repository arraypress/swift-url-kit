//
//  TrackingParameters.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  A read-only view of the rule tables, kept under the name the first
//  version exported. Note the change of meaning: these sets now hold only
//  parameters that are tracking on EVERY host. Site-specific names such as
//  Amazon's `ref` or Twitter's `s` are in `hostRules`, where they belong.
//

import Foundation
import URLCore

/// The parameter database, for inspection.
public enum TrackingParameters {

    /// Every exact name that is tracking anywhere. Prefix rules (`utm_*`)
    /// are patterns, not names, and are listed under ``prefixes``.
    public static var all: Set<String> {
        TrackingCategory.allCases.reduce(into: Set<String>()) { $0.formUnion(GlobalParameters.exactNames(in: $1)) }
    }

    public static var analytics: Set<String> { GlobalParameters.exactNames(in: .analytics) }
    public static var social: Set<String> { GlobalParameters.exactNames(in: .social) }
    public static var email: Set<String> { GlobalParameters.exactNames(in: .email) }
    public static var ecommerce: Set<String> { GlobalParameters.exactNames(in: .ecommerce) }
    public static var other: Set<String> { GlobalParameters.exactNames(in: .other) }

    /// Name prefixes that are tracking anywhere — `utm_`, `mtm_`, `hsa_`.
    public static var prefixes: Set<String> {
        TrackingCategory.allCases.reduce(into: Set<String>()) { $0.formUnion(GlobalParameters.prefixes(in: $1)) }
    }

    /// Tracking that only exists on particular sites.
    public static var hostRules: [HostRule] { HostRules.all }

    /// Redirect pages the cleaner can see through.
    public static var redirects: [RedirectRule] { Redirects.rules }

    /// The category of a name on a host — nil means "functional, keep it".
    public static func category(of parameter: String, on host: String? = nil) -> TrackingCategory? {
        URLStripper.isTracking(parameter, on: host)
    }
}
