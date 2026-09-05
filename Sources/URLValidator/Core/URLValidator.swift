//
//  URLValidator.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  Validates, normalises and classifies URLs: which of 450+ platforms one
//  belongs to, what identifiers it carries, what kind of file it points at,
//  and what it looks like before anyone taps it. Offline; Foundation and
//  UniformTypeIdentifiers only.
//

import Foundation
@_exported import URLCore
import UniformTypeIdentifiers

/// The public entry points. Everything is a pure static function.
public struct URLValidator {

    private init() {}

    // MARK: - Validity

    /// Whether a string is a URL, or a bare domain that becomes one with `https://`.
    ///
    /// Rejects emails, single words, `://` with nothing before it, schemes with
    /// no host, and — new in 2.0 — bare decimals like `1.5`, which are not
    /// domains even though they contain a dot.
    public static func isValid(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if trimmed.contains("@") && !trimmed.contains("://") { return false }
        if trimmed.hasPrefix("://") { return false }

        if trimmed.contains("://") && !trimmed.hasPrefix("file://") {
            let after = trimmed.components(separatedBy: "://").dropFirst().joined(separator: "://")
            if after.isEmpty || after.hasPrefix(":") || after.hasPrefix("/") { return false }
        }

        if !trimmed.contains(".") && !trimmed.contains("://") {
            guard trimmed == "localhost" || trimmed.hasPrefix("localhost:") else { return false }
        }

        if let url = URL(string: trimmed), let scheme = url.scheme {
            if scheme == "file" { return true }
            if scheme == "http" || scheme == "https" { return !(url.host ?? "").isEmpty }
            if trimmed.contains("://") {
                let after = trimmed.components(separatedBy: "://").last ?? ""
                return !after.isEmpty && !after.hasPrefix(":")
            }
            return true
        }

        if !trimmed.contains("://") {
            guard let url = URL(string: "https://\(trimmed)"), let host = url.host, !host.isEmpty else { return false }
            return looksLikeAHost(host)
        }
        return false
    }

    /// A scheme-less string must have a real-looking host: a dotted-quad IP,
    /// `localhost`, or a last label of two or more letters. `1.5` and `3.14`
    /// have dots and are not hosts.
    private static func looksLikeAHost(_ host: String) -> Bool {
        if host == "localhost" || host.hasPrefix("localhost") { return true }
        if Signals.isIPAddress(host) { return true }
        guard let last = host.split(separator: ".").last else { return false }
        return last.count >= 2 && last.allSatisfy(\.isLetter)
    }

    /// Adds `https://` to a bare domain; returns anything else unchanged.
    public static func normalize(_ string: String) -> String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("://") else { return trimmed }
        if !trimmed.contains(" ") && (trimmed.contains(".") || trimmed.contains("localhost")) {
            return "https://\(trimmed)"
        }
        return trimmed
    }

    // MARK: - Platform

    /// Which service a URL belongs to. Deterministic: the most specific host
    /// entry wins, then path overrides (YouTube Shorts, Instagram Reels,
    /// Google Maps under google.com) apply.
    public static func detectPlatform(from urlString: String) -> Platform {
        guard let url = URL(string: normalize(urlString)), let parts = URLParts(url) else { return .unknown }
        return HostIndex.platform(for: parts)
    }

    /// The category of a platform.
    public static func category(for platform: Platform) -> PlatformCategory {
        platform.category
    }

    // MARK: - Media type

    /// What kind of file the URL's extension says it is.
    public static func detectMediaType(from urlString: String) -> MediaType {
        guard let url = URL(string: normalize(urlString)) else { return .unknown }
        return MediaTypes.type(forExtension: url.pathExtension)
    }

    // MARK: - Signals

    /// What the link looks like before anyone taps it — shortened, a tracking
    /// redirect, credentials before `@`, a bare IP, punycode, a code scheme.
    public static func signals(for urlString: String) -> LinkSignals {
        let normalized = normalize(urlString)
        guard let url = URL(string: normalized), let parts = URLParts(url) else {
            return Signals.schemeOnly(normalized)
        }
        return Signals.compute(for: parts, original: urlString)
    }

    // MARK: - Everything

    /// The full analysis.
    public static func analyze(_ urlString: String) -> URLAnalysis {
        var analysis = URLAnalysis(originalURL: urlString)
        let normalized = normalize(urlString)
        analysis.isValid = isValid(urlString)

        // A dangerous scheme is worth reporting even though it is not a valid link.
        if !analysis.isValid {
            analysis.signals = Signals.schemeOnly(normalized)
            return analysis
        }
        guard let url = URL(string: normalized) else {
            analysis.isValid = false
            return analysis
        }

        analysis.url = url
        analysis.scheme = url.scheme
        analysis.host = url.host
        analysis.path = url.path.isEmpty ? nil : url.path
        analysis.query = url.query
        analysis.fragment = url.fragment
        analysis.port = url.port
        analysis.isHTTPS = url.scheme == "https"
        analysis.isHTTP = url.scheme == "http"
        analysis.isFileURL = url.isFileURL

        if let parts = URLParts(url) {
            analysis.platform = HostIndex.platform(for: parts)
            analysis.platformCategory = analysis.platform.category
            analysis.extractedIDs = Extractors.extract(from: parts, platform: analysis.platform)
            analysis.signals = Signals.compute(for: parts, original: urlString)
        } else {
            analysis.signals = Signals.schemeOnly(normalized)
        }

        let ext = url.pathExtension
        if !ext.isEmpty {
            analysis.fileExtension = ext.lowercased()
            analysis.mediaType = MediaTypes.type(forExtension: ext)
            if let ut = UTType(filenameExtension: ext) {
                analysis.utType = ut
                analysis.mimeType = ut.preferredMIMEType
                analysis.fileTypeDescription = ut.localizedDescription
            }
        }
        return analysis
    }

    /// The platforms an extractor exists for.
    public static var platformsWithIDExtraction: Set<Platform> { Extractors.covered }
}
