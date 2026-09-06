//
//  HostMatcher.swift
//  URLCore
//
//  Created by David Sherlock on 2026.
//
//  Pure host matching, shared by the stripper's rules and the validator's index.
//

import Foundation

/// Pure host matching. Every rule table in the kit is matched through here,
/// so "does this host count as Amazon" has exactly one answer.
public enum HostMatcher {

    /// Lowercased, no `www.`, no trailing dot. `nil` for empty.
    public static func normalise(_ host: String?) -> String? {
        guard var h = host?.lowercased(), !h.isEmpty else { return nil }
        if h.hasSuffix(".") { h.removeLast() }
        if h.hasPrefix("www.") { h.removeFirst(4) }
        return h
    }

    /// Whether a normalised host satisfies one pattern.
    public static func matches(_ host: String, _ pattern: HostPattern) -> Bool {
        switch pattern {
        case .exact(let e): return host == e
        case .suffix(let s): return host == s || host.hasSuffix("." + s)
        case .brand(let b): return matchesBrand(host, b)
        }
    }

    /// Whether a normalised host satisfies any of the patterns.
    public static func matches(_ host: String, any patterns: [HostPattern]) -> Bool {
        patterns.contains { matches(host, $0) }
    }

    /// `amazon` matches `amazon.com`, `amazon.co.uk`, `smile.amazon.de`,
    /// `amazon.com.au` — a label equal to the brand followed by one or two
    /// short TLD labels — and nothing else.
    public static func matchesBrand(_ host: String, _ brand: String) -> Bool {
        let labels = host.split(separator: ".").map(String.init)
        guard let i = labels.firstIndex(of: brand) else { return false }
        return isTLDTail(labels[(i + 1)...])
    }

    /// One or two labels of 2–3 letters: `com`, `co.uk`, `com.au`, `de`.
    public static func isTLDTail(_ tail: ArraySlice<String>) -> Bool {
        (1...2).contains(tail.count) && tail.allSatisfy { (2...3).contains($0.count) && $0.allSatisfy(\.isLetter) }
    }
}
