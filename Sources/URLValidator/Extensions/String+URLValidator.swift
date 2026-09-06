//
//  String+URLValidator.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  Thin delegates for call sites holding a String.
//

import Foundation
import URLCore

extension String {

    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    // MARK: Validity

    /// Whether the string parses as a URL at all.
    public var isValidURL: Bool { URLValidator.isValid(self) }
    /// The string with a scheme added if it lacked one, ready to parse.
    public var normalizedURL: String { URLValidator.normalize(self) }
    /// Everything the validator can say about it in one pass.
    public var urlAnalysis: URLAnalysis { URLValidator.analyze(self) }

    // MARK: Platform

    /// The platform, or nil when unrecognised.
    public var urlPlatform: Platform? {
        let p = URLValidator.detectPlatform(from: self)
        return p == .unknown ? nil : p
    }

    /// What kind of platform it is, or nil when unrecognised.
    public var urlPlatformCategory: PlatformCategory? { urlPlatform?.category }

    // MARK: Media

    /// The kind of file it points at, judged by extension, or nil.
    public var urlMediaType: MediaType? {
        let m = URLValidator.detectMediaType(from: self)
        return m == .unknown ? nil : m
    }

    // MARK: Signals

    /// What the link looks like before anyone taps it.
    public var linkSignals: LinkSignals { URLValidator.signals(for: self) }
    /// The link goes through a shortener.
    public var isShortenedURL: Bool { linkSignals.isShortened }
    /// The URL has a shape phishing and tracking tend to use — see `linkSignals.concerns`.
    public var isSuspiciousURL: Bool { linkSignals.isSuspicious }

    // MARK: Category checks

    /// A video platform — YouTube, Vimeo.
    public var isVideoPlatformURL: Bool { urlPlatformCategory == .video }
    /// An audio platform — Spotify, SoundCloud.
    public var isAudioPlatformURL: Bool { urlPlatformCategory == .audio }
    /// A social network.
    public var isSocialMediaURL: Bool { urlPlatformCategory == .social }
    /// A messaging service.
    public var isMessagingPlatformURL: Bool { urlPlatformCategory == .messaging }
    /// A developer platform — GitHub, GitLab.
    public var isDeveloperPlatformURL: Bool { urlPlatformCategory == .developer }
    /// A federated or alternative platform — Mastodon, Bluesky.
    public var isAlternativePlatformURL: Bool { urlPlatformCategory == .alternative }
    /// A web3 platform.
    public var isWeb3PlatformURL: Bool { urlPlatformCategory == .web3 }
    /// A gaming platform — Steam, Twitch.
    public var isGamingPlatformURL: Bool { urlPlatformCategory == .gaming }
    /// A financial platform.
    public var isFinancialPlatformURL: Bool { urlPlatformCategory == .financial }
    /// A dating platform.
    public var isDatingPlatformURL: Bool { urlPlatformCategory == .dating }
    /// A creator-subscription platform — Patreon, Substack.
    public var isSubscriptionPlatformURL: Bool { urlPlatformCategory == .subscription }
    /// A news publisher.
    public var isNewsURL: Bool { urlPlatformCategory == .news }
    /// An AI platform.
    public var isAIPlatformURL: Bool { urlPlatformCategory == .ai }

    // MARK: File checks

    /// The path ends in a video file extension.
    public var hasVideoExtension: Bool { urlMediaType == .video }
    /// The path ends in an audio file extension.
    public var hasAudioExtension: Bool { urlMediaType == .audio }
    /// The path ends in an image file extension.
    public var hasImageExtension: Bool { urlMediaType == .image }
    /// The path ends in a document file extension.
    public var hasDocumentExtension: Bool { urlMediaType == .document }

    // MARK: Transport

    /// Served over HTTPS.
    public var isHTTPS: Bool { URL(string: normalizedURL)?.scheme == "https" }
    /// Served over plain HTTP — worth a second look.
    public var isHTTP: Bool { URL(string: normalizedURL)?.scheme == "http" }
    /// A `file://` URL, pointing at this machine rather than the web.
    public var isFileURL: Bool { URL(string: normalizedURL)?.isFileURL ?? false }

    // MARK: Components

    /// The host, or nil if there is none.
    public var urlDomain: String? { URL(string: normalizedURL)?.host }
    /// The path, or nil when it is empty.
    public var urlPath: String? { URL(string: normalizedURL)?.path.nilIfEmpty }
    /// The raw query string, or nil.
    public var urlQuery: String? { URL(string: normalizedURL)?.query }
    /// The lowercased file extension of the last path segment, or nil.
    public var urlExtension: String? { URL(string: normalizedURL)?.pathExtension.nilIfEmpty?.lowercased() }

    // MARK: Identifiers

    /// The YouTube video id, from any of its URL shapes.
    public var youtubeVideoID: String? { urlAnalysis.extractedIDs["youtube_video_id"] }
    /// The status id of a tweet.
    public var tweetID: String? { urlAnalysis.extractedIDs["tweet_id"] }
    /// The shortcode of an Instagram post.
    public var instagramPostID: String? { urlAnalysis.extractedIDs["instagram_post_id"] }
    /// The numeric id of a TikTok video.
    public var tiktokVideoID: String? { urlAnalysis.extractedIDs["tiktok_video_id"] }
    /// The Spotify id, whichever kind of thing it points at.
    public var spotifyID: String? { urlAnalysis.extractedIDs.first { $0.key.hasPrefix("spotify_") && $0.key.hasSuffix("_id") }?.value }
    /// The base-36 id of a Reddit post.
    public var redditPostID: String? { urlAnalysis.extractedIDs["reddit_post_id"] }
    /// The product's ASIN.
    public var amazonASIN: String? { urlAnalysis.extractedIDs["amazon_asin"] }
    /// The IMDb title or name id — `tt0111161`.
    public var imdbID: String? { urlAnalysis.extractedIDs["imdb_id"] }
    /// The numeric App Store id.
    public var appStoreID: String? { urlAnalysis.extractedIDs["app_store_id"] }
    /// The arXiv paper id.
    public var arxivID: String? { urlAnalysis.extractedIDs["arxiv_id"] }
    /// The DOI, from a doi.org or publisher URL.
    public var doi: String? { urlAnalysis.extractedIDs["doi"] }
    /// The article title, underscores and all.
    public var wikipediaTitle: String? { urlAnalysis.extractedIDs["wikipedia_title"] }

    /// The owner and repository name, when the link is a GitHub repo.
    public var githubRepo: (owner: String, repo: String)? {
        let ids = urlAnalysis.extractedIDs
        guard let owner = ids["github_owner"], let repo = ids["github_repo"] else { return nil }
        return (owner, repo)
    }
}
