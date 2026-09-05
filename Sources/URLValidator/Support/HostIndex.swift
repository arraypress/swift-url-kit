//
//  HostIndex.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  Host → platform, deterministically. The first version iterated a
//  dictionary of platform → domains, so two platforms sharing a suffix could
//  win on different runs, and used `contains` for custom subdomains, so
//  `notbandcamp.com` was Bandcamp. This is an exact-host dictionary walked
//  from the full host towards the registrable domain: the most specific
//  entry wins, every time, in O(labels).
//

import Foundation
import URLCore

enum HostIndex {

    /// Exact hosts (no wildcard) → platform.
    private static let exact: [String: Platform] = {
        var index: [String: Platform] = [:]
        for entry in PlatformDomains.table {
            for host in entry.hosts where !host.contains("*") {
                index[host] = entry.platform      // later duplicates lose; the table has none
            }
        }
        for (host, platform) in PlatformDomains.shortHostOverrides { index[host] = platform }
        return index
    }()

    /// Brand-with-any-TLD patterns: ("amazon", nil) for `amazon.*`,
    /// ("amazon", "music") for `music.amazon.*`.
    private static let brands: [(brand: String, subdomain: String?, platform: Platform)] = {
        var out: [(String, String?, Platform)] = []
        for entry in PlatformDomains.table {
            for host in entry.hosts where host.hasSuffix(".*") {
                let stem = String(host.dropLast(2))
                if let dot = stem.firstIndex(of: ".") {
                    out.append((String(stem[stem.index(after: dot)...]), String(stem[..<dot]), entry.platform))
                } else {
                    out.append((stem, nil, entry.platform))
                }
            }
        }
        // Subdomain-qualified brands must be tried before bare brands.
        return out.sorted { ($0.1 != nil ? 0 : 1) < ($1.1 != nil ? 0 : 1) }
    }()

    /// The platform for a normalised host (lowercased, no `www.`), before path overrides.
    static func platform(forHost host: String) -> Platform {
        // Walk from the full host towards the last two labels.
        var labels = host.split(separator: ".").map(String.init)
        while labels.count >= 2 {
            if let hit = exact[labels.joined(separator: ".")] { return hit }
            labels.removeFirst()
        }
        // Brands with any country TLD.
        let all = host.split(separator: ".").map(String.init)
        for (brand, subdomain, platform) in brands {
            guard let i = all.firstIndex(of: brand), HostMatcher.isTLDTail(all[(i + 1)...]) else { continue }
            if let subdomain {
                guard i > 0, all[i - 1] == subdomain else { continue }
            }
            return platform
        }
        return .unknown
    }

    /// The platform for a parsed URL, path overrides applied.
    static func platform(for parts: URLParts) -> Platform {
        let base = platform(forHost: parts.host)
        guard base != .unknown else { return .unknown }
        let head = Set(parts.segments.prefix(2).map { $0.lowercased() })
        for override in PlatformDomains.pathOverrides where override.platform == base {
            if !override.segments.isDisjoint(with: head) { return override.becomes }
        }
        return base
    }
}
