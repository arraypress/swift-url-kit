//
//  Reference.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum ReferenceExtractor: IDExtractor {

    static let platforms: [Platform] = [.wikipedia, .wikidata, .wiktionary, .wikimedia, .arxiv, .pubmed, .doi, .semanticScholar, .openAlex, .internetArchive, .googleScholar, .googleSearch, .hackerNews]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .wikipedia, .wiktionary:
            let prefix = platform == .wikipedia ? "wikipedia" : "wiktionary"
            if let title = p.segment(after: "wiki") ?? p.query["title"] {
                ids["\(prefix)_title"] = (title.removingPercentEncoding ?? title).replacingOccurrences(of: "_", with: " ")
            }
            if let id = p.query["curid"] { ids["\(prefix)_page_id"] = id }
            if let lang = p.host.split(separator: ".").first.map(String.init), lang.count <= 3, lang != "m" { ids["\(prefix)_language"] = lang }
        case .wikidata:
            if let id = p.segment(after: "wiki") ?? p.segment(after: "entity"), let first = id.first, "QPL".contains(first) {
                ids["wikidata_id"] = id.split(separator: ":").last.map(String.init)
            }
        case .wikimedia:
            if let file = p.segment(after: "wiki"), file.hasPrefix("File:") { ids["wikimedia_file"] = String(file.dropFirst(5)).removingPercentEncoding }
        case .arxiv:
            if let raw = p.segment(after: "abs") ?? p.segment(after: "pdf") ?? p.segment(after: "html") {
                var id = raw
                if id.hasSuffix(".pdf") { id = String(id.dropLast(4)) }
                // Old-style ids have a category segment: /abs/hep-th/9901001
                if let i = p.segments.firstIndex(of: id), i + 1 < p.segments.count, Extractors.isNumeric(p.segments[i + 1].replacingOccurrences(of: ".", with: "")) {
                    id += "/" + p.segments[i + 1]
                }
                ids["arxiv_id"] = id
            }
        case .pubmed:
            if p.host.hasPrefix("pubmed."), let id = p.segments.first, Extractors.isNumeric(id) { ids["pubmed_id"] = id }
            if let pmc = p.segment(after: "articles"), pmc.hasPrefix("PMC") { ids["pmc_id"] = pmc }
        case .doi:
            let doi = p.path.hasPrefix("/") ? String(p.path.dropFirst()) : p.path
            if doi.hasPrefix("10.") { ids["doi"] = doi.removingPercentEncoding ?? doi }
        case .semanticScholar:
            if let i = p.segments.firstIndex(of: "paper"), let sha = p.segments[(i + 1)...].last, Extractors.isHex(sha, count: 40) { ids["semantic_scholar_paper_id"] = sha }
        case .openAlex:
            if let id = p.segments.last, let first = id.first, "WASICPF".contains(first), Extractors.isNumeric(String(id.dropFirst())) { ids["openalex_id"] = id }
        case .internetArchive:
            if p.host == "web.archive.org", let r = p.path.range(of: "/web/") {
                let rest = p.path[r.upperBound...]
                if let slash = rest.firstIndex(of: "/") {
                    var timestamp = String(rest[..<slash])
                    if let star = timestamp.firstIndex(of: "*") { timestamp = String(timestamp[..<star]) }
                    if !timestamp.isEmpty { ids["wayback_timestamp"] = timestamp }
                    var target = String(rest[rest.index(after: slash)...])
                    if let q = p.url.query { target += "?" + q }
                    ids["wayback_url"] = target
                }
            } else if let item = p.segment(after: "details") { ids["archive_item_id"] = item }
        case .googleScholar:
            if let c = p.query["cluster"] { ids["scholar_cluster_id"] = c }
            if let q = p.query["q"] { ids["scholar_query"] = Extractors.formDecoded(q) }
        case .googleSearch:
            if let q = p.query["q"], !q.isEmpty { ids["google_query"] = Extractors.formDecoded(q) }
        case .hackerNews:
            if let id = p.query["id"] { ids["hackernews_item_id"] = id }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }
}
