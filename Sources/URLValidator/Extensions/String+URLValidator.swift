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

    public var isValidURL: Bool { URLValidator.isValid(self) }
    public var normalizedURL: String { URLValidator.normalize(self) }
    public var urlAnalysis: URLAnalysis { URLValidator.analyze(self) }

    // MARK: Platform

    /// The platform, or nil when unrecognised.
    public var urlPlatform: Platform? {
        let p = URLValidator.detectPlatform(from: self)
        return p == .unknown ? nil : p
    }

    public var urlPlatformCategory: PlatformCategory? { urlPlatform?.category }

    // MARK: Media

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

    public var isVideoPlatformURL: Bool { urlPlatformCategory == .video }
    public var isAudioPlatformURL: Bool { urlPlatformCategory == .audio }
    public var isSocialMediaURL: Bool { urlPlatformCategory == .social }
    public var isMessagingPlatformURL: Bool { urlPlatformCategory == .messaging }
    public var isDeveloperPlatformURL: Bool { urlPlatformCategory == .developer }
    public var isAlternativePlatformURL: Bool { urlPlatformCategory == .alternative }
    public var isWeb3PlatformURL: Bool { urlPlatformCategory == .web3 }
    public var isGamingPlatformURL: Bool { urlPlatformCategory == .gaming }
    public var isFinancialPlatformURL: Bool { urlPlatformCategory == .financial }
    public var isDatingPlatformURL: Bool { urlPlatformCategory == .dating }
    public var isSubscriptionPlatformURL: Bool { urlPlatformCategory == .subscription }
    public var isNewsURL: Bool { urlPlatformCategory == .news }
    public var isAIPlatformURL: Bool { urlPlatformCategory == .ai }

    // MARK: File checks

    public var hasVideoExtension: Bool { urlMediaType == .video }
    public var hasAudioExtension: Bool { urlMediaType == .audio }
    public var hasImageExtension: Bool { urlMediaType == .image }
    public var hasDocumentExtension: Bool { urlMediaType == .document }

    // MARK: Transport

    public var isHTTPS: Bool { URL(string: normalizedURL)?.scheme == "https" }
    public var isHTTP: Bool { URL(string: normalizedURL)?.scheme == "http" }
    public var isFileURL: Bool { URL(string: normalizedURL)?.isFileURL ?? false }

    // MARK: Components

    public var urlDomain: String? { URL(string: normalizedURL)?.host }
    public var urlPath: String? { URL(string: normalizedURL)?.path.nilIfEmpty }
    public var urlQuery: String? { URL(string: normalizedURL)?.query }
    public var urlExtension: String? { URL(string: normalizedURL)?.pathExtension.nilIfEmpty?.lowercased() }

    // MARK: Identifiers

    public var youtubeVideoID: String? { urlAnalysis.extractedIDs["youtube_video_id"] }
    public var tweetID: String? { urlAnalysis.extractedIDs["tweet_id"] }
    public var instagramPostID: String? { urlAnalysis.extractedIDs["instagram_post_id"] }
    public var tiktokVideoID: String? { urlAnalysis.extractedIDs["tiktok_video_id"] }
    public var spotifyID: String? { urlAnalysis.extractedIDs.first { $0.key.hasPrefix("spotify_") && $0.key.hasSuffix("_id") }?.value }
    public var redditPostID: String? { urlAnalysis.extractedIDs["reddit_post_id"] }
    public var amazonASIN: String? { urlAnalysis.extractedIDs["amazon_asin"] }
    public var imdbID: String? { urlAnalysis.extractedIDs["imdb_id"] }
    public var appStoreID: String? { urlAnalysis.extractedIDs["app_store_id"] }
    public var arxivID: String? { urlAnalysis.extractedIDs["arxiv_id"] }
    public var doi: String? { urlAnalysis.extractedIDs["doi"] }
    public var wikipediaTitle: String? { urlAnalysis.extractedIDs["wikipedia_title"] }

    public var githubRepo: (owner: String, repo: String)? {
        let ids = urlAnalysis.extractedIDs
        guard let owner = ids["github_owner"], let repo = ids["github_repo"] else { return nil }
        return (owner, repo)
    }
}
