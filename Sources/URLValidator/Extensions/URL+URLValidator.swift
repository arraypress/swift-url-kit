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
    var analysis: URLAnalysis { URLValidator.analyze(absoluteString) }
    var platform: Platform? { absoluteString.urlPlatform }
    var platformCategory: PlatformCategory? { absoluteString.urlPlatformCategory }
    var mediaType: MediaType? { absoluteString.urlMediaType }
    var linkSignals: LinkSignals { URLValidator.signals(for: absoluteString) }
    var extractedIDs: [String: String] { analysis.extractedIDs }
    var isShortened: Bool { linkSignals.isShortened }
}
