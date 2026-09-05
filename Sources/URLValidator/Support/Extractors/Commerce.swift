//
//  Commerce.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum CommerceExtractor: IDExtractor {

    static let platforms: [Platform] = [.amazon, .kindle, .ebay, .etsy, .appStore, .googlePlay, .steam, .aliexpress, .kickstarter, .gofundme, .patreon, .kofi, .gumroad, .eventbrite, .meetup, .polymarket, .coingecko, .etherscan]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .amazon, .kindle:
            if let asin = amazonASIN(p.segments) { ids["amazon_asin"] = asin }
            if p.segments.first == "s", let q = p.query["k"] ?? p.query["keywords"] { ids["amazon_search_query"] = Extractors.formDecoded(q) }
            if let store = p.segment(after: "stores") { ids["amazon_store"] = store }
            if p.host.hasPrefix("read.amazon"), let asin = p.query["asin"] { ids["amazon_asin"] = asin }
        case .ebay:
            if let i = p.segments.firstIndex(of: "itm"), let id = p.segments[(i + 1)...].first(where: { $0.count >= 9 && Extractors.isNumeric($0) }) { ids["ebay_item_id"] = id }
            if let user = p.segment(after: "usr") { ids["ebay_user"] = user }
            if let store = p.segment(after: "str") { ids["ebay_store"] = store }
            if let q = p.query["_nkw"] { ids["ebay_search_query"] = Extractors.formDecoded(q) }
        case .etsy:
            if let id = p.segment(after: "listing"), Extractors.isNumeric(id) { ids["etsy_listing_id"] = id }
            if let shop = p.segment(after: "shop") { ids["etsy_shop"] = shop }
        case .appStore:
            if let seg = p.segments.first(where: { $0.hasPrefix("id") && Extractors.isNumeric(String($0.dropFirst(2))) }) { ids["app_store_id"] = String(seg.dropFirst(2)) }
            if let dev = p.segments.firstIndex(of: "developer"), dev + 2 < p.segments.count, p.segments[dev + 2].hasPrefix("id") { ids["app_store_developer_id"] = String(p.segments[dev + 2].dropFirst(2)) }
            if let storefront = p.segments.first, storefront.count == 2 { ids["apple_storefront"] = storefront }
        case .googlePlay:
            if let pkg = p.query["id"] { ids["google_play_package"] = pkg }
            if let dev = p.query["id"], p.segments.contains("dev") { ids["google_play_developer_id"] = dev; ids["google_play_package"] = nil }
        case .steam:
            if let id = p.segment(after: "app"), Extractors.isNumeric(id) { ids["steam_app_id"] = id }
            if let id = p.segment(after: "sub"), Extractors.isNumeric(id) { ids["steam_package_id"] = id }
            if let v = p.segment(after: "id") { ids["steam_vanity_id"] = v }
            if let id = p.segment(after: "profiles") { ids["steam_profile_id"] = id }
            if let id = p.segment(after: "sharedfiles") ?? p.query["id"], p.host.hasSuffix("steamcommunity.com"), p.path.contains("filedetails") { ids["steam_workshop_id"] = id }
        case .aliexpress:
            if let item = p.segment(after: "item"), let d = Extractors.leadingDigits(item) { ids["aliexpress_item_id"] = d }
            if let store = p.segment(after: "store"), let d = Extractors.leadingDigits(store) { ids["aliexpress_store_id"] = d }
        case .kickstarter:
            if let i = p.segments.firstIndex(of: "projects"), i + 2 < p.segments.count { ids["kickstarter_creator"] = p.segments[i + 1]; ids["kickstarter_project"] = p.segments[i + 2] }
        case .gofundme:
            if let slug = p.segment(after: "f") { ids["gofundme_campaign"] = slug }
        case .patreon:
            if let post = p.segment(after: "posts"), let id = Extractors.afterLastDash(post) ?? (Extractors.isNumeric(post) ? post : nil) { ids["patreon_post_id"] = id }
            if let c = p.segments.first, !["posts", "login", "join", "home", "explore", "settings", "c", "cw", "user"].contains(c) { ids["patreon_creator"] = c }
            if let c = p.segment(after: "c") ?? p.segment(after: "cw") { ids["patreon_creator"] = c }
        case .kofi:
            if let user = p.segments.first, !["s", "post", "shop", "settings", "manage"].contains(user) { ids["kofi_user"] = user }
        case .gumroad:
            if p.rawHost.hasSuffix(".gumroad.com"), p.rawHost != "www.gumroad.com", p.rawHost != "app.gumroad.com" { ids["gumroad_creator"] = String(p.rawHost.dropLast(".gumroad.com".count)) }
            if let product = p.segment(after: "l") { ids["gumroad_product"] = product }
        case .eventbrite:
            if let slug = p.segment(after: "e"), let id = Extractors.afterLastDash(slug), Extractors.isNumeric(id) { ids["eventbrite_event_id"] = id }
            else if let slug = p.segment(after: "e"), Extractors.isNumeric(slug) { ids["eventbrite_event_id"] = slug }
            if let org = p.segment(after: "o"), let id = Extractors.afterLastDash(org) { ids["eventbrite_organizer_id"] = id }
        case .meetup:
            if p.segments.count >= 3, p.segments[1] == "events" { ids["meetup_group"] = p.segments[0]; ids["meetup_event_id"] = p.segments[2] }
            else if let group = p.segments.first, !["find", "login", "register", "topics", "cities", "pro"].contains(group) { ids["meetup_group"] = group }
        case .polymarket:
            if let slug = p.segment(after: "event") { ids["polymarket_event_slug"] = slug }
            if let slug = p.segment(after: "market") { ids["polymarket_market_slug"] = slug }
        case .coingecko:
            if let coin = p.segment(after: "coins") { ids["coingecko_coin_id"] = coin }
        case .etherscan:
            if let tx = p.segment(after: "tx") { ids["ethereum_tx"] = tx }
            if let address = p.segment(after: "address") { ids["ethereum_address"] = address }
            if let token = p.segment(after: "token") { ids["ethereum_token"] = token }
            if let block = p.segment(after: "block") { ids["ethereum_block"] = block }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }

    /// `/dp/X`, `/gp/product/X`, `/gp/aw/d/X`, `/exec/obidos/ASIN/X`, `/Title/dp/X`.
    static func amazonASIN(_ segments: [String]) -> String? {
        func isASIN(_ s: String) -> Bool { s.count == 10 && s.allSatisfy { ($0.isLetter && $0.isUppercase) || $0.isNumber } }
        for (i, s) in segments.enumerated() where i + 1 < segments.count {
            let next = segments[i + 1]
            if ["dp", "ASIN", "d"].contains(s), isASIN(next) { return next }
            if s == "product", i > 0, segments[i - 1] == "gp", isASIN(next) { return next }
        }
        return nil
    }
}
