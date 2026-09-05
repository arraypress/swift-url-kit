//
//  IDExtractor.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  One extractor per platform family. Each reads identifiers out of an
//  already-parsed URL and knows nothing about the others.
//

import Foundation
import URLCore

/// Pulls platform identifiers — video ids, handles, ASINs — out of a URL.
///
/// Keys follow `platform_thing` (`youtube_video_id`, `github_owner`) and are
/// stable: they are part of the public contract of ``URLAnalysis/extractedIDs``.
protocol IDExtractor {
    /// The platforms this extractor handles.
    static var platforms: [Platform] { get }
    /// The identifiers found, or an empty dictionary. Never throws, never guesses.
    static func extract(from parts: URLParts, platform: Platform) -> [String: String]
}
