//
//  Maps.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum MapsExtractor: IDExtractor {

    static let platforms: [Platform] = [.googleMaps, .appleMaps, .openstreetmap, .what3words, .waze]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .googleMaps:
            if p.host == "maps.app.goo.gl" || p.host == "goo.gl", let code = p.segments.last, code != "maps" { ids["google_maps_short_code"] = code }
            if let place = p.segment(after: "place") { ids["maps_place"] = (place.removingPercentEncoding ?? place).replacingOccurrences(of: "+", with: " ") }
            if let at = p.segments.first(where: { $0.hasPrefix("@") }), let (lat, lng) = Extractors.coordinates(String(at.dropFirst())) {
                ids["maps_latitude"] = lat; ids["maps_longitude"] = lng
            }
            if let q = p.query["q"] ?? p.query["query"] {
                if let (lat, lng) = Extractors.coordinates(q) { ids["maps_latitude"] = lat; ids["maps_longitude"] = lng } else { ids["maps_query"] = q }
            }
            if let ll = p.query["ll"], let (lat, lng) = Extractors.coordinates(ll) { ids["maps_latitude"] = lat; ids["maps_longitude"] = lng }
            if let cid = p.query["cid"] { ids["google_maps_cid"] = cid }
            if let pid = p.query["place_id"] ?? p.query["query_place_id"] { ids["google_maps_place_id"] = pid }
            if let i = p.segments.firstIndex(of: "dir"), i + 2 < p.segments.count {
                ids["maps_origin"] = p.segments[i + 1].replacingOccurrences(of: "+", with: " ")
                ids["maps_destination"] = p.segments[i + 2].replacingOccurrences(of: "+", with: " ")
            }
        case .appleMaps:
            if let ll = p.query["ll"] ?? p.query["sll"], let (lat, lng) = Extractors.coordinates(ll) { ids["maps_latitude"] = lat; ids["maps_longitude"] = lng }
            if let q = p.query["q"] { ids["maps_query"] = q }
            if let address = p.query["address"] { ids["maps_address"] = address }
            if let id = p.query["place-id"] ?? p.query["auid"] { ids["apple_maps_place_id"] = id }
            if let daddr = p.query["daddr"] { ids["maps_destination"] = daddr }
            if let saddr = p.query["saddr"] { ids["maps_origin"] = saddr }
        case .openstreetmap:
            if let f = p.fragment, f.hasPrefix("map=") {
                let parts = f.dropFirst(4).split(separator: "/").map(String.init)
                if parts.count == 3 { ids["maps_zoom"] = parts[0]; ids["maps_latitude"] = parts[1]; ids["maps_longitude"] = parts[2] }
            }
            for kind in ["node", "way", "relation", "changeset"] { if let id = p.segment(after: kind) { ids["osm_\(kind)_id"] = id } }
        case .what3words:
            if let words = p.segments.first, words.split(separator: ".").count == 3 { ids["what3words_address"] = words }
        case .waze:
            if let ll = p.query["ll"], let (lat, lng) = Extractors.coordinates(ll) { ids["maps_latitude"] = lat; ids["maps_longitude"] = lng }
            if let q = p.query["q"] { ids["maps_query"] = q }
            if let place = p.query["place"] { ids["waze_place_id"] = place }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }
}
