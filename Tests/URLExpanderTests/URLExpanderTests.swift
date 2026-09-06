//
//  URLExpanderTests.swift
//  URLExpander
//
//  Created by David Sherlock on 2026.
//
//  A stub URLProtocol plays the servers, so every hop shape is exercised
//  without a network. One live test at the end, opt-in.
//

import XCTest
@testable import URLExpander

/// Answers requests from a table of (method + url) → (status, headers).
/// Records what was asked, so headers and methods can be asserted.
final class StubServer: URLProtocol {
    struct Answer { let status: Int; let headers: [String: String] }
    nonisolated(unsafe) static var routes: [String: Answer] = [:]
    nonisolated(unsafe) static var requests: [URLRequest] = []

    static func key(_ method: String, _ url: String) -> String { "\(method) \(url)" }
    static func reset() { routes = [:]; requests = [] }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        StubServer.requests.append(request)
        let method = request.httpMethod ?? "GET"
        let url = request.url!.absoluteString
        let answer = StubServer.routes[StubServer.key(method, url)]
            ?? StubServer.routes[StubServer.key("*", url)]
            ?? Answer(status: 404, headers: [:])
        let response = HTTPURLResponse(url: request.url!, statusCode: answer.status, httpVersion: "HTTP/1.1", headerFields: answer.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class URLExpanderTests: XCTestCase {

    private var session: URLSession!

    override func setUp() {
        super.setUp()
        StubServer.reset()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubServer.self]
        session = URLSession(configuration: configuration)
    }

    private func route(_ method: String, _ url: String, _ status: Int, location: String? = nil) {
        StubServer.routes[StubServer.key(method, url)] = .init(status: status, headers: location.map { ["Location": $0] } ?? [:])
    }

    // MARK: - Chains

    func testFollowsAChainHopByHopAndReportsEachStatus() async throws {
        route("HEAD", "https://short.example/a", 301, location: "https://mid.example/b")
        route("HEAD", "https://mid.example/b", 302, location: "https://final.example/page?id=1")
        route("HEAD", "https://final.example/page?id=1", 200)

        let e = try await URLExpander.expand("https://short.example/a", session: session)
        XCTAssertEqual(e.finalURL, "https://final.example/page?id=1")
        XCTAssertEqual(e.finalStatus, 200)
        XCTAssertEqual(e.hops.map(\.via), ["301", "302"])
        XCTAssertEqual(e.hops.map(\.url), ["https://mid.example/b", "https://final.example/page?id=1"])
        XCTAssertTrue(e.didRedirect)
        XCTAssertEqual(e.destinationExists, true)
    }

    func testALinkThatDoesNotRedirectHasNoHops() async throws {
        route("HEAD", "https://example.com/a", 200)
        let e = try await URLExpander.expand("https://example.com/a", session: session)
        XCTAssertTrue(e.hops.isEmpty)
        XCTAssertFalse(e.didRedirect)
        XCTAssertEqual(e.finalURL, "https://example.com/a")
    }

    func testADeadDestinationIsReportedNotThrown() async throws {
        route("HEAD", "https://short.example/x", 301, location: "https://gone.example/p")
        route("HEAD", "https://gone.example/p", 404)
        let e = try await URLExpander.expand("https://short.example/x", session: session)
        XCTAssertEqual(e.finalStatus, 404)
        XCTAssertEqual(e.destinationExists, false)
        XCTAssertEqual(e.finalURL, "https://gone.example/p")
    }

    func testRelativeLocationIsResolvedAgainstTheHop() async throws {
        route("HEAD", "https://example.com/old/page", 301, location: "/new/page")
        route("HEAD", "https://example.com/new/page", 200)
        let e = try await URLExpander.expand("https://example.com/old/page", session: session)
        XCTAssertEqual(e.finalURL, "https://example.com/new/page")
    }

    // MARK: - HEAD refused

    func testHeadRefusedFallsBackToAFirstByteGet() async throws {
        route("HEAD", "https://picky.example/l", 405)
        route("GET", "https://picky.example/l", 302, location: "https://final.example/")
        route("HEAD", "https://final.example/", 200)
        let e = try await URLExpander.expand("https://picky.example/l", session: session)
        XCTAssertEqual(e.hops.first?.via, "302 (GET)")
        XCTAssertEqual(e.finalURL, "https://final.example/")
        let get = try XCTUnwrap(StubServer.requests.first { $0.httpMethod == "GET" })
        XCTAssertEqual(get.value(forHTTPHeaderField: "Range"), "bytes=0-0", "a GET fallback must not download the page")
    }

    func testEveryRequestCarriesTheUserAgent() async throws {
        route("HEAD", "https://example.com/", 200)
        _ = try await URLExpander.expand("https://example.com/", options: ExpandOptions(userAgent: "test-agent/1"), session: session)
        XCTAssertEqual(StubServer.requests.first?.value(forHTTPHeaderField: "User-Agent"), "test-agent/1")
    }

    // MARK: - Offline wrappers mid-chain

    func testAWrapperIsPeeledOfflineBeforeAnyRequestIsMade() async throws {
        // bit.ly → Google redirect → Safe Link → page. Only the shortener and
        // the page should be fetched; the two wrappers carry their targets.
        let page = "https://final.example/doc"
        let safelink = "https://eur01.safelinks.protection.outlook.com/?url=" + page.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let google = "https://www.google.com/url?q=" + safelink.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        route("HEAD", "https://bit.ly/abc", 301, location: google)
        route("HEAD", page, 200)

        let e = try await URLExpander.expand("https://bit.ly/abc", session: session)
        XCTAssertEqual(e.finalURL, page)
        XCTAssertEqual(e.hops.map(\.via), ["301", "offline: Google", "offline: Outlook Safe Links"])
        XCTAssertEqual(Set(StubServer.requests.map { $0.url!.host! }), ["bit.ly", "final.example"], "the wrappers were never fetched")
    }

    func testOfflineOnlyPeelsAndStopsWithoutARequest() async throws {
        let e = try await URLExpander.expand("https://www.google.com/url?q=https://example.com/a", options: ExpandOptions(offlineOnly: true), session: session)
        XCTAssertEqual(e.finalURL, "https://example.com/a")
        XCTAssertNil(e.finalStatus)
        XCTAssertTrue(StubServer.requests.isEmpty)
    }

    // MARK: - Refusals

    func testLoopsAndLongChainsAreErrorsNotHangs() async {
        route("HEAD", "https://a.example/", 302, location: "https://b.example/")
        route("HEAD", "https://b.example/", 302, location: "https://a.example/")
        do {
            _ = try await URLExpander.expand("https://a.example/", session: session)
            XCTFail("loop")
        } catch let error as ExpandError {
            XCTAssertEqual(error, .redirectLoop("https://a.example/"))
        } catch { XCTFail("\(error)") }

        for i in 0..<20 { route("HEAD", "https://hop\(i).example/", 301, location: "https://hop\(i + 1).example/") }
        do {
            _ = try await URLExpander.expand("https://hop0.example/", options: ExpandOptions(maxHops: 5), session: session)
            XCTFail("too many")
        } catch let error as ExpandError {
            XCTAssertEqual(error, .tooManyHops(5))
        } catch { XCTFail("\(error)") }
    }

    func testOnlyHTTPLinksAreFollowed() async {
        for bad in ["mailto:a@b.c", "javascript:alert(1)", "ftp://files.example/x"] {
            do {
                _ = try await URLExpander.expand(bad, session: session)
                XCTFail(bad)
            } catch let error as ExpandError {
                if case .unsupportedScheme = error {} else { XCTFail("\(bad) → \(error)") }
            } catch { XCTFail("\(error)") }
        }
        do {
            _ = try await URLExpander.expand("   ", session: session)
            XCTFail("empty")
        } catch let error as ExpandError {
            if case .notAURL = error {} else { XCTFail("\(error)") }
        } catch { XCTFail("\(error)") }
    }

    func testABareDomainIsTreatedAsHTTPS() async throws {
        route("HEAD", "https://example.com/path", 200)
        let e = try await URLExpander.expand("example.com/path", session: session)
        XCTAssertEqual(e.finalURL, "https://example.com/path")
    }

    // MARK: - Batch

    /// The point of the batch entry point: one dead host must not cost the
    /// caller the answers for every other link in the list.
    func testABadLinkInABatchIsItsOwnFailureAndTheRestStillResolve() async {
        route("HEAD", "https://a.example/1", 200)
        route("HEAD", "https://c.example/3", 301, location: "https://d.example/4")
        route("HEAD", "https://d.example/4", 200)

        let results = await URLExpander.expand(
            ["https://a.example/1", "mailto:someone@example.com", "https://c.example/3"],
            session: session)

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].expansion?.finalURL, "https://a.example/1")
        XCTAssertEqual(results[1].error, .unsupportedScheme("mailto"))
        XCTAssertNil(results[1].expansion)
        XCTAssertEqual(results[2].expansion?.finalURL, "https://d.example/4")
        XCTAssertEqual(results.filter(\.isSuccess).count, 2)
    }

    /// Results come back in the order the caller wrote them, whatever order
    /// the hosts happened to answer in.
    func testBatchResultsKeepTheInputOrder() async {
        let urls = (0..<12).map { "https://h\($0).example/p" }
        for url in urls { route("HEAD", url, 200) }
        let results = await URLExpander.expand(urls, options: ExpandOptions(maxConcurrency: 4), session: session)
        XCTAssertEqual(results.map(\.url), urls)
        XCTAssertEqual(results.compactMap { $0.expansion?.finalURL }, urls)
    }

    func testAnEmptyBatchIsAnEmptyResultNotAnError() async {
        let results = await URLExpander.expand([], session: session)
        XCTAssertTrue(results.isEmpty)
    }

    /// A destination that answers 404 is a successful expansion of a dead
    /// link — the request worked, the page is gone. `check` leans on this.
    func testADeadDestinationIsAnExpansionNotAFailure() async throws {
        route("HEAD", "https://gone.example/page", 404)
        let e = try await URLExpander.expand("https://gone.example/page", session: session)
        XCTAssertEqual(e.finalStatus, 404)
        XCTAssertEqual(e.destinationExists, false)
    }

    func testOfflineOnlyLeavesTheDestinationUnknownRatherThanClaimingItLives() async throws {
        let e = try await URLExpander.expand("https://gone.example/page",
                                             options: ExpandOptions(offlineOnly: true), session: session)
        XCTAssertNil(e.finalStatus)
        XCTAssertNil(e.destinationExists)
    }

    // MARK: - Live, opt in

    /// `URLKIT_LIVE=1 swift test --filter URLExpanderTests/testLive`
    func testLiveYouTubeShortLinkExpands() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["URLKIT_LIVE"] == "1", "set URLKIT_LIVE=1")
        let e = try await URLExpander.expand("https://youtu.be/dQw4w9WgXcQ")
        XCTAssertTrue(e.finalURL.contains("youtube.com/watch"), e.finalURL)
        XCTAssertTrue(e.finalURL.contains("v=dQw4w9WgXcQ"), e.finalURL)
        XCTAssertTrue(e.didRedirect)
    }
}
