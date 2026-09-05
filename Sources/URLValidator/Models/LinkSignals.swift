//
//  LinkSignals.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  What a link looks like before anyone taps it. Offline: judged from the
//  URL text alone, so nothing here can tell you a page is safe — only that a
//  URL has one of the shapes phishing and tracking tend to use.
//

import Foundation
import URLCore

/// Properties of a URL worth knowing before following it.
public struct LinkSignals: Sendable, Codable, Equatable {

    /// The link goes through a URL shortener, so its destination is hidden.
    public let isShortened: Bool
    /// The shortener's name when ``isShortened`` — "Bitly", "TinyURL", "t.co".
    public let shortener: String?
    /// The host is a known tracking-redirect page (Google's `/url`, Outlook
    /// Safe Links, Proofpoint), so the real destination is inside the URL.
    public let isTrackingRedirect: Bool
    /// A query value or path carries another `http(s)://` URL.
    public let embedsURL: Bool

    /// `https://apple.com@evil.example/` — the part before `@` is decoration;
    /// the browser goes to what follows it. A classic phishing shape.
    public let hasUserInfo: Bool
    /// The host is a bare IP address rather than a name.
    public let hostIsIPAddress: Bool
    /// The host is localhost, a private range, `.local` or `.internal`.
    public let isLocalOrPrivate: Bool
    /// The host has an `xn--` label — an internationalised name, which can
    /// look like a familiar brand while being a different one.
    public let hasPunycode: Bool
    /// The host, as typed, mixes scripts (Latin with Cyrillic, say) — the
    /// homograph trick. Only detectable when the original string is Unicode.
    public let hasMixedScripts: Bool
    /// A port other than 80 or 443, when one is given.
    public let nonStandardPort: Int?
    /// `javascript:`, `data:` or `vbscript:` — a "link" that runs code.
    public let schemeIsDangerous: Bool
    /// How many labels precede the registrable domain: `a.b.c.example.com` is 3.
    public let subdomainDepth: Int
    /// The URL is longer than anything a person would type — 512 characters.
    public let isUnusuallyLong: Bool

    /// Human-readable reasons for caution, empty when there are none. Being
    /// shortened or a tracking redirect is NOT a concern by itself — those are
    /// facts to act on, listed separately.
    public let concerns: [String]

    /// Whether ``concerns`` is non-empty.
    public var isSuspicious: Bool { !concerns.isEmpty }

    public init(isShortened: Bool = false, shortener: String? = nil, isTrackingRedirect: Bool = false,
                embedsURL: Bool = false, hasUserInfo: Bool = false, hostIsIPAddress: Bool = false,
                isLocalOrPrivate: Bool = false, hasPunycode: Bool = false, hasMixedScripts: Bool = false,
                nonStandardPort: Int? = nil, schemeIsDangerous: Bool = false, subdomainDepth: Int = 0,
                isUnusuallyLong: Bool = false, concerns: [String] = []) {
        self.isShortened = isShortened
        self.shortener = shortener
        self.isTrackingRedirect = isTrackingRedirect
        self.embedsURL = embedsURL
        self.hasUserInfo = hasUserInfo
        self.hostIsIPAddress = hostIsIPAddress
        self.isLocalOrPrivate = isLocalOrPrivate
        self.hasPunycode = hasPunycode
        self.hasMixedScripts = hasMixedScripts
        self.nonStandardPort = nonStandardPort
        self.schemeIsDangerous = schemeIsDangerous
        self.subdomainDepth = subdomainDepth
        self.isUnusuallyLong = isUnusuallyLong
        self.concerns = concerns
    }

    /// Nothing notable.
    public static let none = LinkSignals()
}
