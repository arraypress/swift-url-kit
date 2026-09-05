//
//  Documents.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum DocumentExtractor: IDExtractor {

    static let platforms: [Platform] = [.googleDrive, .googleForms, .googlePhotos, .googleCalendar, .dropbox, .onedrive, .box, .wetransfer, .icloud, .figma, .notion, .miro, .canva, .airtable, .trello, .calendly, .calCom, .typeform, .tally, .medium, .substack, .linear, .jira, .asana, .clickup, .monday, .obsidian, .craft]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .googleDrive, .googleForms:
            if let id = p.segment(after: "d") ?? p.query["id"] {
                switch p.segments.first {
                case "document": ids["google_docs_id"] = id
                case "spreadsheets": ids["google_sheets_id"] = id
                case "presentation": ids["google_slides_id"] = id
                case "forms": ids["google_forms_id"] = (id == "e" ? p.segments.dropFirst(3).first : id)
                default: ids["google_drive_file_id"] = id
                }
            }
            if let folder = p.segment(after: "folders") { ids["google_drive_folder_id"] = folder }
            if let gid = p.query["gid"] { ids["google_sheets_gid"] = gid }
            if p.host == "forms.gle", let code = p.segments.first { ids["google_forms_short_code"] = code }
            if p.host == "sites.google.com", let site = p.segment(after: "view") { ids["google_sites_name"] = site }
        case .googlePhotos:
            if p.host == "photos.app.goo.gl", let code = p.segments.first { ids["google_photos_short_code"] = code }
            if let album = p.segment(after: "share") { ids["google_photos_album_id"] = album }
        case .googleCalendar:
            if let eid = p.query["eid"] { ids["google_calendar_event_id"] = eid }
        case .dropbox:
            if let key = p.segment(after: "s") ?? p.segment(after: "fi") ?? p.segment(after: "fo") ?? p.segment(after: "sh") { ids["dropbox_share_key"] = key }
            if p.host == "db.tt", let code = p.segments.first { ids["dropbox_short_code"] = code }
        case .onedrive:
            if p.host == "1drv.ms", p.segments.count >= 2 { ids["onedrive_short_code"] = p.segments[1] }
            if let resid = p.query["resid"] { ids["onedrive_resource_id"] = resid }
        case .box:
            if let key = p.segment(after: "s") { ids["box_shared_key"] = key }
        case .wetransfer:
            if p.host == "we.tl", let code = p.segments.first { ids["wetransfer_code"] = code }
            if let id = p.segment(after: "downloads") { ids["wetransfer_transfer_id"] = id }
        case .icloud:
            for kind in ["iclouddrive", "photos", "notes", "numbers", "pages", "keynote", "reminders"] {
                if let id = p.segment(after: kind) { ids["icloud_share_id"] = id.removingPercentEncoding?.split(separator: "#").first.map(String.init) ?? id; ids["icloud_kind"] = kind }
            }
        case .figma:
            for kind in ["file", "design", "proto", "board", "slides", "make", "deck", "site"] {
                if let key = p.segment(after: kind) { ids["figma_file_key"] = key; ids["figma_kind"] = kind }
            }
            if let node = p.query["node-id"] { ids["figma_node_id"] = node }
        case .notion:
            let candidates = [p.query["p"], p.segments.last].compactMap { $0 }
            for c in candidates {
                let raw = c.replacingOccurrences(of: "-", with: "")
                let tail = String(raw.suffix(32))
                if raw.count >= 32, Extractors.isHex(tail, count: 32) { ids["notion_page_id"] = formatted(tail); break }
            }
            if let v = p.query["v"], Extractors.isHex(v.replacingOccurrences(of: "-", with: ""), count: 32) { ids["notion_view_id"] = formatted(v.replacingOccurrences(of: "-", with: "")) }
        case .miro:
            if let id = p.segment(after: "board") { ids["miro_board_id"] = id }
        case .canva:
            if let id = p.segment(after: "design") { ids["canva_design_id"] = id }
        case .airtable:
            if let base = p.segments.first(where: { $0.hasPrefix("app") && $0.count == 17 }) { ids["airtable_base_id"] = base }
            if let table = p.segments.first(where: { $0.hasPrefix("tbl") && $0.count == 17 }) { ids["airtable_table_id"] = table }
            if let view = p.segments.first(where: { $0.hasPrefix("viw") && $0.count == 17 }) { ids["airtable_view_id"] = view }
            if let share = p.segments.first(where: { $0.hasPrefix("shr") && $0.count == 17 }) { ids["airtable_share_id"] = share }
        case .trello:
            if let b = p.segment(after: "b") { ids["trello_board_id"] = b }
            if let c = p.segment(after: "c") { ids["trello_card_id"] = c }
        case .calendly:
            if let code = p.segment(after: "d") { ids["calendly_link_code"] = code; break }
            if let user = p.segments.first, !["app", "d", "login", "signup", "pricing", "integrations"].contains(user) {
                ids["calendly_user"] = user
                if p.segments.count >= 2 { ids["calendly_event"] = p.segments[1] }
            }
        case .calCom:
            if let user = p.segments.first, !["app", "login", "signup", "pricing", "docs", "team", "booking"].contains(user) {
                ids["cal_user"] = user
                if p.segments.count >= 2 { ids["cal_event"] = p.segments[1] }
            }
        case .typeform:
            if let id = p.segment(after: "to") { ids["typeform_id"] = id }
        case .tally:
            if let id = p.segment(after: "r") { ids["tally_form_id"] = id }
        case .medium:
            if p.rawHost.hasSuffix(".medium.com"), !["www.medium.com", "medium.com", "link.medium.com"].contains(p.rawHost) {
                ids["medium_publication"] = String(p.rawHost.dropLast(".medium.com".count))
            }
            if let user = p.segments.first(where: { $0.hasPrefix("@") }) { ids["medium_user"] = String(user.dropFirst()) }
            else if p.segments.count >= 2, !["p", "m", "tag", "search", "me"].contains(p.segments[0]) { ids["medium_publication"] = p.segments[0] }
            if let last = p.segments.last, let id = Extractors.afterLastDash(last), id.count >= 10, Extractors.isHex(id) { ids["medium_article_id"] = id }
            else if p.segments.first == "p", p.segments.count >= 2 { ids["medium_article_id"] = p.segments[1] }
        case .substack:
            if p.rawHost.hasSuffix(".substack.com"), p.rawHost != "www.substack.com" { ids["substack_publication"] = String(p.rawHost.dropLast(".substack.com".count)) }
            if let post = p.segment(after: "p") { ids["substack_post"] = post }
            if let first = p.segments.first, first.hasPrefix("@") { ids["substack_user"] = String(first.dropFirst()) }
        case .linear:
            if let i = p.segments.firstIndex(of: "issue"), i + 1 < p.segments.count {
                ids["linear_issue_key"] = p.segments[i + 1]
                if i >= 1 { ids["linear_workspace"] = p.segments[i - 1] }
            }
        case .jira:
            if p.rawHost.hasSuffix(".atlassian.net"), let site = p.rawHost.split(separator: ".").first { ids["jira_site"] = String(site) }
            if let key = p.segment(after: "browse") { ids["jira_issue_key"] = key }
            if let key = p.query["selectedIssue"] { ids["jira_issue_key"] = key }
        case .asana:
            if p.segments.first == "0", p.segments.count >= 3 { ids["asana_project_id"] = p.segments[1]; ids["asana_task_id"] = p.segments[2] }
        case .clickup:
            if let id = p.segment(after: "t") { ids["clickup_task_id"] = id }
        case .monday:
            if let b = p.segment(after: "boards") { ids["monday_board_id"] = b }
            if let item = p.segment(after: "pulses") { ids["monday_item_id"] = item }
        case .obsidian:
            if p.host == "publish.obsidian.md", p.segments.count >= 1 {
                ids["obsidian_site"] = p.segments[0]
                if p.segments.count >= 2 { ids["obsidian_note"] = p.segments[1...].joined(separator: "/").removingPercentEncoding }
            }
        case .craft:
            if let id = p.segment(after: "s") { ids["craft_share_id"] = id }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }

    /// 32 hex → 8-4-4-4-12, the form Notion's API wants.
    private static func formatted(_ hex: String) -> String {
        let h = Array(hex)
        guard h.count == 32 else { return hex }
        return "\(String(h[0..<8]))-\(String(h[8..<12]))-\(String(h[12..<16]))-\(String(h[16..<20]))-\(String(h[20..<32]))"
    }
}
