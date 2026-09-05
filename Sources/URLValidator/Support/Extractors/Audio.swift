//
//  Audio.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum AudioExtractor: IDExtractor {

    static let platforms: [Platform] = [.spotify, .soundcloud, .appleMusic, .applePodcasts, .bandcamp, .discogs, .musicbrainz, .shazam, .deezer, .tidal, .mixcloud]

    private static let spotifyTypes: Set<String> = ["track", "album", "playlist", "episode", "show", "artist", "audiobook"]
    private static let soundcloudReserved: Set<String> = ["discover", "search", "stream", "you", "upload", "charts", "tags", "settings", "pages", "terms-of-use", "people", "tracks", "playlists"]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .spotify:
            let segs = p.segments
            if segs.count >= 2 {
                let type = segs[segs.count - 2], id = segs[segs.count - 1]
                if spotifyTypes.contains(type) { ids["spotify_\(type)_id"] = id }
            }
            if let user = p.segment(after: "user"), segs.count == 2 { ids["spotify_user"] = user }
            if p.host == "spotify.link" || p.host == "spoti.fi", let code = segs.first { ids["spotify_short_code"] = code }
        case .soundcloud:
            let segs = p.segments
            guard let artist = segs.first, !soundcloudReserved.contains(artist), p.host != "on.soundcloud.com" else {
                if p.host == "on.soundcloud.com", let code = segs.first { ids["soundcloud_short_code"] = code }
                break
            }
            ids["soundcloud_artist"] = artist
            if segs.count >= 3, segs[1] == "sets" { ids["soundcloud_playlist"] = segs[2] }
            else if segs.count >= 2, !["likes", "reposts", "tracks", "albums", "sets", "followers", "following", "comments"].contains(segs[1]) { ids["soundcloud_track"] = segs[1] }
        case .appleMusic:
            if let id = p.segment(after: "album"), let n = numericAfter(p, "album") { ids["apple_music_album_id"] = n; _ = id }
            if let n = numericAfter(p, "song") { ids["apple_music_track_id"] = n }
            if let n = numericAfter(p, "artist") { ids["apple_music_artist_id"] = n }
            if let i = p.segments.firstIndex(of: "playlist"), let pl = p.segments[(i + 1)...].first(where: { $0.hasPrefix("pl.") }) { ids["apple_music_playlist_id"] = pl }
            if let track = p.query["i"], Extractors.isNumeric(track) { ids["apple_music_track_id"] = track }
            if let storefront = p.segments.first, storefront.count == 2 { ids["apple_storefront"] = storefront }
        case .applePodcasts:
            if let i = p.segments.firstIndex(of: "podcast"), let idSeg = p.segments[(i + 1)...].first(where: { $0.hasPrefix("id") && Extractors.isNumeric(String($0.dropFirst(2))) }) {
                ids["apple_podcast_id"] = String(idSeg.dropFirst(2))
            }
            if let episode = p.query["i"], Extractors.isNumeric(episode) { ids["apple_podcast_episode_id"] = episode }
        case .bandcamp:
            if p.rawHost.hasSuffix(".bandcamp.com"), p.rawHost != "www.bandcamp.com" { ids["bandcamp_artist"] = String(p.rawHost.dropLast(".bandcamp.com".count)) }
            if let track = p.segment(after: "track") { ids["bandcamp_track"] = track }
            if let album = p.segment(after: "album") { ids["bandcamp_album"] = album }
        case .discogs:
            if let r = p.segment(after: "release"), let d = Extractors.leadingDigits(r) { ids["discogs_release_id"] = d }
            if let m = p.segment(after: "master"), let d = Extractors.leadingDigits(m) { ids["discogs_master_id"] = d }
            if let a = p.segment(after: "artist"), let d = Extractors.leadingDigits(a) { ids["discogs_artist_id"] = d }
            if let l = p.segment(after: "label"), let d = Extractors.leadingDigits(l) { ids["discogs_label_id"] = d }
        case .musicbrainz:
            for kind in ["release", "release-group", "recording", "artist", "label", "work"] {
                if let mbid = p.segment(after: kind), mbid.count == 36 { ids["musicbrainz_\(kind.replacingOccurrences(of: "-", with: "_"))_id"] = mbid }
            }
        case .shazam:
            if let id = p.segment(after: "track") ?? p.segment(after: "song"), let d = Extractors.leadingDigits(id) { ids["shazam_track_id"] = d }
        case .deezer:
            for kind in ["track", "album", "artist", "playlist", "episode", "show"] {
                if let id = p.segment(after: kind), Extractors.isNumeric(id) { ids["deezer_\(kind)_id"] = id }
            }
        case .tidal:
            for kind in ["track", "album", "artist", "playlist", "video", "mix"] {
                if let id = p.segment(after: kind) { ids["tidal_\(kind)_id"] = id }
            }
        case .mixcloud:
            if p.segments.count >= 2, !["discover", "upload", "settings", "search"].contains(p.segments[0]) {
                ids["mixcloud_user"] = p.segments[0]; ids["mixcloud_show"] = p.segments[1]
            } else if let user = p.segments.first { ids["mixcloud_user"] = user }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }

    /// The first all-numeric segment after `marker` — Apple puts a slug between.
    private static func numericAfter(_ p: URLParts, _ marker: String) -> String? {
        guard let i = p.segments.firstIndex(of: marker) else { return nil }
        return p.segments[(i + 1)...].first(where: Extractors.isNumeric)
    }
}
