//
//  URL+URLStripper.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  The same surface for Foundation's URL.
//

import Foundation
import URLCore

public extension URL {

    /// The URL with every known tracking parameter, redirect wrapper, path
    /// attribution and share fragment removed.
    var withoutTracking: URL { URLStripper.clean(self) }

    /// Only analytics parameters removed — nothing else touched.
    var withoutAnalytics: URL { URLStripper.clean(self, options: .only(.analytics)) }
    /// Only social-platform click identifiers removed.
    var withoutSocial: URL { URLStripper.clean(self, options: .only(.social)) }
    /// Only email-marketing parameters removed.
    var withoutEmail: URL { URLStripper.clean(self, options: .only(.email)) }
    /// Only affiliate and marketplace parameters removed.
    var withoutEcommerce: URL { URLStripper.clean(self, options: .only(.ecommerce)) }

    /// Everything `withoutTracking` removes, plus these names.
    func withoutTracking(removing additional: [String]) -> URL {
        URLStripper.clean(self, options: CleanOptions(additional: Set(additional)))
    }

    /// Only these names removed; tracking rules are not applied.
    func withoutParams(_ params: [String]) -> URL {
        URLStripper.clean(self, options: .onlyParameters(params))
    }

    /// Where a known redirect link really goes, or the URL unchanged.
    var unwrappedRedirect: URL { URLStripper.unwrap(absoluteString).flatMap(URL.init(string:)) ?? self }

    /// What a full clean would change, and why.
    var cleanReport: CleanReport { URLStripper.report(absoluteString) }
}
