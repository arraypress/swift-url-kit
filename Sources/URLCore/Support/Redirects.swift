//
//  Redirects.swift
//  URLCore
//
//  Created by David Sherlock on 2026.
//
//  Redirect pages whose real destination is in the URL itself, and how to
//  read it out. Offline: nothing here fetches anything. Shorteners such as
//  t.co or bit.ly carry nothing in the URL and are NOT unwrapped here.
//

import Foundation

/// The redirect wrappers this kit can peel, and the peeling itself.
public enum Redirects {

    /// Every wrapper that carries its destination in the URL. Order matters
    /// only in that the first match wins; the patterns do not overlap.
    public static let rules: [RedirectRule] = [
        // Search engines and mail clients — where most pasted redirects come from
        RedirectRule(hosts: [.brand("google")], pathPrefix: "/url",
                     source: .query(["url", "q"]), label: "Google"),
        RedirectRule(hosts: [.brand("google")], pathPrefix: "/amp/s/",
                     source: .pathAfter("/amp/s/"), encoding: .schemeless, label: "Google AMP"),
        RedirectRule(hosts: [.suffix("googleadservices.com"), .brand("doubleclick")],
                     source: .query(["adurl"]), label: "Google Ads"),
        RedirectRule(hosts: [.brand("bing")], pathPrefix: "/ck/a",
                     source: .query(["u"]), encoding: .bingBase64, label: "Bing"),
        RedirectRule(hosts: [.suffix("duckduckgo.com")], pathPrefix: "/l/",
                     source: .query(["uddg"]), label: "DuckDuckGo"),
        RedirectRule(hosts: [.suffix("safelinks.protection.outlook.com")],
                     source: .query(["url"]), label: "Outlook Safe Links"),
        RedirectRule(hosts: [.suffix("urldefense.proofpoint.com")], pathPrefix: "/v2/url",
                     source: .query(["u"]), encoding: .proofpointV2, label: "Proofpoint"),
        RedirectRule(hosts: [.suffix("urldefense.com")], pathPrefix: "/v3/",
                     source: .proofpointV3, label: "Proofpoint"),
        RedirectRule(hosts: [.exact("slack-redir.net")], pathPrefix: "/link",
                     source: .query(["url"]), label: "Slack"),

        // Social
        RedirectRule(hosts: [.exact("l.facebook.com"), .exact("lm.facebook.com"), .exact("l.messenger.com")],
                     pathPrefix: "/l.php", source: .query(["u"]), label: "Facebook"),
        RedirectRule(hosts: [.exact("l.instagram.com")], source: .query(["u"]), label: "Instagram"),
        RedirectRule(hosts: [.exact("l.threads.net"), .exact("l.threads.com")], source: .query(["u"]), label: "Threads"),
        RedirectRule(hosts: [.suffix("youtube.com")], pathPrefix: "/redirect",
                     source: .query(["q"]), label: "YouTube"),
        RedirectRule(hosts: [.exact("out.reddit.com"), .exact("click.redditmail.com")],
                     source: .query(["url"]), label: "Reddit"),
        RedirectRule(hosts: [.suffix("linkedin.com")], pathPrefix: "/redir/redirect",
                     source: .query(["url"]), label: "LinkedIn"),
        RedirectRule(hosts: [.exact("t.umblr.com")], pathPrefix: "/redirect",
                     source: .query(["z"]), label: "Tumblr"),
        RedirectRule(hosts: [.exact("vk.com")], pathPrefix: "/away.php",
                     source: .query(["to"]), label: "VK"),
        RedirectRule(hosts: [.exact("disq.us")], source: .query(["url"]), label: "Disqus"),
        RedirectRule(hosts: [.suffix("deviantart.com")], pathPrefix: "/users/outgoing",
                     source: .query(["url"]), label: "DeviantArt"),

        // Gaming, shopping, misc
        RedirectRule(hosts: [.suffix("steamcommunity.com")], pathPrefix: "/linkfilter/",
                     source: .query(["url", "u"]), label: "Steam"),
        RedirectRule(hosts: [.suffix("curseforge.com")], pathPrefix: "/linkout",
                     source: .query(["remoteUrl"]), label: "CurseForge"),
        RedirectRule(hosts: [.brand("ebay")], pathPrefix: "/rover/",
                     source: .query(["mpre"]), label: "eBay"),
        RedirectRule(hosts: [.suffix("linksynergy.com")], source: .query(["murl"]), label: "Rakuten"),
        RedirectRule(hosts: [.suffix("anonym.to"), .exact("href.li")],
                     source: .query(["url", ""]), label: "Anonymiser"),
        RedirectRule(hosts: [.suffix("cdn.ampproject.org")], pathPrefix: "/c/s/",
                     source: .pathAfter("/c/s/"), encoding: .schemeless, label: "AMP cache"),
        RedirectRule(hosts: [.suffix("cdn.ampproject.org")], pathPrefix: "/v/s/",
                     source: .pathAfter("/v/s/"), encoding: .schemeless, label: "AMP cache"),
    ]

    /// The rule whose host and path match, regardless of whether a destination
    /// can be read out — for flagging a link as a tracking redirect.
    public static func rule(matching components: URLComponents) -> RedirectRule? {
        guard let host = HostMatcher.normalise(components.host) else { return nil }
        let path = components.path
        return rules.first { rule in
            HostMatcher.matches(host, any: rule.hosts) && (rule.pathPrefix.map { path.hasPrefix($0) } ?? true)
        }
    }

    /// Redirect hosts whose destination is NOT in the URL (Mailchimp, SendGrid,
    /// Mandrill click tracking): recognisable, not unwrappable.
    public static let opaqueTrackingHosts: [HostPattern] = [
        .suffix("click.mailchimp.com"), .suffix("mandrillapp.com"), .suffix("sendgrid.net"),
        .suffix("links.govdelivery.com"), .suffix("awstrack.me"), .suffix("mailtrack.io"),
        .suffix("list-manage.com"), .suffix("clicks.beehiiv.com"), .suffix("email.mg.substack.com"),
        .suffix("t.sidekickopen"), .suffix("hubspotlinks.com"), .suffix("mailchi.mp"),
    ]

    /// Whether a URL is any kind of tracking redirect, unwrappable or not.
    public static func isTrackingRedirect(_ components: URLComponents) -> Bool {
        if rule(matching: components) != nil { return true }
        guard let host = HostMatcher.normalise(components.host) else { return false }
        return HostMatcher.matches(host, any: opaqueTrackingHosts)
    }

    /// The destination carried by a redirect URL, and which service it was.
    public static func unwrap(_ components: URLComponents) -> (URLComponents, label: String)? {
        guard let host = HostMatcher.normalise(components.host) else { return nil }
        let path = components.path
        for rule in rules where HostMatcher.matches(host, any: rule.hosts) {
            if let prefix = rule.pathPrefix, !path.hasPrefix(prefix) { continue }
            guard let raw = extract(rule.source, from: components),
                  let decoded = decode(raw, as: rule.encoding),
                  let target = URLComponents(string: decoded),
                  let scheme = target.scheme?.lowercased(), scheme == "http" || scheme == "https",
                  let targetHost = target.host, !targetHost.isEmpty
            else { continue }
            return (target, rule.label)
        }
        return nil
    }

    private static func extract(_ source: RedirectRule.Source, from components: URLComponents) -> String? {
        switch source {
        case .query(let names):
            let items = components.queryItems ?? []
            for name in names {
                if name.isEmpty {
                    // `href.li/?https://example.com` — the whole query IS the URL.
                    if let q = components.query, q.hasPrefix("http") { return q }
                    continue
                }
                if let value = items.first(where: { $0.name == name })?.value, !value.isEmpty {
                    return value
                }
            }
            return nil
        case .pathAfter(let prefix):
            guard components.path.hasPrefix(prefix) else { return nil }
            var rest = String(components.path.dropFirst(prefix.count))
            if let q = components.query, !q.isEmpty { rest += "?" + q }
            return rest.isEmpty ? nil : rest
        case .proofpointV3:
            // /v3/__https://example.com/path__;!!Hash$
            let path = components.path
            guard let open = path.range(of: "__"),
                  let close = path.range(of: "__;", range: open.upperBound..<path.endIndex)
            else { return nil }
            return String(path[open.upperBound..<close.lowerBound])
        }
    }

    private static func decode(_ raw: String, as encoding: RedirectRule.Encoding) -> String? {
        switch encoding {
        case .percent:
            // URLComponents has decoded the value once already. Google sometimes
            // double-encodes; a second pass on a non-URL is harmless.
            return raw.hasPrefix("http") ? raw : raw.removingPercentEncoding
        case .schemeless:
            let stripped = raw.hasPrefix("/") ? String(raw.dropFirst()) : raw
            return stripped.isEmpty ? nil : "https://" + stripped
        case .bingBase64:
            // Bing prefixes the base64url payload with "a1".
            guard raw.hasPrefix("a1") else { return nil }
            var b64 = String(raw.dropFirst(2))
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            while b64.count % 4 != 0 { b64 += "=" }
            guard let data = Data(base64Encoded: b64) else { return nil }
            return String(data: data, encoding: .utf8)
        case .proofpointV2:
            // `_` stands for `/`; `-XX` stands for `%XX`.
            var out = ""
            var i = raw.startIndex
            while i < raw.endIndex {
                let c = raw[i]
                if c == "_" {
                    out.append("/")
                } else if c == "-",
                          let end = raw.index(i, offsetBy: 3, limitedBy: raw.endIndex),
                          raw[raw.index(after: i)..<end].allSatisfy(\.isHexDigit) {
                    out.append("%")
                    out.append(contentsOf: raw[raw.index(after: i)..<end])
                    i = end
                    continue
                } else {
                    out.append(c)
                }
                i = raw.index(after: i)
            }
            return out.removingPercentEncoding ?? out
        }
    }
}
