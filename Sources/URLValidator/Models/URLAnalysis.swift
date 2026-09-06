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
    /// The string as it was given, before normalising.
    public let originalURL: String
    /// Whether it parsed as a URL at all. Everything below is left at its
    /// default when this is false.
    public var isValid: Bool = false
    /// The parsed URL, normalised — a scheme added if the string lacked one.
    public var url: URL?

    // MARK: Components

    /// The scheme, lowercased.
    public var scheme: String?
    /// The host, lowercased.
    public var host: String?
    /// The path, or nil when empty.
    public var path: String?
    /// The raw query string, or nil.
    public var query: String?
    /// The `#fragment`, or nil.
    public var fragment: String?
    /// An explicit port, if the URL carried one.
    public var port: Int?

    // MARK: Transport

    /// Served over HTTPS.
    public var isHTTPS: Bool = false
    /// Served over plain HTTP — worth a second look.
    public var isHTTP: Bool = false
    /// A `file://` URL, pointing at this machine rather than the web.
    public var isFileURL: Bool = false

    // MARK: Identity

    /// The platform the host belongs to, or `.unknown`.
    public var platform: Platform = .unknown
    /// What kind of platform that is, or `.unknown`.
    public var platformCategory: PlatformCategory = .unknown

    // MARK: File type, from the extension

    /// The broad kind of file the path points at, or `.unknown`.
    public var mediaType: MediaType = .unknown
    /// The lowercased extension of the last path segment, or nil.
    public var fileExtension: String?
    /// The system's type for that extension, when it recognises one.
    public var utType: UTType?
    /// The MIME type for that extension, when the system knows one.
    public var mimeType: String?
    /// The system's human-readable name for the type — "PDF document".
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
