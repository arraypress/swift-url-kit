//
//  Registry.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum Extractors {

    static let all: [any IDExtractor.Type] = [
        VideoExtractor.self, SocialExtractor.self, AudioExtractor.self, DeveloperExtractor.self,
        CommerceExtractor.self, ReferenceExtractor.self, EntertainmentExtractor.self, MapsExtractor.self,
        MessagingExtractor.self, DocumentExtractor.self, ImageExtractor.self,
    ]

    private static let byPlatform: [Platform: any IDExtractor.Type] = {
        var map: [Platform: any IDExtractor.Type] = [:]
        for extractor in all { for platform in extractor.platforms { map[platform] = extractor } }
        return map
    }()

    /// Platforms with an extractor — for tests and documentation.
    static var covered: Set<Platform> { Set(byPlatform.keys) }

    static func extract(from parts: URLParts, platform: Platform) -> [String: String] {
        byPlatform[platform]?.extract(from: parts, platform: platform) ?? [:]
    }

    // MARK: Shared helpers

    /// Leading run of digits: "12345-the-title" → "12345".
    static func leadingDigits(_ s: String) -> String? {
        let d = s.prefix { $0.isNumber }
        return d.isEmpty ? nil : String(d)
    }

    /// Whatever follows the last `-`: "title-abc123" → "abc123".
    static func afterLastDash(_ s: String) -> String? {
        guard let i = s.lastIndex(of: "-"), s.index(after: i) < s.endIndex else { return nil }
        return String(s[s.index(after: i)...])
    }

    static func isNumeric(_ s: String) -> Bool { !s.isEmpty && s.allSatisfy(\.isNumber) }

    static func isHex(_ s: String, count: Int? = nil) -> Bool {
        !s.isEmpty && s.allSatisfy(\.isHexDigit) && (count.map { $0 == s.count } ?? true)
    }

    /// Search boxes form-encode: `usb+c+hub` is three words. Only for query
    /// text — a `+44` phone number must keep its plus.
    static func formDecoded(_ s: String) -> String { s.replacingOccurrences(of: "+", with: " ") }

    /// "lat,lng" → both, when both parse.
    static func coordinates(_ s: String) -> (String, String)? {
        let parts = s.split(separator: ",").map(String.init)
        guard parts.count >= 2, Double(parts[0]) != nil, Double(parts[1]) != nil else { return nil }
        return (parts[0], parts[1])
    }
}
