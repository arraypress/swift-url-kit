//
//  TrackingCategory.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  What kind of tracking a parameter is. Callers strip by category.
//

import Foundation
import URLCore

/// The family a tracking parameter belongs to.
///
/// Categories exist so a caller can strip selectively — analytics but not
/// affiliate tags, say. `URLStripper.clean` removes every category by default.
public enum TrackingCategory: String, CaseIterable, Sendable, Codable, Hashable {
    /// Campaign and click attribution: `utm_*`, `gclid`, `msclkid`, Matomo, Adobe.
    case analytics
    /// Social platforms' click identifiers: `fbclid`, `igshid`, `twclid`, `ttclid`.
    case social
    /// Email and marketing-automation platforms: Mailchimp, HubSpot, Klaviyo, Salesforce.
    case email
    /// Affiliate networks and marketplaces: Amazon, eBay, Awin, Impact, Rakuten.
    case ecommerce
    /// Everything else — publishers' share tokens, search engines' session state, CDNs.
    case other

    /// Every category. The default for a full clean.
    public static let all: Set<TrackingCategory> = Set(allCases)
}
