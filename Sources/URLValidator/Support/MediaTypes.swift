//
//  MediaTypes.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  File-type judgement from an extension: a short manual list for formats
//  UTType does not know, then UTType conformance.
//

import Foundation
import URLCore
import UniformTypeIdentifiers

enum MediaTypes {

    /// Formats UTType does not register, or classifies oddly.
    private static let audio: Set<String> = ["ogg", "oga", "opus", "ape", "wv", "tta", "dts", "ac3", "eac3", "f4a", "amr", "mka"]
    private static let video: Set<String> = ["mkv", "webm", "flv", "vob", "ogv", "m2ts", "mts", "f4v", "f4p", "ts"]
    private static let image: Set<String> = ["jxl", "avif", "heif", "heic", "webp", "svgz", "psd", "raw", "cr2", "cr3", "nef", "arw", "dng"]
    private static let archive: Set<String> = ["7z", "rar", "xz", "zst", "lz4", "tgz", "tbz2", "cab", "dmg", "pkg", "deb", "rpm", "apk", "ipa"]
    private static let document: Set<String> = ["epub", "mobi", "azw", "azw3", "djvu", "odt", "ods", "odp", "pages", "numbers", "key", "md", "markdown"]
    private static let code: Set<String> = ["swift", "kt", "kts", "rs", "go", "ts", "tsx", "jsx", "py", "rb", "php", "java", "c", "h", "cpp", "hpp", "m", "mm", "cs", "scala", "sh", "zsh", "lua", "dart", "sql"]
    private static let data: Set<String> = ["json", "yaml", "yml", "toml", "xml", "csv", "tsv", "parquet", "sqlite", "db", "plist", "ndjson"]
    private static let executable: Set<String> = ["exe", "msi", "bat", "cmd", "com", "scr", "app", "jar"]
    private static let font: Set<String> = ["woff", "woff2", "ttf", "otf", "eot"]
    private static let model3d: Set<String> = ["usdz", "usd", "usda", "usdc", "obj", "fbx", "gltf", "glb", "stl", "dae", "3ds", "blend"]

    static func type(forExtension ext: String) -> MediaType {
        let e = ext.lowercased()
        guard !e.isEmpty else { return .unknown }
        if audio.contains(e) { return .audio }
        if video.contains(e) { return .video }
        if image.contains(e) { return .image }
        if archive.contains(e) { return .archive }
        if document.contains(e) { return .document }
        if code.contains(e) { return .code }
        if data.contains(e) { return .data }
        if executable.contains(e) { return .executable }
        if font.contains(e) { return .font }
        if model3d.contains(e) { return .model3d }

        guard let ut = UTType(filenameExtension: e) else { return .unknown }
        if ut.conforms(to: .image) { return .image }
        if ut.conforms(to: .movie) || ut.conforms(to: .video) { return .video }
        if ut.conforms(to: .audio) { return .audio }
        if ut.conforms(to: .pdf) || ut.conforms(to: .text) || ut.conforms(to: .rtf) || ut.conforms(to: .presentation) || ut.conforms(to: .spreadsheet) { return .document }
        if ut.conforms(to: .archive) { return .archive }
        if ut.conforms(to: .sourceCode) { return .code }
        if ut.conforms(to: .data) || ut.conforms(to: .database) { return .data }
        if ut.conforms(to: .executable) || ut.conforms(to: .application) { return .executable }
        if ut.conforms(to: .font) { return .font }
        if ut.conforms(to: .threeDContent) { return .model3d }
        return .unknown
    }
}
