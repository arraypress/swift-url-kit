//
//  Fragments.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  Tracking hidden after the `#`. Anchors stay; so do text fragments
//  (`#:~:text=`), which are what the user asked the browser to highlight.
//

import Foundation
import URLCore

enum Fragments {

    /// Share-button suffixes: AddThis's `#.Vh3x.twitter`, ShareThis's `#sthash.abc.dpbs`.
    private static let shareSuffixes: Set<String> = [
        "facebook", "twitter", "email", "linkedin", "gmail", "tumblr", "reddit",
        "pinterest", "whatsapp", "dpuf", "dpbs", "gplus", "google_plus",
    ]

    static func isTracking(_ fragment: String) -> Bool {
        let f = fragment.lowercased()
        if f.isEmpty { return false }
        if f == "_=_" { return true }                                   // Facebook OAuth
        if f.hasPrefix("xtor=") || f.hasPrefix("utm_") || f.hasPrefix("?utm_") { return true }
        if f.hasPrefix("echobox=") || f.hasPrefix("sthash.") { return true }
        if f.hasPrefix(".") {                                           // AddThis: .abc.twitter
            let parts = f.split(separator: ".")
            if parts.count >= 2, let last = parts.last, shareSuffixes.contains(String(last)) { return true }
        }
        return false
    }
}
