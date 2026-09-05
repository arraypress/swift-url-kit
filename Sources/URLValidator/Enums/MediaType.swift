//
//  MediaType.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

/// What kind of file a URL points at, judged by its extension.
public enum MediaType: String, CaseIterable, Sendable, Codable {
    case image = "Image"
    case video = "Video"
    case audio = "Audio"
    case document = "Document"
    case archive = "Archive"
    case code = "Code"
    case data = "Data"
    case executable = "Executable"
    case font = "Font"
    case model3d = "3D Model"
    case unknown = "Unknown"
}
