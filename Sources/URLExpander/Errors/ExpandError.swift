//
//  ExpandError.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why a link could not be followed.
public enum ExpandError: Error, LocalizedError, Sendable, Equatable {
    /// The string is not a URL at all.
    case notAURL(String)
    /// `mailto:`, `javascript:` and friends are not followed.
    case unsupportedScheme(String)
    /// Still redirecting after `ExpandOptions.maxHops`.
    case tooManyHops(Int)
    /// A redirect returned to a URL already visited.
    case redirectLoop(String)
    /// No answer within `ExpandOptions.timeout`.
    case timedOut(String)
    /// DNS, TLS, a refused connection — anything the host did that is not HTTP.
    case network(String)

    /// A lowercase phrase that reads inside a sentence, for a CLI or a log.
    public var errorDescription: String? {
        switch self {
        case .notAURL(let s): return "not a URL: \(s)"
        case .unsupportedScheme(let s): return "only http and https links are followed, not \(s):"
        case .tooManyHops(let n): return "still redirecting after \(n) hops"
        case .redirectLoop(let url): return "redirect loop at \(url)"
        case .timedOut(let url): return "no answer in time from \(url)"
        case .network(let why): return why
        }
    }
}
