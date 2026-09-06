//
//  HostPattern.swift
//  URLCore
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Which hosts a rule applies to.
public enum HostPattern: Sendable, Hashable {
    /// The host itself or any subdomain of it: `nytimes.com` matches
    /// `www.nytimes.com` and `cooking.nytimes.com`.
    case suffix(String)
    /// This host only.
    case exact(String)
    /// A brand with any country TLD: `amazon` matches `amazon.com`,
    /// `amazon.co.uk`, `smile.amazon.de` — but not `amazon.example.com` or
    /// `amazonaws.com`.
    case brand(String)
}
