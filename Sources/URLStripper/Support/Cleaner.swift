//
//  Cleaner.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  The engine. Pure: string in, report out, no state.
//

import Foundation
import URLCore

enum Cleaner {

    /// How many nested redirects to peel — a Gmail link to a Safe Link to a page is three hops.
    static let maximumUnwraps = 3

    static func clean(_ input: String, options: CleanOptions) -> CleanReport {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return CleanReport(original: input, cleaned: input) }
        // A URL cannot contain whitespace. Modern Foundation would accept the
        // string anyway and percent-encode the spaces — rewriting text that was
        // never a URL. Such strings get the byte-preserving fallback instead.
        guard !trimmed.contains(where: \.isWhitespace),
              var components = URLComponents(string: trimmed) else {
            return fallback(input, trimmed, options: options)
        }

        // 1. Redirects, outermost first.
        var unwrapped: [String] = []
        if options.unwrapRedirects {
            while unwrapped.count < maximumUnwraps, let (target, label) = Redirects.unwrap(components) {
                components = target
                unwrapped.append(label)
            }
        }

        let host = HostMatcher.normalise(components.host)
        let rules = host.map(HostRules.matching) ?? []

        // 2. Query. Work on the percent-encoded items so kept parameters come
        //    back byte-for-byte — `+` stays `+`, `%20` stays `%20`.
        var removed: [RemovedParameter] = []
        if let items = components.percentEncodedQueryItems {
            let kept = items.filter { item in
                let name = (item.name.removingPercentEncoding ?? item.name).lowercased()
                if options.preserve.contains(name) { return true }
                if options.additional.contains(name) {
                    removed.append(RemovedParameter(name: name, category: nil, scope: "custom"))
                    return false
                }
                if let category = GlobalParameters.category(of: name), options.categories.contains(category) {
                    removed.append(RemovedParameter(name: name, category: category, scope: "global"))
                    return false
                }
                if let rule = HostRules.rule(removing: name, among: rules), options.categories.contains(rule.category) {
                    removed.append(RemovedParameter(name: name, category: rule.category, scope: rule.label))
                    return false
                }
                return true
            }
            components.percentEncodedQueryItems = kept.isEmpty ? nil : kept
        } else if components.query != nil {
            components.query = nil   // a bare trailing "?"
        }

        // 3. Path.
        var pathChanges: [String] = []
        if options.cleanPath, let host {
            let (path, changes) = Paths.clean(components.path, host: host)
            if !changes.isEmpty {
                components.path = path
                pathChanges = changes
            }
        }

        // 4. Fragment.
        var fragmentRemoved = false
        if options.stripFragmentTracking, let fragment = components.fragment, Fragments.isTracking(fragment) {
            components.fragment = nil
            fragmentRemoved = true
        }

        return CleanReport(original: input, cleaned: components.string ?? trimmed, removed: removed,
                           unwrapped: unwrapped, pathChanges: pathChanges, fragmentRemoved: fragmentRemoved)
    }

    /// Only the redirect step — the destination a link really points at.
    static func unwrap(_ input: String) -> (String, [String])? {
        guard var components = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        var labels: [String] = []
        while labels.count < maximumUnwraps, let (target, label) = Redirects.unwrap(components) {
            components = target
            labels.append(label)
        }
        guard !labels.isEmpty, let out = components.string else { return nil }
        return (out, labels)
    }

    /// For strings `URLComponents` refuses (spaces, stray characters): split on
    /// `?` and `&` by hand and apply the host-independent rules only.
    private static func fallback(_ original: String, _ s: String, options: CleanOptions) -> CleanReport {
        guard let q = s.firstIndex(of: "?") else { return CleanReport(original: original, cleaned: original) }
        let base = String(s[..<q])
        var rest = String(s[s.index(after: q)...])
        var fragment = ""
        if let h = rest.firstIndex(of: "#") { fragment = String(rest[h...]); rest = String(rest[..<h]) }

        var removed: [RemovedParameter] = []
        let kept = rest.split(separator: "&", omittingEmptySubsequences: false).filter { pair in
            let name = String(pair.split(separator: "=", maxSplits: 1).first ?? pair).lowercased()
            if options.preserve.contains(name) { return true }
            if options.additional.contains(name) {
                removed.append(RemovedParameter(name: name, category: nil, scope: "custom")); return false
            }
            if let category = GlobalParameters.category(of: name), options.categories.contains(category) {
                removed.append(RemovedParameter(name: name, category: category, scope: "global")); return false
            }
            return true
        }
        let cleaned = base + (kept.isEmpty ? "" : "?" + kept.joined(separator: "&")) + fragment
        return CleanReport(original: original, cleaned: cleaned, removed: removed)
    }
}
