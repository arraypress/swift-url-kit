//
//  Images.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum ImageExtractor: IDExtractor {

    static let platforms: [Platform] = [.imgur, .giphy, .unsplash, .flickr, .pexels, .pixabay, .deviantart, .artstation, .pixiv, .tenor, .behance, .dribbble]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .imgur:
            if let a = p.segment(after: "a") { ids["imgur_album_id"] = a }
            else if let g = p.segment(after: "gallery") { ids["imgur_gallery_id"] = g }
            else if let stem = p.lastSegmentStem, p.segments.count == 1 { ids["imgur_image_id"] = stem }
        case .giphy:
            if p.host == "gph.is", let code = p.segments.first { ids["giphy_short_code"] = code }
            if let slug = p.segment(after: "gifs"), let id = Extractors.afterLastDash(slug) ?? slug as String? { ids["giphy_gif_id"] = id }
            if let id = p.segment(after: "media") { ids["giphy_gif_id"] = id }
        case .unsplash:
            if let slug = p.segment(after: "photos") {
                let id = Extractors.afterLastDash(slug) ?? slug
                ids["unsplash_photo_id"] = id.count == 11 ? id : slug
            }
            if let user = p.segments.first, user.hasPrefix("@") { ids["unsplash_user"] = String(user.dropFirst()) }
            if let c = p.segment(after: "collections") { ids["unsplash_collection_id"] = c }
        case .flickr:
            if p.host == "flic.kr", let code = p.segment(after: "p") { ids["flickr_short_code"] = code }
            if let i = p.segments.firstIndex(of: "photos"), i + 1 < p.segments.count {
                ids["flickr_user"] = p.segments[i + 1]
                if i + 2 < p.segments.count, Extractors.isNumeric(p.segments[i + 2]) { ids["flickr_photo_id"] = p.segments[i + 2] }
                if let album = p.segment(after: "albums") { ids["flickr_album_id"] = album }
            }
        case .pexels:
            if let slug = p.segment(after: "photo"), let id = Extractors.afterLastDash(slug) ?? Extractors.leadingDigits(slug) { ids["pexels_photo_id"] = id }
            if let slug = p.segment(after: "video"), let id = Extractors.afterLastDash(slug) { ids["pexels_video_id"] = id }
        case .pixabay:
            for kind in ["photos", "videos", "illustrations", "vectors"] {
                if let slug = p.segment(after: kind), let id = Extractors.afterLastDash(slug) { ids["pixabay_id"] = id }
            }
        case .deviantart:
            if let slug = p.segment(after: "art"), let id = Extractors.afterLastDash(slug) { ids["deviantart_id"] = id }
            if let user = p.segments.first, !["art", "tag", "search", "daily-deviations", "join", "users"].contains(user) { ids["deviantart_user"] = user }
        case .artstation:
            if let id = p.segment(after: "artwork") { ids["artstation_artwork_id"] = id }
            else if let user = p.segments.first, !["search", "marketplace", "learning", "jobs", "blogs", "challenges"].contains(user) { ids["artstation_user"] = user }
        case .pixiv:
            if let id = p.segment(after: "artworks") { ids["pixiv_artwork_id"] = id }
            if let id = p.segment(after: "users") { ids["pixiv_user_id"] = id }
            if let id = p.query["illust_id"] { ids["pixiv_artwork_id"] = id }
        case .tenor:
            if let slug = p.segment(after: "view"), let id = Extractors.afterLastDash(slug) { ids["tenor_gif_id"] = id }
        case .behance:
            if let i = p.segments.firstIndex(of: "gallery"), i + 1 < p.segments.count { ids["behance_project_id"] = p.segments[i + 1] }
            else if let user = p.segments.first, !["search", "galleries", "joblist", "live", "assets"].contains(user) { ids["behance_user"] = user }
        case .dribbble:
            if let slug = p.segment(after: "shots"), let id = Extractors.leadingDigits(slug) { ids["dribbble_shot_id"] = id }
            else if let user = p.segments.first, !["shots", "search", "designers", "jobs", "tags", "stories"].contains(user) { ids["dribbble_user"] = user }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }
}
