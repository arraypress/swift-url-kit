//
//  Messaging.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum MessagingExtractor: IDExtractor {

    static let platforms: [Platform] = [.discord, .telegram, .whatsapp, .signal, .zoom, .googleMeet, .teams, .slack, .messenger, .matrix, .line]

    private static let telegramReserved: Set<String> = ["joinchat", "s", "c", "addstickers", "addemoji", "share", "proxy", "socks", "setlanguage", "login", "iv", "addtheme", "bg", "m"]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .discord:
            if p.host == "discord.gg", let code = p.segments.first { ids["discord_invite"] = code }
            if let code = p.segment(after: "invite") { ids["discord_invite"] = code }
            if let i = p.segments.firstIndex(of: "channels") {
                let rest = Array(p.segments[(i + 1)...])
                if rest.count >= 1 { ids["discord_guild_id"] = rest[0] }
                if rest.count >= 2 { ids["discord_channel_id"] = rest[1] }
                if rest.count >= 3 { ids["discord_message_id"] = rest[2] }
            }
            if let user = p.segment(after: "users") { ids["discord_user_id"] = user }
        case .telegram:
            guard p.host == "t.me" || p.host == "telegram.me" || p.host == "telegram.dog" else { break }
            guard let first = p.segments.first else { break }
            if first.hasPrefix("+") { ids["telegram_invite"] = String(first.dropFirst()) }
            else if first == "joinchat", let code = p.segments.dropFirst().first { ids["telegram_invite"] = code }
            else if first == "c", p.segments.count >= 3 { ids["telegram_chat_id"] = p.segments[1]; ids["telegram_message_id"] = p.segments[2] }
            else if first == "s", let channel = p.segments.dropFirst().first { ids["telegram_user"] = channel }
            else if first == "addstickers", let set = p.segments.dropFirst().first { ids["telegram_sticker_set"] = set }
            else if !telegramReserved.contains(first) {
                ids["telegram_user"] = first
                if p.segments.count >= 2, Extractors.isNumeric(p.segments[1]) { ids["telegram_message_id"] = p.segments[1] }
            }
            if let start = p.query["start"] ?? p.query["startgroup"] { ids["telegram_start_parameter"] = start }
        case .whatsapp:
            if p.host == "wa.me", let n = p.segments.first, Extractors.isNumeric(n) { ids["whatsapp_number"] = n }
            if let phone = p.query["phone"] { ids["whatsapp_number"] = phone.filter(\.isNumber) }
            if p.host == "chat.whatsapp.com", let code = p.segments.first { ids["whatsapp_invite"] = code }
            if let text = p.query["text"] { ids["whatsapp_text"] = text }
        case .signal:
            if let f = p.fragment {
                if f.hasPrefix("p/") { ids["signal_phone"] = String(f.dropFirst(2)) }
                else if f.hasPrefix("eu/") { ids["signal_username_link"] = String(f.dropFirst(3)) }
            }
        case .zoom:
            if let id = p.segment(after: "j") ?? p.segment(after: "w") ?? p.segment(after: "s"), Extractors.isNumeric(id) { ids["zoom_meeting_id"] = id }
            if let name = p.segment(after: "my") { ids["zoom_personal_name"] = name }
            if let i = p.segments.firstIndex(of: "rec"), i + 2 < p.segments.count, p.segments[i + 1] == "share" { ids["zoom_recording_id"] = p.segments[i + 2] }
        case .googleMeet:
            if let code = p.segments.first, code.split(separator: "-").count == 3 { ids["google_meet_code"] = code }
        case .teams:
            if let i = p.segments.firstIndex(of: "meetup-join"), i + 1 < p.segments.count { ids["teams_thread_id"] = p.segments[i + 1].removingPercentEncoding }
        case .slack:
            if p.rawHost.hasSuffix(".slack.com"), let ws = p.rawHost.split(separator: ".").first, ws != "app", ws != "join" { ids["slack_workspace"] = String(ws) }
            if let i = p.segments.firstIndex(of: "archives"), i + 1 < p.segments.count {
                ids["slack_channel_id"] = p.segments[i + 1]
                if i + 2 < p.segments.count, p.segments[i + 2].hasPrefix("p") { ids["slack_message_ts"] = String(p.segments[i + 2].dropFirst()) }
            }
            if let i = p.segments.firstIndex(of: "shared_invite"), i + 1 < p.segments.count { ids["slack_invite"] = p.segments[i + 1] }
            if p.segments.first == "t", p.segments.count >= 2 { ids["slack_workspace"] = p.segments[1] }
            if let user = p.segment(after: "team") { ids["slack_user_id"] = user }
        case .messenger:
            if p.host == "m.me", let user = p.segments.first { ids["messenger_user"] = user }
            if let thread = p.segment(after: "t") { ids["messenger_thread_id"] = thread }
        case .matrix:
            if let f = p.fragment, f.hasPrefix("/") { ids["matrix_id"] = String(f.dropFirst()).split(separator: "?").first.map(String.init) }
        case .line:
            if let i = p.segments.firstIndex(of: "p"), i + 1 < p.segments.count { ids["line_id"] = p.segments[i + 1] }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }
}
