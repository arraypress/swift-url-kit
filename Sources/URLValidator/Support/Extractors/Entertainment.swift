//
//  Entertainment.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum EntertainmentExtractor: IDExtractor {

    static let platforms: [Platform] = [.imdb, .letterboxd, .tmdb, .rottenTomatoes, .goodreads, .netflix, .primeVideo, .disneyPlus, .max, .hulu, .crunchyroll, .plex, .appleTV, .appleBooks, .audible, .strava]

    private static let letterboxdReserved: Set<String> = ["film", "films", "lists", "members", "journal", "search", "settings", "director", "actor", "list", "sign-in", "create-account"]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .imdb:
            if let t = p.segment(after: "title"), t.hasPrefix("tt") { ids["imdb_id"] = t }
            if let n = p.segment(after: "name"), n.hasPrefix("nm") { ids["imdb_name_id"] = n }
            if let l = p.segment(after: "list"), l.hasPrefix("ls") { ids["imdb_list_id"] = l }
        case .letterboxd:
            if p.host == "boxd.it", let code = p.segments.first { ids["letterboxd_short_code"] = code; break }
            if let film = p.segment(after: "film") { ids["letterboxd_film"] = film }
            if let list = p.segment(after: "list") { ids["letterboxd_list"] = list }
            if let first = p.segments.first, !letterboxdReserved.contains(first) { ids["letterboxd_user"] = first }
        case .tmdb:
            for kind in ["movie", "tv", "person", "collection"] {
                if let seg = p.segment(after: kind), let id = Extractors.leadingDigits(seg) { ids["tmdb_\(kind)_id"] = id }
            }
        case .rottenTomatoes:
            if let m = p.segment(after: "m") { ids["rotten_tomatoes_movie"] = m }
            if let tv = p.segment(after: "tv") { ids["rotten_tomatoes_tv"] = tv }
        case .goodreads:
            if p.segments.count >= 3, p.segments[1] == "show", let id = Extractors.leadingDigits(p.segments[2]) {
                switch p.segments[0] {
                case "book": ids["goodreads_book_id"] = id
                case "author": ids["goodreads_author_id"] = id
                case "user": ids["goodreads_user_id"] = id
                case "series": ids["goodreads_series_id"] = id
                default: break
                }
            }
        case .netflix:
            if let id = p.segment(after: "title") ?? p.segment(after: "watch"), Extractors.isNumeric(id) { ids["netflix_title_id"] = id }
        case .primeVideo:
            if let id = p.segment(after: "detail") { ids["prime_video_id"] = id }
            if let asin = CommerceExtractor.amazonASIN(p.segments) { ids["amazon_asin"] = asin }
        case .disneyPlus:
            if let entity = p.segment(after: "browse"), entity.hasPrefix("entity-") { ids["disney_plus_id"] = String(entity.dropFirst(7)) }
            for kind in ["movies", "series"] {
                if let i = p.segments.firstIndex(of: kind), i + 2 < p.segments.count { ids["disney_plus_id"] = p.segments[i + 2] }
            }
        case .max:
            for kind in ["movie", "show", "episode"] { if let id = p.segment(after: kind) { ids["max_id"] = id } }
        case .hulu:
            for kind in ["movie", "series", "watch"] {
                if let seg = p.segment(after: kind) { ids["hulu_id"] = seg.count > 36 ? String(seg.suffix(36)) : seg }
            }
        case .crunchyroll:
            for kind in ["series", "watch"] { if let id = p.segment(after: kind) { ids["crunchyroll_id"] = id } }
        case .plex:
            if let id = p.segment(after: "watch") ?? p.segment(after: "show") ?? p.segment(after: "movie") { ids["plex_id"] = id }
        case .appleTV:
            if let umc = p.segments.first(where: { $0.hasPrefix("umc.") }) { ids["apple_tv_id"] = umc }
            if let storefront = p.segments.first, storefront.count == 2 { ids["apple_storefront"] = storefront }
        case .appleBooks:
            if let seg = p.segments.first(where: { $0.hasPrefix("id") && Extractors.isNumeric(String($0.dropFirst(2))) }) { ids["apple_books_id"] = String(seg.dropFirst(2)) }
        case .audible:
            if let i = p.segments.firstIndex(of: "pd"), let asin = p.segments[(i + 1)...].first(where: { $0.count == 10 && $0.hasPrefix("B") }) { ids["audible_asin"] = asin }
            else if let asin = p.query["asin"] { ids["audible_asin"] = asin }
        case .strava:
            for (plural, singular) in [("activities", "activity"), ("athletes", "athlete"), ("routes", "route"), ("segments", "segment"), ("clubs", "club")] {
                if let id = p.segment(after: plural) { ids["strava_\(singular)_id"] = id }
            }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }
}
