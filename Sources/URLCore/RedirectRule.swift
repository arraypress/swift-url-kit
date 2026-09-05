//
//  RedirectRule.swift
//  URLCore
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A redirect page that carries its real destination in the URL.
///
/// Unwrapping is done offline from the URL alone; nothing here follows a link.
public struct RedirectRule: Sendable {
    /// Where the destination is.
    public enum Source: Sendable {
        /// A query parameter, tried in order: Google uses `url` or `q`.
        case query([String])
        /// The rest of the path after a prefix, e.g. Google AMP's
        /// `/amp/s/example.com/page` → `https://example.com/page`.
        case pathAfter(String)
        /// Proofpoint's v3 format: the URL sits between `__` and `__;`.
        case proofpointV3
    }

    /// How the destination is encoded.
    public enum Encoding: Sendable {
        /// Ordinary percent-encoding, or none.
        case percent
        /// Bing: `a1` followed by base64url of the URL.
        case bingBase64
        /// Proofpoint v2: `_` for `/`, `-XX` for `%XX`.
        case proofpointV2
        /// A bare `host/path` with no scheme, as AMP caches write them.
        case schemeless
    }

    public let hosts: [HostPattern]
    /// Only unwrap when the path starts with this. `nil` means any path.
    public let pathPrefix: String?
    public let source: Source
    public let encoding: Encoding
    /// Shown in a report — "Google", "Outlook Safe Links".
    public let label: String

    public init(hosts: [HostPattern], pathPrefix: String? = nil, source: Source,
                encoding: Encoding = .percent, label: String) {
        self.hosts = hosts
        self.pathPrefix = pathPrefix
        self.source = source
        self.encoding = encoding
        self.label = label
    }
}

