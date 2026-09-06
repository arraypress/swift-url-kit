//
//  ParameterPattern.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  One of the shapes the rule tables are written in. Data only — matching
//  lives in Support/.
//

import Foundation

/// How a parameter name is recognised. Names are compared lowercased.
public enum ParameterPattern: Sendable, Hashable {
    /// The whole name, e.g. `gclid`.
    case exact(String)
    /// Any name starting with this, e.g. `utm_` catches `utm_source` and every
    /// variant a marketing team invents next year.
    case prefix(String)

    /// The lowercased text of the pattern, for listings.
    public var text: String {
        switch self {
        case .exact(let name): return name
        case .prefix(let name): return name + "*"
        }
    }
}
