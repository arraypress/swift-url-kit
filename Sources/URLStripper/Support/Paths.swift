//
//  Paths.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  Tracking that lives in the PATH, not the query, and the sites where the
//  product URL has a short canonical form.
//

import Foundation
import URLCore

enum Paths {

    /// Cleans a path for a normalised host. Returns the new path and what changed.
    static func clean(_ path: String, host: String) -> (path: String, changes: [String]) {
        if HostMatcher.matches(host, any: [.brand("amazon"), .exact("a.co")]) { return amazon(path) }
        if HostMatcher.matches(host, .brand("ebay")) { return ebay(path) }
        return (path, [])
    }

    /// Amazon carries attribution in path segments — `/ref=sr_1_3` — and wraps
    /// the product id in a slug that changes with the page title. Everything a
    /// product URL needs is `/dp/ASIN` (plus a `/-/xx` locale prefix when present).
    private static func amazon(_ path: String) -> (String, [String]) {
        var changes: [String] = []
        var segments = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)

        let refs = segments.filter { $0.hasPrefix("ref=") }
        if !refs.isEmpty {
            segments.removeAll { $0.hasPrefix("ref=") }
            changes.append("removed /" + refs.joined(separator: ", /"))
        }

        var locale: [String] = []
        if segments.count >= 2, segments[0] == "-" { locale = Array(segments[0...1]) }

        if let asin = asin(in: segments) {
            let canonical = locale + ["dp", asin]
            if canonical != segments {
                changes.append("canonicalised to /dp/\(asin)")
                segments = canonical
            }
        }
        return (segments.isEmpty ? "/" : "/" + segments.joined(separator: "/"), changes)
    }

    /// The ASIN in a product path: `/dp/X`, `/gp/product/X`, `/gp/aw/d/X`,
    /// `/exec/obidos/ASIN/X`, `/Some-Title/dp/X`. An ASIN is exactly ten
    /// upper-case letters and digits.
    static func asin(in segments: [String]) -> String? {
        func isASIN(_ s: String) -> Bool {
            s.count == 10 && s.allSatisfy { ($0.isLetter && $0.isUppercase) || $0.isNumber }
        }
        for (i, s) in segments.enumerated() where i + 1 < segments.count {
            let next = segments[i + 1]
            switch s {
            case "dp", "ASIN", "d":
                if isASIN(next) { return next }
            case "product":
                if i > 0, segments[i - 1] == "gp", isASIN(next) { return next }
            default:
                continue
            }
        }
        return nil
    }

    /// eBay item URLs carry the title as a slug: `/itm/Some-Title/123456789012`
    /// is `/itm/123456789012`.
    private static func ebay(_ path: String) -> (String, [String]) {
        let segments = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        guard let i = segments.firstIndex(of: "itm"), i + 2 < segments.count else { return (path, []) }
        let id = segments[i + 2]
        guard id.count >= 9, id.allSatisfy(\.isNumber) else { return (path, []) }
        let rebuilt = Array(segments[0...i]) + [id]
        return ("/" + rebuilt.joined(separator: "/"), ["canonicalised to /itm/\(id)"])
    }
}
