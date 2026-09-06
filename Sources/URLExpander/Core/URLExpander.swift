//
//  URLExpander.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//
//  Follows a link to where it really goes. The one module in the kit that
//  touches the network: shorteners keep their destinations server-side, so
//  there is no other way to learn them.
//
//  Redirects are followed BY HAND, one hop at a time, so that every hop is
//  reported and a wrapper met mid-chain (a Safe Link behind a bit.ly) is
//  peeled offline rather than fetched. HEAD is tried first; hosts that refuse
//  it get a GET for the first byte only.
//

import Foundation
import URLCore

/// Follows a link to where it really goes.
///
/// Stateless: every call makes its own requests and shares nothing. The
/// only module in the kit that touches the network.
public enum URLExpander {

    /// Where a link goes, hop by hop.
    ///
    /// - Parameter session: For tests, or a caller with its own configuration.
    ///   The default is ephemeral — no cookies, no cache — with the option's
    ///   timeout.
    public static func expand(_ string: String,
                              options: ExpandOptions = ExpandOptions(),
                              session: URLSession? = nil) async throws -> Expansion {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ExpandError.notAURL(string) }

        // Anything with a scheme keeps it — `mailto:` must not become a host
        // called "mailto". Only a scheme-less string is a domain someone typed.
        let candidate: String
        if let scheme = Self.scheme(of: trimmed) {
            guard scheme == "http" || scheme == "https" else { throw ExpandError.unsupportedScheme(scheme) }
            candidate = trimmed
        } else {
            candidate = "https://" + trimmed
        }
        guard var current = URLComponents(string: candidate), let host = current.host, !host.isEmpty else {
            throw ExpandError.notAURL(trimmed)
        }

        let session = session ?? URLExpander.makeSession(timeout: options.timeout)
        var hops: [Hop] = []
        var seen: Set<String> = [current.string ?? candidate]
        var finalStatus: Int? = nil

        while true {
            // 1. Anything whose destination is in the URL is peeled without a request.
            if let (target, label) = Redirects.unwrap(current), let next = target.string {
                guard seen.insert(next).inserted else { throw ExpandError.redirectLoop(next) }
                hops.append(Hop(url: next, status: nil, via: "offline: \(label)"))
                current = target
                guard hops.count < options.maxHops else { throw ExpandError.tooManyHops(options.maxHops) }
                continue
            }
            if options.offlineOnly { break }

            // 2. Ask the server, HEAD first.
            guard let url = current.url else { throw ExpandError.notAURL(current.string ?? trimmed) }
            var (status, location) = try await fetch(url, method: "HEAD", options: options, session: session)
            var via = "\(status)"
            if Self.headRefused(status) {
                (status, location) = try await fetch(url, method: "GET", options: options, session: session)
                via = "\(status) (GET)"
            }

            guard (300...399).contains(status), let location, !location.isEmpty else {
                finalStatus = status
                break
            }
            guard let nextURL = URL(string: location, relativeTo: url)?.absoluteURL,
                  let nextComponents = URLComponents(url: nextURL, resolvingAgainstBaseURL: false) else {
                throw ExpandError.network("unreadable Location header from \(url.absoluteString): \(location)")
            }
            let nextString = nextURL.absoluteString
            guard seen.insert(nextString).inserted else { throw ExpandError.redirectLoop(nextString) }
            hops.append(Hop(url: nextString, status: status, via: via))
            current = nextComponents
            guard hops.count < options.maxHops else { throw ExpandError.tooManyHops(options.maxHops) }
        }

        return Expansion(original: string, hops: hops,
                         finalURL: current.string ?? candidate, finalStatus: finalStatus)
    }

    // MARK: - Batch

    /// Where each of several links goes, followed a few at a time.
    ///
    /// One result per input, in the order given. A link that cannot be
    /// followed becomes a `.failure` in its own slot rather than an error for
    /// the whole list — one dead host must not cost the caller the answers for
    /// every other link.
    ///
    /// All the links share one session, so connections to a host that appears
    /// twice are reused.
    ///
    /// - Parameters:
    ///   - inputs: The links to follow.
    ///   - options: How far to follow, and how many at once.
    ///   - session: For tests, or a caller with its own configuration.
    /// - Returns: One ``ExpansionResult`` per input, in the original order.
    public static func expand(_ inputs: [String],
                              options: ExpandOptions = ExpandOptions(),
                              session: URLSession? = nil) async -> [ExpansionResult] {
        guard !inputs.isEmpty else { return [] }
        let limit = max(1, options.maxConcurrency)
        let session = session ?? URLExpander.makeSession(timeout: options.timeout)

        return await withTaskGroup(of: (Int, ExpansionResult).self) { group in
            var results = [ExpansionResult?](repeating: nil, count: inputs.count)
            var next = 0

            // Prime the group up to the limit, then refill as tasks finish — a
            // sliding window, so a list of two hundred links does not open two
            // hundred connections at once.
            func addTask(_ index: Int) {
                let input = inputs[index]
                group.addTask {
                    do {
                        let expansion = try await expand(input, options: options, session: session)
                        return (index, ExpansionResult(url: input, outcome: .success(expansion)))
                    } catch let error as ExpandError {
                        return (index, ExpansionResult(url: input, outcome: .failure(error)))
                    } catch {
                        return (index, ExpansionResult(url: input, outcome: .failure(.network(error.localizedDescription))))
                    }
                }
            }

            while next < min(limit, inputs.count) {
                addTask(next)
                next += 1
            }

            for await (index, result) in group {
                results[index] = result
                if next < inputs.count {
                    addTask(next)
                    next += 1
                }
            }

            return results.compactMap { $0 }
        }
    }

    // MARK: - Parsing

    /// The scheme a string starts with — `mailto`, `https` — or nil for none.
    /// RFC 3986: a letter, then letters, digits, `+`, `-` or `.`, then a colon.
    static func scheme(of string: String) -> String? {
        guard let colon = string.firstIndex(of: ":"), colon != string.startIndex else { return nil }
        let head = string[..<colon]
        guard head.first!.isLetter, head.allSatisfy({ $0.isLetter || $0.isNumber || "+-.".contains($0) }) else { return nil }
        return head.lowercased()
    }

    // MARK: - Requests

    /// Servers that will not answer HEAD usually say so with one of these.
    static func headRefused(_ status: Int) -> Bool { [400, 403, 405, 501].contains(status) }

    private static func fetch(_ url: URL, method: String, options: ExpandOptions,
                              session: URLSession) async throws -> (Int, String?) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: options.timeout)
        request.httpMethod = method
        request.setValue(options.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if method == "GET" { request.setValue("bytes=0-0", forHTTPHeaderField: "Range") }
        do {
            let (_, response) = try await session.data(for: request, delegate: RedirectStopper())
            guard let http = response as? HTTPURLResponse else {
                throw ExpandError.network("no HTTP response from \(url.host ?? url.absoluteString)")
            }
            return (http.statusCode, http.value(forHTTPHeaderField: "Location"))
        } catch let error as ExpandError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw ExpandError.timedOut(url.absoluteString)
        } catch {
            throw ExpandError.network("\(url.host ?? url.absoluteString): \(error.localizedDescription)")
        }
    }

    static func makeSession(timeout: TimeInterval) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        return URLSession(configuration: configuration)
    }
}
