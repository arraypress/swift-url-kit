//
//  URL+URLValidator.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  The same surface for Foundation's URL.
//

import Foundation
import URLCore

public extension URL {
    /// Everything the validator can say about this URL in one pass.
    var analysis: URLAnalysis { URLValidator.analyze(absoluteString) }
    /// The platform it belongs to, or nil when unrecognised.
    var platform: Platform? { absoluteString.urlPlatform }
    /// What kind of platform it is, or nil when unrecognised.
    var platformCategory: PlatformCategory? { absoluteString.urlPlatformCategory }
    /// The kind of file it points at, judged by extension, or nil.
    var mediaType: MediaType? { absoluteString.urlMediaType }
    /// What the link looks like before anyone taps it.
    var linkSignals: LinkSignals { URLValidator.signals(for: absoluteString) }
    /// The identifiers found in it, keyed by name — `youtube_video_id`, `doi`.
    var extractedIDs: [String: String] { analysis.extractedIDs }
    /// Whether the link goes through a shortener.
    var isShortened: Bool { linkSignals.isShortened }
}
