//
//  URLCoreTests.swift
//  URLCore
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import URLCore

final class URLCoreTests: XCTestCase {

    func testNormaliseDropsWWWAndCase() {
        XCTAssertEqual(HostMatcher.normalise("WWW.Example.COM."), "example.com")
        XCTAssertNil(HostMatcher.normalise(""))
        XCTAssertNil(HostMatcher.normalise(nil))
    }

    func testBrandMatchesCountryTLDsAndNothingElse() {
        for host in ["amazon.com", "amazon.co.uk", "amazon.com.au", "smile.amazon.de", "music.amazon.co.jp"] {
            XCTAssertTrue(HostMatcher.matches(host, .brand("amazon")), host)
        }
        for host in ["amazon.example.com", "amazonaws.com", "notamazon.com", "amazon-adsystem.com", "amazon.verylongtld"] {
            XCTAssertFalse(HostMatcher.matches(host, .brand("amazon")), host)
        }
    }

    func testSuffixAndExact() {
        XCTAssertTrue(HostMatcher.matches("cooking.nytimes.com", .suffix("nytimes.com")))
        XCTAssertFalse(HostMatcher.matches("fakenytimes.com", .suffix("nytimes.com")))
        XCTAssertTrue(HostMatcher.matches("t.co", .exact("t.co")))
        XCTAssertFalse(HostMatcher.matches("x.t.co", .exact("t.co")))
    }

    func testURLPartsSplitsOnceForEveryone() throws {
        let parts = try XCTUnwrap(URLParts(URL(string: "https://user@www.Example.com:8443/a/b/c.html?x=1&x=2&y#frag")!))
        XCTAssertEqual(parts.host, "example.com")
        XCTAssertEqual(parts.rawHost, "www.example.com")
        XCTAssertEqual(parts.segments, ["a", "b", "c.html"])
        XCTAssertEqual(parts.query["x"], "1", "first value wins")
        XCTAssertEqual(parts.query["y"], "")
        XCTAssertEqual(parts.fragment, "frag")
        XCTAssertEqual(parts.port, 8443)
        XCTAssertEqual(parts.user, "user")
        XCTAssertEqual(parts.segment(after: "a"), "b")
        XCTAssertEqual(parts.lastSegmentStem, "c")
        XCTAssertNil(URLParts(URL(string: "mailto:a@b.c")!), "no host, no parts")
    }

    func testRedirectMatchingAndUnwrapping() throws {
        let google = try XCTUnwrap(URLComponents(string: "https://www.google.com/url?q=https://example.com/a&sa=D"))
        XCTAssertEqual(Redirects.rule(matching: google)?.label, "Google")
        XCTAssertEqual(Redirects.unwrap(google)?.label, "Google")
        XCTAssertEqual(Redirects.unwrap(google)?.0.string, "https://example.com/a")
        XCTAssertTrue(Redirects.isTrackingRedirect(google))

        let search = try XCTUnwrap(URLComponents(string: "https://www.google.com/search?q=x"))
        XCTAssertNil(Redirects.rule(matching: search))
        XCTAssertFalse(Redirects.isTrackingRedirect(search))

        // Opaque: recognisable but not unwrappable.
        let mailchimp = try XCTUnwrap(URLComponents(string: "https://click.mailchimp.com/track/abc"))
        XCTAssertTrue(Redirects.isTrackingRedirect(mailchimp))
        XCTAssertNil(Redirects.unwrap(mailchimp))
    }

    func testShortenersAreNamedAndSubdomainsCount() {
        XCTAssertEqual(Shorteners.service(for: "bit.ly"), "Bitly")
        XCTAssertEqual(Shorteners.service(for: "youtu.be"), "YouTube")
        XCTAssertEqual(Shorteners.service(for: "custom.bit.ly"), "Bitly")
        XCTAssertNil(Shorteners.service(for: "example.com"))
    }
}
