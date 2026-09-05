//
//  Signals.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  Computes LinkSignals from a parsed URL and the string it came from.
//

import Foundation
import URLCore

enum Signals {

    static let dangerousSchemes: Set<String> = ["javascript", "data", "vbscript"]

    static func compute(for parts: URLParts, original: String) -> LinkSignals {
        var concerns: [String] = []

        let shortener = Shorteners.service(for: parts.host)
        let isRedirect = URLComponents(url: parts.url, resolvingAgainstBaseURL: false).map(Redirects.isTrackingRedirect) ?? false

        let userInfo = parts.user != nil && !(parts.user ?? "").isEmpty
        if userInfo { concerns.append("has credentials before @ — the real host is \(parts.host)") }

        let ip = isIPAddress(parts.rawHost)
        if ip { concerns.append("host is a bare IP address") }

        let local = isLocalOrPrivate(parts.rawHost)

        let punycode = parts.rawHost.split(separator: ".").contains { $0.hasPrefix("xn--") }
        if punycode { concerns.append("internationalised host (xn--) — check it is the brand you expect") }

        let mixed = hasMixedScripts(hostAsTyped(from: original))
        if mixed { concerns.append("host mixes alphabets — possible look-alike domain") }

        var port: Int? = nil
        if let p = parts.port, p != 80, p != 443 {
            port = p
            concerns.append("non-standard port \(p)")
        }

        let dangerous = dangerousSchemes.contains(parts.scheme ?? "")
        if dangerous { concerns.append("\(parts.scheme ?? "")-scheme link runs code rather than opening a page") }

        let embeds = parts.query.values.contains { $0.lowercased().hasPrefix("http") } || parts.path.lowercased().contains("http")
        let depth = max(0, parts.host.split(separator: ".").count - registrableLabelCount(parts.host))
        if depth >= 4 { concerns.append("\(depth) subdomain levels deep") }

        let long = original.count > 512
        if long { concerns.append("unusually long (\(original.count) characters)") }

        return LinkSignals(
            isShortened: shortener != nil, shortener: shortener, isTrackingRedirect: isRedirect,
            embedsURL: embeds, hasUserInfo: userInfo, hostIsIPAddress: ip, isLocalOrPrivate: local,
            hasPunycode: punycode, hasMixedScripts: mixed, nonStandardPort: port,
            schemeIsDangerous: dangerous, subdomainDepth: depth, isUnusuallyLong: long, concerns: concerns)
    }

    /// Signals for a string that did not parse as a URL with a host — only
    /// the scheme can be judged.
    static func schemeOnly(_ original: String) -> LinkSignals {
        let scheme = original.split(separator: ":", maxSplits: 1).first.map { String($0).lowercased() } ?? ""
        let dangerous = dangerousSchemes.contains(scheme)
        return LinkSignals(schemeIsDangerous: dangerous,
                           concerns: dangerous ? ["\(scheme)-scheme link runs code rather than opening a page"] : [])
    }

    static func isIPAddress(_ host: String) -> Bool {
        let h = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let quads = h.split(separator: ".", omittingEmptySubsequences: false)
        if quads.count == 4, quads.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) && (Int($0) ?? 256) <= 255 }) { return true }
        return h.contains(":") && h.allSatisfy { $0.isHexDigit || $0 == ":" || $0 == "." }
    }

    static func isLocalOrPrivate(_ host: String) -> Bool {
        let h = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if h == "localhost" || h.hasSuffix(".localhost") || h.hasSuffix(".local") || h.hasSuffix(".internal") || h.hasSuffix(".home.arpa") { return true }
        if h == "::1" || h.hasPrefix("fd") && h.contains(":") || h.hasPrefix("fe80:") { return true }
        let q = h.split(separator: ".").compactMap { Int($0) }
        guard q.count == 4 else { return false }
        if q[0] == 127 || q[0] == 10 || q[0] == 0 { return true }
        if q[0] == 192 && q[1] == 168 { return true }
        if q[0] == 172 && (16...31).contains(q[1]) { return true }
        if q[0] == 169 && q[1] == 254 { return true }
        return false
    }

    /// The host as the user typed it, before Foundation encoded it — the only
    /// place a Cyrillic `а` next to a Latin `a` is still visible.
    static func hostAsTyped(from original: String) -> String {
        var s = original.trimmingCharacters(in: .whitespacesAndNewlines)
        if let r = s.range(of: "://") { s = String(s[r.upperBound...]) }
        if let at = s.firstIndex(of: "@"), let slash = s.firstIndex(of: "/"), at < slash { s = String(s[s.index(after: at)...]) }
        else if let at = s.firstIndex(of: "@"), !s.contains("/") { s = String(s[s.index(after: at)...]) }
        if let end = s.firstIndex(where: { $0 == "/" || $0 == "?" || $0 == "#" || $0 == ":" }) { s = String(s[..<end]) }
        return s
    }

    /// Latin letters mixed with letters from another script in one label.
    static func hasMixedScripts(_ host: String) -> Bool {
        for label in host.split(separator: ".") {
            var latin = false, other = false
            for scalar in label.unicodeScalars where scalar.properties.isAlphabetic {
                if scalar.isASCII { latin = true }
                else if (0x0400...0x04FF).contains(scalar.value) || (0x0370...0x03FF).contains(scalar.value)
                            || (0x0530...0x058F).contains(scalar.value) { other = true }   // Cyrillic, Greek, Armenian: the confusable scripts
            }
            if latin && other { return true }
        }
        return false
    }

    /// 2 for `example.com`, 3 for `example.co.uk`-style hosts.
    static func registrableLabelCount(_ host: String) -> Int {
        let labels = host.split(separator: ".").map(String.init)
        guard labels.count >= 3 else { return labels.count }
        let secondLevel: Set<String> = ["co", "com", "org", "net", "gov", "edu", "ac", "or", "ne", "go", "in"]
        let tld = labels[labels.count - 1], sld = labels[labels.count - 2]
        return (tld.count == 2 && secondLevel.contains(sld)) ? 3 : 2
    }
}
