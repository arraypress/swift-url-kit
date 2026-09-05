//
//  String+URLStripper.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  Thin delegates onto the engine, for call sites that already hold a String.
//

import Foundation
import URLCore

public extension String {

    /// The URL with every known tracking parameter, redirect wrapper, path
    /// attribution and share fragment removed.
    var withoutTracking: String { URLStripper.clean(self) }

    /// Only analytics parameters removed — nothing else touched.
    var withoutAnalytics: String { URLStripper.clean(self, options: .only(.analytics)) }
    /// Only social-platform click identifiers removed.
    var withoutSocial: String { URLStripper.clean(self, options: .only(.social)) }
    /// Only email-marketing parameters removed.
    var withoutEmail: String { URLStripper.clean(self, options: .only(.email)) }
    /// Only affiliate and marketplace parameters removed.
    var withoutEcommerce: String { URLStripper.clean(self, options: .only(.ecommerce)) }

    /// Everything `withoutTracking` removes, plus these names.
    func withoutTracking(removing additional: [String]) -> String {
        URLStripper.clean(self, options: CleanOptions(additional: Set(additional)))
    }

    /// Only these names removed; tracking rules are not applied.
    func withoutParams(_ params: [String]) -> String {
        URLStripper.clean(self, options: .onlyParameters(params))
    }

    /// Where a known redirect link really goes, or the string unchanged.
    var unwrappedRedirect: String { URLStripper.unwrap(self) ?? self }

    /// What a full clean would change, and why.
    var cleanReport: CleanReport { URLStripper.report(self) }
}
