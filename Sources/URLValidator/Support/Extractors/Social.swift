//
//  Social.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum SocialExtractor: IDExtractor {

    static let platforms: [Platform] = [
        .twitter, .instagram, .instagramReels, .facebook, .linkedin, .reddit, .bluesky, .threads,
        .mastodon, .pinterest, .tumblr, .vk, .weibo, .xiaohongshu, .linktree, .snapchat, .lemmy,
    ]

    private static let twitterReserved: Set<String> = ["home", "explore", "search", "i", "settings", "messages", "notifications", "hashtag", "intent", "share", "login", "signup", "compose", "tos", "privacy", "about"]
    private static let instagramReserved: Set<String> = ["explore", "accounts", "p", "reel", "reels", "tv", "stories", "direct", "about", "developer", "legal"]
    private static let redditReserved: Set<String> = ["r", "u", "user", "comments", "search", "submit", "login", "settings", "message", "gallery", "poll", "live"]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .twitter:
            if let id = p.segment(after: "status"), let digits = Extractors.leadingDigits(id) { ids["tweet_id"] = digits }
            if let first = p.segments.first, !twitterReserved.contains(first), p.host != "t.co" { ids["twitter_user"] = first }
            if let tag = p.segment(after: "hashtag") { ids["twitter_hashtag"] = tag }
            if p.host == "t.co", let code = p.segments.first { ids["twitter_short_code"] = code }
        case .instagram, .instagramReels:
            if let id = p.segment(after: "p") ?? p.segment(after: "reel") ?? p.segment(after: "reels") ?? p.segment(after: "tv") { ids["instagram_post_id"] = id }
            if p.segments.first == "stories", p.segments.count >= 3 {
                ids["instagram_user"] = p.segments[1]; ids["instagram_story_id"] = p.segments[2]
            } else if let first = p.segments.first, !instagramReserved.contains(first), !first.hasPrefix("@") {
                ids["instagram_user"] = first
            }
        case .facebook:
            if p.host == "fb.watch", let code = p.segments.first { ids["facebook_video_short_code"] = code }
            if let id = p.segment(after: "posts") { ids["facebook_post_id"] = id }
            if let id = p.query["v"], p.segments.first == "watch" || p.path.hasPrefix("/watch") { ids["facebook_video_id"] = id }
            if let id = p.segment(after: "videos"), Extractors.isNumeric(id) { ids["facebook_video_id"] = id }
            if let id = p.segment(after: "reel") { ids["facebook_video_id"] = id }
            if let id = p.query["fbid"] { ids["facebook_photo_id"] = id }
            if let id = p.query["story_fbid"] { ids["facebook_post_id"] = id }
            if p.segments.first == "profile.php", let id = p.query["id"] { ids["facebook_profile_id"] = id }
            if p.segments.first == "permalink.php", let id = p.query["id"] { ids["facebook_page_id"] = id }
            if let id = p.segment(after: "groups") { ids["facebook_group"] = id }
            if let id = p.segment(after: "events") { ids["facebook_event_id"] = id }
            if p.segments.first == "share", p.segments.count >= 3 { ids["facebook_share_code"] = p.segments[2] }
            if p.segments.count >= 2, p.segments[1] == "posts" || p.segments[1] == "videos" { ids["facebook_page"] = p.segments[0] }
        case .linkedin:
            if let slug = p.segment(after: "posts"), let r = slug.range(of: "activity-") {
                let digits = slug[r.upperBound...].prefix { $0.isNumber }
                if !digits.isEmpty { ids["linkedin_activity_id"] = String(digits) }
            }
            if let urn = p.segment(after: "update"), let r = urn.range(of: "activity:") {
                let digits = urn[r.upperBound...].prefix { $0.isNumber }
                if !digits.isEmpty { ids["linkedin_activity_id"] = String(digits) }
            }
            if let handle = p.segment(after: "in") { ids["linkedin_handle"] = handle }
            if let company = p.segment(after: "company") { ids["linkedin_company"] = company }
            if let school = p.segment(after: "school") { ids["linkedin_school"] = school }
            if p.segments.first == "jobs", let id = p.segment(after: "view"), let digits = Extractors.leadingDigits(id) { ids["linkedin_job_id"] = digits }
            if let article = p.segment(after: "pulse") { ids["linkedin_article"] = article }
        case .reddit:
            if p.host == "redd.it", let id = p.segments.first { ids["reddit_post_id"] = id }
            if let sub = p.segment(after: "r") { ids["subreddit"] = sub }
            if let id = p.segment(after: "comments") {
                ids["reddit_post_id"] = id
                if let i = p.segments.firstIndex(of: "comments"), i + 3 < p.segments.count { ids["reddit_comment_id"] = p.segments[i + 3] }
            }
            if let code = p.segment(after: "s"), p.segments.first == "r" { ids["reddit_share_id"] = code }
            if let user = p.segment(after: "user") ?? p.segment(after: "u") { ids["reddit_user"] = user }
        case .bluesky:
            if let handle = p.segment(after: "profile") { ids["bluesky_handle"] = handle }
            if let post = p.segment(after: "post") { ids["bluesky_post_id"] = post }
        case .threads:
            if let first = p.segments.first, first.hasPrefix("@") { ids["threads_user"] = String(first.dropFirst()) }
            if let post = p.segment(after: "post") { ids["threads_post_id"] = post }
        case .mastodon:
            if let first = p.segments.first, first.hasPrefix("@") {
                ids["mastodon_user"] = String(first.dropFirst())
                if p.segments.count >= 2, Extractors.isNumeric(p.segments[1]) { ids["mastodon_status_id"] = p.segments[1] }
            }
            if let user = p.segment(after: "users") { ids["mastodon_user"] = user }
            if let status = p.segment(after: "statuses") { ids["mastodon_status_id"] = status }
        case .pinterest:
            if let id = p.segment(after: "pin") { ids["pinterest_pin_id"] = id }
            else if p.host == "pin.it", let code = p.segments.first { ids["pinterest_short_code"] = code }
            else if let user = p.segments.first, !["pin", "search", "ideas", "today", "settings"].contains(user) {
                ids["pinterest_user"] = user
                if p.segments.count >= 2 { ids["pinterest_board"] = p.segments[1] }
            }
        case .tumblr:
            if p.rawHost.hasSuffix(".tumblr.com"), p.rawHost != "www.tumblr.com" {
                ids["tumblr_blog"] = String(p.rawHost.dropLast(".tumblr.com".count))
                if let id = p.segment(after: "post") { ids["tumblr_post_id"] = id }
            } else if p.segments.count >= 2, Extractors.isNumeric(p.segments[1]) {
                ids["tumblr_blog"] = p.segments[0]; ids["tumblr_post_id"] = p.segments[1]
            } else if let blog = p.segments.first { ids["tumblr_blog"] = blog }
        case .vk:
            if let first = p.segments.first {
                if first.hasPrefix("wall") { ids["vk_wall_post"] = String(first.dropFirst(4)) }
                else if first.hasPrefix("id"), Extractors.isNumeric(String(first.dropFirst(2))) { ids["vk_user_id"] = String(first.dropFirst(2)) }
                else if first.hasPrefix("club"), Extractors.isNumeric(String(first.dropFirst(4))) { ids["vk_club_id"] = String(first.dropFirst(4)) }
                else if first != "away.php" { ids["vk_screen_name"] = first }
            }
        case .weibo:
            if p.segments.count >= 2, Extractors.isNumeric(p.segments[0]) { ids["weibo_user_id"] = p.segments[0]; ids["weibo_post_id"] = p.segments[1] }
            else if let user = p.segment(after: "u") { ids["weibo_user_id"] = user }
        case .xiaohongshu:
            if let id = p.segment(after: "explore") ?? p.segment(after: "discovery") { ids["xiaohongshu_note_id"] = id }
            if let user = p.segment(after: "profile") { ids["xiaohongshu_user_id"] = user }
        case .linktree:
            if let user = p.segments.first { ids["linktree_user"] = user }
        case .snapchat:
            if let user = p.segment(after: "add") { ids["snapchat_user"] = user }
        case .lemmy:
            if let community = p.segment(after: "c") { ids["lemmy_community"] = community }
            if let post = p.segment(after: "post") { ids["lemmy_post_id"] = post }
            if let user = p.segment(after: "u") { ids["lemmy_user"] = user }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }
}
