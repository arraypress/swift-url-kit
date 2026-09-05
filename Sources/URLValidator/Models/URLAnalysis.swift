//
//  URLAnalysis.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore
import UniformTypeIdentifiers

/// Everything the library can say about one URL.
public struct URLAnalysis: Sendable {
    public let originalURL: String
    public var isValid: Bool = false
    public var url: URL?

    // Components
    public var scheme: String?
    public var host: String?
    public var path: String?
    public var query: String?
    public var fragment: String?
    public var port: Int?

    // Transport
    public var isHTTPS: Bool = false
    public var isHTTP: Bool = false
    public var isFileURL: Bool = false

    // Identity
    public var platform: Platform = .unknown
    public var platformCategory: PlatformCategory = .unknown

    // File type, from the extension
    public var mediaType: MediaType = .unknown
    public var fileExtension: String?
    public var utType: UTType?
    public var mimeType: String?
    public var fileTypeDescription: String?

    /// Platform identifiers — `youtube_video_id`, `github_owner`, `amazon_asin`.
    /// Keys are stable and documented per extractor.
    public var extractedIDs: [String: String] = [:]

    /// What the link looks like before anyone taps it.
    public var signals: LinkSignals = .none

    public init(originalURL: String) {
        self.originalURL = originalURL
    }

    /// The link goes through a shortener, so the destination is hidden.
    public var isShortened: Bool { signals.isShortened }

    /// One line: "YouTube • Video • Secure • 1 ID(s)".
    public var summary: String {
        var parts: [String] = []
        if platform != .unknown { parts.append(platform.rawValue) }
        if platform.isDefunct, let year = platform.retiredIn { parts.append("retired \(year)") }
        if mediaType != .unknown { parts.append(mediaType.rawValue) }
        if let ext = fileExtension { parts.append(".\(ext)") }
        if isHTTPS { parts.append("Secure") }
        if signals.isShortened, let s = signals.shortener { parts.append("shortened via \(s)") }
        if !extractedIDs.isEmpty { parts.append("\(extractedIDs.count) ID(s)") }
        if signals.isSuspicious { parts.append("\(signals.concerns.count) concern(s)") }
        return parts.isEmpty ? (isValid ? "URL" : "Invalid URL") : parts.joined(separator: " • ")
    }
}
