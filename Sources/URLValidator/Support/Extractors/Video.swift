//
//  Video.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum VideoExtractor: IDExtractor {

    static let platforms: [Platform] = [
        .youtube, .youtubeMusic, .youtubeShorts, .vimeo, .twitch, .tiktok, .dailymotion,
        .kick, .rumble, .bilibili, .niconico, .douyin, .loom,
    ]

    private static let twitchReserved: Set<String> = ["directory", "videos", "settings", "p", "downloads", "search", "clip", "collections", "events"]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .youtube, .youtubeMusic, .youtubeShorts:
            if p.host == "youtu.be", let id = p.segments.first { ids["youtube_video_id"] = id }
            else if let id = p.segment(after: "shorts") ?? p.segment(after: "live") ?? p.segment(after: "embed") ?? p.segment(after: "v") { ids["youtube_video_id"] = id }
            else if let v = p.query["v"], !v.isEmpty { ids["youtube_video_id"] = v }
            if let list = p.query["list"], !list.isEmpty { ids["youtube_playlist_id"] = list }
            if let t = p.query["t"], !t.isEmpty { ids["youtube_timestamp"] = t }
            if let channel = p.segment(after: "channel") { ids["youtube_channel_id"] = channel }
            if let handle = p.segments.first, handle.hasPrefix("@") { ids["youtube_channel_handle"] = String(handle.dropFirst()) }
            if let user = p.segment(after: "c") ?? p.segment(after: "user") { ids["youtube_channel_handle"] = user }
        case .vimeo:
            if let id = p.firstNumericSegment(minimumDigits: 6) { ids["vimeo_video_id"] = id }
        case .twitch:
            if p.host == "clips.twitch.tv", let id = p.segments.first { ids["twitch_clip_id"] = id }
            else if let id = p.segment(after: "clip") { ids["twitch_clip_id"] = id }
            if let id = p.segment(after: "videos") ?? (p.segments.first == "videos" ? nil : nil), isNumeric(id) { ids["twitch_video_id"] = id }
            if let first = p.segments.first, !twitchReserved.contains(first), p.host == "twitch.tv" || p.host == "m.twitch.tv" {
                ids["twitch_channel"] = first
            }
        case .tiktok:
            if let id = p.segment(after: "video") { ids["tiktok_video_id"] = id.split(separator: "?").first.map(String.init) }
            if let id = p.segment(after: "photo") { ids["tiktok_photo_id"] = id }
            if let user = p.segments.first, user.hasPrefix("@") { ids["tiktok_user"] = String(user.dropFirst()) }
            if let code = p.segment(after: "t") { ids["tiktok_short_code"] = code }
            else if (p.host == "vm.tiktok.com" || p.host == "vt.tiktok.com"), p.segments.count == 1, let code = p.segments.first { ids["tiktok_short_code"] = code }
        case .dailymotion:
            if p.host == "dai.ly", let id = p.segments.first { ids["dailymotion_video_id"] = id }
            else if let id = p.segment(after: "video") { ids["dailymotion_video_id"] = id.split(separator: "_").first.map(String.init) }
        case .kick:
            if let channel = p.segments.first, channel != "video", channel != "category" { ids["kick_channel"] = channel }
            if let id = p.segment(after: "video") { ids["kick_video_id"] = id }
        case .rumble:
            if let last = p.lastSegmentStem, last.hasPrefix("v"), let dash = last.firstIndex(of: "-") {
                ids["rumble_video_id"] = String(last[last.index(after: last.startIndex)..<dash])
            }
        case .bilibili:
            if let id = p.segment(after: "video") { ids["bilibili_video_id"] = id }
            else if p.host == "b23.tv", let code = p.segments.first { ids["bilibili_short_code"] = code }
            if let id = p.query["bvid"] { ids["bilibili_video_id"] = id }
        case .niconico:
            if let id = p.segment(after: "watch") ?? (p.host == "nico.ms" ? p.segments.first : nil) { ids["niconico_video_id"] = id }
        case .douyin:
            if let id = p.segment(after: "video") { ids["douyin_video_id"] = id }
            if let id = p.query["modal_id"] { ids["douyin_video_id"] = id }
        case .loom:
            if let id = p.segment(after: "share") ?? p.segment(after: "embed") { ids["loom_video_id"] = id }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }

    private static func isNumeric(_ s: String) -> Bool { Extractors.isNumeric(s) }
}
