//
//  ExpansionResult.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The outcome of expanding one link in a batch.
///
/// The batch entry point ``URLExpander/expand(_:options:session:)-batch``
/// returns one of these per input, so one dead host never costs the caller the
/// answers for every other link in the list.
///
/// ```swift
/// for result in await URLExpander.expand(links) {
///     if let expansion = result.expansion {
///         print("✓ \(expansion.finalURL)")
///     } else {
///         print("✗ \(result.url): \(result.error?.localizedDescription ?? "")")
///     }
/// }
/// ```
public struct ExpansionResult: Sendable {

    /// Whether the link was followed, or why it could not be.
    public enum Outcome: Sendable {
        /// The link was followed to its destination.
        case success(Expansion)
        /// Following it failed with the given error.
        case failure(ExpandError)
    }

    /// The link as the caller passed it.
    public let url: String

    /// The success or failure outcome.
    public let outcome: Outcome

    /// Creates a batch result.
    public init(url: String, outcome: Outcome) {
        self.url = url
        self.outcome = outcome
    }

    /// Where the link went, or nil if it failed.
    public var expansion: Expansion? {
        if case .success(let expansion) = outcome { return expansion }
        return nil
    }

    /// The failure, or nil if the link was followed.
    public var error: ExpandError? {
        if case .failure(let error) = outcome { return error }
        return nil
    }

    /// Whether this link was followed successfully.
    public var isSuccess: Bool {
        if case .success = outcome { return true }
        return false
    }
}
