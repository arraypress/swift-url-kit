//
//  CleanOptions.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

/// What a clean is allowed to do.
public struct CleanOptions: Sendable {
    /// Which families of parameter to remove. Everything, by default.
    public var categories: Set<TrackingCategory>
    /// Replace a known redirect page with the destination it carries.
    /// `google.com/url?q=X` becomes `X`. Offline; nothing is fetched.
    public var unwrapRedirects: Bool
    /// Remove tracking that lives in the PATH — Amazon's `/ref=…` segments —
    /// and canonicalise the product URL to `/dp/ASIN`.
    public var cleanPath: Bool
    /// Remove tracking fragments: `#xtor=`, `#utm_source=`, AddThis's `#.abc.twitter`.
    public var stripFragmentTracking: Bool
    /// Extra parameter names to remove, whatever the host.
    public var additional: Set<String>
    /// Parameter names never to remove. Wins over every rule.
    public var preserve: Set<String>

    public init(categories: Set<TrackingCategory> = TrackingCategory.all,
                unwrapRedirects: Bool = true,
                cleanPath: Bool = true,
                stripFragmentTracking: Bool = true,
                additional: Set<String> = [],
                preserve: Set<String> = []) {
        self.categories = categories
        self.unwrapRedirects = unwrapRedirects
        self.cleanPath = cleanPath
        self.stripFragmentTracking = stripFragmentTracking
        self.additional = Set(additional.map { $0.lowercased() })
        self.preserve = Set(preserve.map { $0.lowercased() })
    }

    /// The full clean: every category, redirects unwrapped, path and fragment cleaned.
    public static let `default` = CleanOptions()

    /// One category and nothing else — no unwrapping, no path or fragment
    /// changes. What the `withoutAnalytics`-style helpers use, so that asking
    /// for one thing does exactly one thing.
    public static func only(_ category: TrackingCategory) -> CleanOptions {
        CleanOptions(categories: [category], unwrapRedirects: false,
                     cleanPath: false, stripFragmentTracking: false)
    }

    /// Named parameters only; no tracking rules at all.
    static func onlyParameters(_ names: [String]) -> CleanOptions {
        CleanOptions(categories: [], unwrapRedirects: false, cleanPath: false,
                     stripFragmentTracking: false, additional: Set(names))
    }
}
