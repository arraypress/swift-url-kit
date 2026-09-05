//
//  Developer.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//

import Foundation
import URLCore

enum DeveloperExtractor: IDExtractor {

    static let platforms: [Platform] = [.github, .gitlab, .stackoverflow, .npm, .pypi, .cratesIo, .huggingface, .swiftPackageIndex, .codepen, .dockerHub, .hackerNews]

    private static let githubReserved: Set<String> = [
        "orgs", "topics", "settings", "marketplace", "features", "about", "login", "explore", "trending", "sponsors",
        "apps", "search", "notifications", "pulls", "issues", "codespaces", "new", "collections", "events", "site",
        "security", "pricing", "customer-stories", "readme", "enterprise", "team", "contact", "join", "signup",
        "organizations", "dashboard", "stars", "watching", "account", "sessions", "logout",
    ]

    static func extract(from p: URLParts, platform: Platform) -> [String: String] {
        var ids: [String: String] = [:]
        switch platform {
        case .github:
            if p.host == "gist.github.com" {
                if p.segments.count >= 2 { ids["github_owner"] = p.segments[0]; ids["github_gist_id"] = p.segments[1] }
                else if let id = p.segments.first { ids["github_gist_id"] = id }
                break
            }
            if p.host == "raw.githubusercontent.com" {
                if p.segments.count >= 3 { ids["github_owner"] = p.segments[0]; ids["github_repo"] = p.segments[1]; ids["github_ref"] = p.segments[2] }
                if p.segments.count >= 4 { ids["github_path"] = p.segments[3...].joined(separator: "/") }
                break
            }
            if p.host.hasSuffix(".github.io") { ids["github_owner"] = String(p.host.dropLast(".github.io".count)); break }
            guard let owner = p.segments.first, !githubReserved.contains(owner) else { break }
            ids["github_owner"] = owner
            guard p.segments.count >= 2 else { break }
            ids["github_repo"] = p.segments[1]
            guard p.segments.count >= 4 else { break }
            let kind = p.segments[2], value = p.segments[3]
            switch kind {
            case "pull": ids["github_pr_number"] = value
            case "issues": ids["github_issue_number"] = value
            case "discussions": ids["github_discussion_number"] = value
            case "commit": ids["github_commit"] = value
            case "releases": if value == "tag", p.segments.count >= 5 { ids["github_release_tag"] = p.segments[4] }
            case "tree", "blob":
                ids["github_ref"] = value
                if p.segments.count >= 5 { ids["github_path"] = p.segments[4...].joined(separator: "/") }
            case "actions": if value == "runs", p.segments.count >= 5 { ids["github_run_id"] = p.segments[4] }
            default: break
            }
        case .gitlab:
            let segs = p.segments
            if let dash = segs.firstIndex(of: "-") {
                let project = Array(segs[..<dash])
                if project.count >= 2 { ids["gitlab_namespace"] = project.dropLast().joined(separator: "/"); ids["gitlab_project"] = project.last }
                if dash + 2 <= segs.count - 1 {
                    switch segs[dash + 1] {
                    case "merge_requests": ids["gitlab_mr_number"] = segs[dash + 2]
                    case "issues": ids["gitlab_issue_number"] = segs[dash + 2]
                    case "commit": ids["gitlab_commit"] = segs[dash + 2]
                    case "tree", "blob": ids["gitlab_ref"] = segs[dash + 2]
                    default: break
                    }
                }
            } else if segs.count >= 2, !["users", "explore", "groups", "help", "dashboard"].contains(segs[0]) {
                ids["gitlab_namespace"] = segs.dropLast().joined(separator: "/"); ids["gitlab_project"] = segs.last
            }
        case .stackoverflow:
            if let q = p.segment(after: "questions") ?? p.segment(after: "q") { ids["stackoverflow_question_id"] = q }
            if let a = p.segment(after: "a") { ids["stackoverflow_answer_id"] = a }
            if let u = p.segment(after: "users") { ids["stackoverflow_user_id"] = u }
            if let i = p.segments.firstIndex(of: "questions"), i + 3 < p.segments.count, Extractors.isNumeric(p.segments[i + 3]) { ids["stackoverflow_answer_id"] = p.segments[i + 3] }
            if p.host.hasSuffix("stackexchange.com"), let site = p.host.split(separator: ".").first { ids["stackexchange_site"] = String(site) }
        case .npm:
            if let i = p.segments.firstIndex(of: "package"), i + 1 < p.segments.count {
                let name = p.segments[i + 1]
                ids["npm_package"] = name.hasPrefix("@") && i + 2 < p.segments.count ? "\(name)/\(p.segments[i + 2])" : name
            }
        case .pypi:
            if let name = p.segment(after: "project") { ids["pypi_package"] = name }
        case .cratesIo:
            if let name = p.segment(after: "crates") { ids["crate"] = name }
        case .huggingface:
            let segs = p.segments
            if let paper = p.segment(after: "papers") { ids["arxiv_id"] = paper; break }
            if let kind = segs.first, ["datasets", "spaces"].contains(kind), segs.count >= 3 {
                ids["huggingface_owner"] = segs[1]; ids["huggingface_repo"] = segs[2]; ids["huggingface_kind"] = kind == "datasets" ? "dataset" : "space"
            } else if segs.count >= 2, !["models", "docs", "blog", "pricing", "join", "login", "settings", "collections"].contains(segs[0]) {
                ids["huggingface_owner"] = segs[0]; ids["huggingface_repo"] = segs[1]; ids["huggingface_kind"] = "model"
            }
        case .swiftPackageIndex:
            if p.segments.count >= 2, !["search", "add-a-package", "faq", "privacy", "packages"].contains(p.segments[0]) {
                ids["package_owner"] = p.segments[0]; ids["package_repo"] = p.segments[1]
            }
        case .codepen:
            if p.segments.count >= 3, ["pen", "full", "details", "debug"].contains(p.segments[1]) { ids["codepen_user"] = p.segments[0]; ids["codepen_pen_id"] = p.segments[2] }
        case .dockerHub:
            if p.segments.count >= 2, p.segments[0] == "r" { ids["docker_image"] = p.segments[1...].prefix(2).joined(separator: "/") }
            else if p.segments.count >= 2, p.segments[0] == "_" { ids["docker_image"] = p.segments[1] }
        case .hackerNews:
            if let id = p.query["id"] { ids["hackernews_item_id"] = id }
        default:
            break
        }
        return ids.compactMapValues { $0.isEmpty ? nil : $0 }
    }
}
