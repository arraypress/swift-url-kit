//
//  URLStripper.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  Removes tracking from URLs: query parameters, redirect wrappers, path
//  attribution and share fragments — offline, from the URL text alone.
//

import Foundation
@_exported import URLCore

/// Cleans tracking out of URLs.
///
/// ```swift
/// URLStripper.clean("https://www.amazon.co.uk/Some-Thing/dp/B08N5WRWNW/ref=sr_1_3?tag=x-21")
/// // "https://www.amazon.co.uk/dp/B08N5WRWNW"
///
/// URLStripper.clean("https://www.google.com/url?q=https://example.com/a&sa=D&ved=2ah")
/// // "https://example.com/a"
/// ```
///
/// Parameters are matched in two tiers. A short **global** table holds names
/// that are tracking on every host (`utm_*`, `gclid`, `fbclid`). A larger
/// **host-scoped** table holds names that are tracking on one site and
/// functional elsewhere — `ref` on Amazon, `s` on Twitter, `t` on Twitter but
/// not YouTube. The first version of this library used one global list of 340
/// names and, measured on fifteen real links, broke twelve of them.
public enum URLStripper {

    /// The cleaned URL.
    public static func clean(_ string: String, options: CleanOptions = .default) -> String {
        Cleaner.clean(string, options: options).cleaned
    }

    /// The cleaned URL. Falls back to the original if the result would not parse.
    public static func clean(_ url: URL, options: CleanOptions = .default) -> URL {
        URL(string: Cleaner.clean(url.absoluteString, options: options).cleaned) ?? url
    }

    /// The cleaned URL together with everything that was removed and why.
    public static func report(_ string: String, options: CleanOptions = .default) -> CleanReport {
        Cleaner.clean(string, options: options)
    }

    /// Only the redirect step: where a `google.com/url?q=…`, Safe Links or
    /// Proofpoint link really goes. `nil` when the URL is not a known redirect.
    /// Offline — shorteners like `t.co` cannot be resolved this way.
    public static func unwrap(_ string: String) -> String? {
        Cleaner.unwrap(string)?.0
    }

    /// Whether a parameter name is tracking — on a particular host, or anywhere
    /// when `host` is nil. Returns the category, or nil for "functional".
    public static func isTracking(_ parameter: String, on host: String? = nil) -> TrackingCategory? {
        let name = parameter.lowercased()
        if let category = GlobalParameters.category(of: name) { return category }
        guard let host = HostMatcher.normalise(host) else { return nil }
        return HostRules.rule(removing: name, among: HostRules.matching(host))?.category
    }
}
