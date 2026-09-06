//
//  Hop.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One step on the way from a link to where it really goes.
public struct Hop: Sendable, Codable, Equatable {
    /// The URL this hop arrived at.
    public let url: String
    /// The HTTP status that sent us here — nil for an offline unwrap.
    public let status: Int?
    /// How: `"301"`, `"302 (GET)"` when HEAD was refused, `"offline: Google"`
    /// when the destination was read out of the URL without a request.
    public let via: String

    /// - Parameters:
    ///   - url: The URL arrived at.
    ///   - status: The redirect status that led here, or nil for an offline unwrap.
    ///   - via: How this hop was made, for a trace.
    public init(url: String, status: Int?, via: String) {
        self.url = url
        self.status = status
        self.via = via
    }
}
