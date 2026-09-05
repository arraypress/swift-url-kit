//
//  URLStripperTests.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import URLStripper
import URLCore

final class URLStripperTests: XCTestCase {

    // MARK: - The basics

    func testBasicTrackingRemoval() {
        XCTAssertEqual("https://example.com?utm_source=newsletter&id=123&fbclid=abc".withoutTracking,
                       "https://example.com?id=123")
    }

    func testEmptyAndUntouchedURLs() {
        XCTAssertEqual("".withoutTracking, "")
        XCTAssertEqual("https://example.com".withoutTracking, "https://example.com")
        XCTAssertEqual("https://example.com/path".withoutTracking, "https://example.com/path")
        XCTAssertEqual("https://example.com?".withoutTracking, "https://example.com")
    }

    func testAllTrackingRemovedDropsTheQuestionMark() {
        XCTAssertEqual("https://example.com?utm_source=test&utm_medium=email&gclid=123&fbclid=456".withoutTracking,
                       "https://example.com")
    }

    func testFunctionalParametersSurviveInOrder() {
        XCTAssertEqual("https://example.com?utm_source=test&id=123&page=2&sort=date".withoutTracking,
                       "https://example.com?id=123&page=2&sort=date")
    }

    func testCaseInsensitiveNamesAndPreservedCaseOfKeptOnes() {
        XCTAssertEqual("https://example.com?UTM_SOURCE=test&Fbclid=123&ID=page".withoutTracking,
                       "https://example.com?ID=page")
    }

    func testParametersWithoutValues() {
        XCTAssertEqual("https://example.com?utm_source&fbclid&id=123".withoutTracking, "https://example.com?id=123")
    }

    func testEmptyValuesAreKeptWhenTheNameIsFunctional() {
        XCTAssertEqual("https://example.com?utm_source=&id=123".withoutTracking, "https://example.com?id=123")
        XCTAssertEqual("https://example.com?utm_source=test&id=&page=2".withoutTracking, "https://example.com?id=&page=2")
    }

    func testPortAndAnchorSurvive() {
        XCTAssertEqual("https://analytics.example.com:8443/dashboard?utm_source=email&report_id=1#section1".withoutTracking,
                       "https://analytics.example.com:8443/dashboard?report_id=1#section1")
    }

    /// Kept parameters must come back byte for byte: `+` is not a space to
    /// re-encode, and `%20` is not to be turned into `+`.
    func testEncodingOfKeptParametersIsUntouched() {
        XCTAssertEqual("https://example.com?utm_source=t&name=John%20Doe&q=usb+c+hub".withoutTracking,
                       "https://example.com?name=John%20Doe&q=usb+c+hub")
        XCTAssertEqual("https://example.com?utm_campaign=summer%202023&search=cats%20%26%20dogs".withoutTracking,
                       "https://example.com?search=cats%20%26%20dogs")
    }

    func testUnicodeHostBecomesPunycodeAsURLComponentsDoes() {
        XCTAssertEqual("https://müller.de/product?utm_source=test&productId=123".withoutTracking,
                       "https://xn--mller-kva.de/product?productId=123")
    }

    func testMalformedStringsStillGetTheGlobalRules() {
        XCTAssertEqual("not-a-valid-url?utm_source=test&id=123".withoutTracking, "not-a-valid-url?id=123")
        XCTAssertEqual("has a space?utm_source=x&id=1".withoutTracking, "has a space?id=1")
    }

    func testCleaningIsIdempotent() {
        let once = "https://www.amazon.com/Great-Thing/dp/B08N5WRWNW/ref=sr_1_3?tag=x-20&utm_source=a".withoutTracking
        XCTAssertEqual(once.withoutTracking, once)
    }

    // MARK: - False positives: the reason v2 exists

    /// Each of these was DESTROYED by the first version, which stripped 340
    /// names on every host. The query parameter here is the whole point of
    /// the link.
    func testFunctionalParametersThatShareANameWithTrackingAreKept() {
        let functional = [
            "https://www.amazon.com/s?k=usb+c+hub&i=electronics",           // k = Amazon search query
            "https://wordpress.org/?s=gutenberg",                             // s = WordPress search
            "https://example.blog/posts?tag=swift&page=2",                    // tag = filter
            "https://gitlab.com/o/r/-/blob/README.md?ref_type=heads&ref=v1.0",// ref = git ref
            "https://github.com/apple/swift/compare?ref=release",             // ref = git ref
            "https://shop.example.com/list?price=10-20&sort=asc",             // price = filter
            "https://docs.example.com/page?hash=section-2",                   // hash = anchor
            "https://time.example.com/convert?from=UTC&to=PST&ts=1700000000", // from, ts = inputs
            "https://app.example.com/profile?user_id=42",                     // user_id = the record
            "https://jobs.example.com/search?keywords=swift+developer",       // keywords = query
            "https://api.example.com/data?_=1700000000&id=7",                 // _ = cache buster
            "https://www.bilibili.com/video/BV1xx411c7mD?bvid=BV1xx411c7mD&p=2", // bvid = THE video id
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&list=PL1",    // t = timestamp, list = playlist
            "https://medium.com/@a/post-1a2b3c?sk=friendlinkkey",             // sk = friend link, unlocks paywall
            "https://zoom.us/j/1234567890?pwd=abc123",                        // pwd = meeting password
            "https://t.me/somebot?start=ref123",                              // start = bot deep link
            "https://www.nytimes.com/2026/01/01/x.html?unlocked_article_code=1.abc", // gift link
        ]
        for url in functional {
            XCTAssertEqual(url.withoutTracking, url, "a functional parameter was stripped from \(url)")
        }
    }

    // MARK: - Host scoping

    func testTwitterShareParametersAreTrackingOnXOnly() {
        XCTAssertEqual("https://x.com/user/status/1?s=20&t=abc".withoutTracking, "https://x.com/user/status/1")
        XCTAssertEqual("https://twitter.com/user/status/1?s=46&t=xyz&ref_src=twsrc".withoutTracking,
                       "https://twitter.com/user/status/1")
        XCTAssertEqual("https://example.com/search?s=swift&t=week".withoutTracking, "https://example.com/search?s=swift&t=week")
    }

    func testSiIsTrackingOnYouTubeAndSpotifyButNotElsewhere() {
        XCTAssertEqual("https://youtu.be/dQw4w9WgXcQ?si=abcDEF".withoutTracking, "https://youtu.be/dQw4w9WgXcQ")
        XCTAssertEqual("https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=x&nd=1".withoutTracking,
                       "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT")
        XCTAssertEqual("https://example.com/item?si=7".withoutTracking, "https://example.com/item?si=7")
    }

    func testYouTubeKeepsTimeAndPlaylistButLosesShareCruft() {
        XCTAssertEqual("https://www.youtube.com/watch?v=dQw4w9WgXcQ&utm_source=facebook&feature=share&t=42s".withoutTracking,
                       "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s")
        XCTAssertEqual("https://www.youtube.com/watch?v=abc&list=PL123&index=3&pp=ygUF&ab_channel=Name".withoutTracking,
                       "https://www.youtube.com/watch?v=abc&list=PL123&index=3")
    }

    func testAmazonBrandMatchesEveryCountryAndNothingElse() {
        for host in ["www.amazon.com", "amazon.co.uk", "smile.amazon.de", "www.amazon.com.au", "amazon.co.jp"] {
            XCTAssertEqual("https://\(host)/dp/B08N5WRWNW?tag=aff-21&psc=1".withoutTracking,
                           "https://\(host)/dp/B08N5WRWNW?psc=1", host)
        }
        // Not Amazon: `tag` must survive.
        for host in ["amazon.example.com", "amazonaws.com", "notamazon.com", "amazon-adsystem.com"] {
            XCTAssertEqual("https://\(host)/x?tag=keep".withoutTracking, "https://\(host)/x?tag=keep", host)
        }
    }

    func testFacebookOwnLinksLoseTheirInternalTracking() {
        XCTAssertEqual("https://www.facebook.com/page/posts/123?ref=share&__cft__[0]=abc&__tn__=-UK&mibextid=xyz".withoutTracking,
                       "https://www.facebook.com/page/posts/123")
        // …but `ref` on a site that is not Facebook is left alone.
        XCTAssertEqual("https://example.com/docs?ref=nav".withoutTracking, "https://example.com/docs?ref=nav")
    }

    func testTikTokShareParametersAreScopedToTikTok() {
        XCTAssertEqual("https://www.tiktok.com/@u/video/1?ttclid=abc&is_from_webapp=1&sender_device=pc&id=video".withoutTracking,
                       "https://www.tiktok.com/@u/video/1?id=video")
        // ttclid is a click id and global; the TikTok-only names are not tracking elsewhere.
        XCTAssertEqual("https://example.com?ttclid=abc&is_from_webapp=1&id=video".withoutTracking,
                       "https://example.com?is_from_webapp=1&id=video")
    }

    func testGmailIsExcludedFromTheGoogleRule() {
        XCTAssertEqual("https://mail.google.com/mail/u/0/?source=x#inbox".withoutTracking,
                       "https://mail.google.com/mail/u/0/?source=x#inbox")
        XCTAssertEqual("https://www.google.com/search?q=swift&source=hp&ei=abc&ved=2ah&oq=swi".withoutTracking,
                       "https://www.google.com/search?q=swift")
    }

    func testPublisherRules() {
        XCTAssertEqual("https://cnn.com/article?utm_source=twCNN&utm_medium=social&ftag=cnn123".withoutTracking, "https://cnn.com/article")
        XCTAssertEqual("https://bbc.com/news/tech-123?at_medium=custom7&at_campaign=64&article_id=tech-123".withoutTracking,
                       "https://bbc.com/news/tech-123?article_id=tech-123")
        XCTAssertEqual("https://nytimes.com/article?smid=tw-nytimes&smtyp=cur&story_id=456".withoutTracking,
                       "https://nytimes.com/article?story_id=456")
        XCTAssertEqual("https://www.theguardian.com/uk?CMP=share_btn_tw".withoutTracking, "https://www.theguardian.com/uk")
        // `cmp` is not tracking on other sites.
        XCTAssertEqual("https://example.com/compare?cmp=a,b".withoutTracking, "https://example.com/compare?cmp=a,b")
    }

    // MARK: - Prefix rules

    func testPrefixRulesCatchVariantsNoListCouldEnumerate() {
        XCTAssertEqual("https://example.com?utm_reader=x&utm_viz_id=y&utm_swu=z&mtm_group=g&pk_kwd=k&hsa_ver=3&sfmc_activityid=9&at_custom9=q&id=1".withoutTracking,
                       "https://example.com?id=1")
    }

    // MARK: - Email and affiliate networks (global)

    func testEmailMarketingPlatforms() {
        XCTAssertEqual("https://example.com?_hsenc=p2ANqtz-abc&_hsmi=12345&utm_campaign=email".withoutTracking, "https://example.com")
        XCTAssertEqual("https://example.com?mkt_tok=eyJ0eXAi&article_id=10".withoutTracking, "https://example.com?article_id=10")
        XCTAssertEqual("https://example.com?mc_cid=abc&mc_eid=def&ck_subscriber_id=1&_bhlid=2&id=3".withoutTracking, "https://example.com?id=3")
        // Salesforce's `sfmc_` prefix is unique; `jobid`/`subid` are not, and are
        // functional on a jobs site, so they stay.
        XCTAssertEqual("https://example.com?jobid=123&subid=456&sfmc_sub=789&content_id=article".withoutTracking,
                       "https://example.com?jobid=123&subid=456&content_id=article")
    }

    func testAffiliateNetworks() {
        XCTAssertEqual("https://shop.example.com/p/1?awc=123_456&cjevent=abc&irclickid=xyz&ranMID=1&colour=red".withoutTracking,
                       "https://shop.example.com/p/1?colour=red")
    }

    func testShopifyStorefrontTrackingOnACustomDomain() {
        XCTAssertEqual("https://shop.example.com/products/tee?variant=1&_pos=2&_sid=abc&_ss=r&pr_rec_pid=9".withoutTracking,
                       "https://shop.example.com/products/tee?variant=1")
    }

    // MARK: - Redirect unwrapping

    func testGoogleSearchRedirectBecomesTheDestination() {
        let google = "https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwjX&url=https%3A%2F%2Fexample.com%2Farticle"
        XCTAssertEqual(google.withoutTracking, "https://example.com/article")
        XCTAssertEqual("https://www.google.com/url?q=https://example.com/a?id%3D1&sa=D".withoutTracking, "https://example.com/a?id=1")
        XCTAssertEqual("https://www.google.co.uk/amp/s/www.example.com/amp/article".withoutTracking, "https://www.example.com/amp/article")
    }

    func testBingRedirectIsBase64() {
        let payload = Data("https://example.com/page?id=1".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        XCTAssertEqual("https://www.bing.com/ck/a?!&&p=abc&u=a1\(payload)&ntb=1".withoutTracking, "https://example.com/page?id=1")
    }

    func testDuckDuckGoOutlookProofpointAndSlack() {
        XCTAssertEqual("https://duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2Fx&rut=abc".withoutTracking, "https://example.com/x")
        XCTAssertEqual("https://nam12.safelinks.protection.outlook.com/?url=https%3A%2F%2Fexample.com%2Fdoc%3Fid%3D5&data=05%7C01%7C&sdata=abc&reserved=0".withoutTracking,
                       "https://example.com/doc?id=5")
        XCTAssertEqual("https://urldefense.proofpoint.com/v2/url?u=https-3A__www.example.com_path-3Fq-3D1&d=DwMF&c=abc&e=".withoutTracking,
                       "https://www.example.com/path?q=1")
        XCTAssertEqual("https://urldefense.com/v3/__https://example.com/a/b__;!!AbC-dEf$".withoutTracking, "https://example.com/a/b")
        XCTAssertEqual("https://slack-redir.net/link?url=https%3A%2F%2Fexample.com%2Fs".withoutTracking, "https://example.com/s")
    }

    func testSocialAndGamingRedirects() {
        XCTAssertEqual("https://l.facebook.com/l.php?u=https%3A%2F%2Fexample.com%2Ff%3Ffbclid%3DIwAR&h=AT0".withoutTracking, "https://example.com/f")
        XCTAssertEqual("https://l.instagram.com/?u=https%3A%2F%2Fexample.com%2Fi&e=AT1".withoutTracking, "https://example.com/i")
        XCTAssertEqual("https://www.youtube.com/redirect?event=video_description&q=https%3A%2F%2Fexample.com%2Fy".withoutTracking, "https://example.com/y")
        XCTAssertEqual("https://out.reddit.com/t3_abc?url=https%3A%2F%2Fexample.com%2Fr&token=1".withoutTracking, "https://example.com/r")
        XCTAssertEqual("https://www.linkedin.com/redir/redirect?url=https%3A%2F%2Fexample.com%2Fl&urlhash=x".withoutTracking, "https://example.com/l")
        XCTAssertEqual("https://steamcommunity.com/linkfilter/?url=https://example.com/s".withoutTracking, "https://example.com/s")
        XCTAssertEqual("https://vk.com/away.php?to=https%3A%2F%2Fexample.com%2Fv&cc_key=".withoutTracking, "https://example.com/v")
        XCTAssertEqual("https://t.umblr.com/redirect?z=https%3A%2F%2Fexample.com%2Ft&t=abc".withoutTracking, "https://example.com/t")
        XCTAssertEqual("https://www-example-com.cdn.ampproject.org/c/s/www.example.com/page".withoutTracking, "https://www.example.com/page")
    }

    /// A Gmail link to a Safe Link to a page is three wrappers deep.
    func testNestedRedirectsAreAllPeeledAndReported() {
        let inner = "https://example.com/final?id=9"
        let safelink = "https://eur01.safelinks.protection.outlook.com/?url=" + inner.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let google = "https://www.google.com/url?q=" + safelink.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let report = google.cleanReport
        XCTAssertEqual(report.cleaned, inner)
        XCTAssertEqual(report.unwrapped, ["Google", "Outlook Safe Links"])
    }

    func testRedirectsToNonHTTPSchemesAreRefused() {
        let bad = "https://www.google.com/url?q=javascript:alert(1)"
        XCTAssertEqual(bad.withoutTracking, "https://www.google.com/url?q=javascript:alert(1)")
        XCTAssertNil(URLStripper.unwrap(bad))
    }

    func testUnwrapAloneDoesNotClean() {
        XCTAssertEqual("https://www.google.com/url?q=https://example.com/a?utm_source=x".unwrappedRedirect,
                       "https://example.com/a?utm_source=x")
        XCTAssertEqual("https://example.com/a".unwrappedRedirect, "https://example.com/a")
        XCTAssertNil(URLStripper.unwrap("https://example.com/a"))
    }

    // MARK: - Path cleaning

    func testAmazonPathAttributionAndCanonicalisation() {
        XCTAssertEqual("https://www.amazon.com/Sony-WH-1000XM5-Headphones/dp/B09XS7JWHH/ref=sr_1_3?keywords=x&qid=1&sr=8-3&tag=a-20".withoutTracking,
                       "https://www.amazon.com/dp/B09XS7JWHH?keywords=x")
        XCTAssertEqual("https://www.amazon.co.uk/gp/product/B08N5WRWNW/ref=ppx_yo_dt_b?ie=UTF8&psc=1".withoutTracking,
                       "https://www.amazon.co.uk/dp/B08N5WRWNW?psc=1")
        XCTAssertEqual("https://www.amazon.de/-/en/Some-Thing/dp/B08N5WRWNW/".withoutTracking, "https://www.amazon.de/-/en/dp/B08N5WRWNW")
        // A short code that is not an ASIN is left as it is.
        XCTAssertEqual("https://amazon.ca/gp/product/B789?ref=ppx_yo_dt&tag=ca-20".withoutTracking, "https://amazon.ca/gp/product/B789")
    }

    func testEbayItemSlugIsDropped() {
        XCTAssertEqual("https://www.ebay.co.uk/itm/Vintage-Camera-Lens/123456789012?hash=item1:g:abc&_trkparms=x".withoutTracking,
                       "https://www.ebay.co.uk/itm/123456789012")
    }

    func testPathCleaningCanBeTurnedOff() {
        let options = CleanOptions(cleanPath: false)
        XCTAssertEqual(URLStripper.clean("https://www.amazon.com/Thing/dp/B08N5WRWNW/ref=sr_1_1?tag=x", options: options),
                       "https://www.amazon.com/Thing/dp/B08N5WRWNW/ref=sr_1_1")
    }

    // MARK: - Fragments

    func testTrackingFragmentsGoAndAnchorsStay() {
        XCTAssertEqual("https://example.com/a#xtor=RSS-1".withoutTracking, "https://example.com/a")
        XCTAssertEqual("https://example.com/a#utm_source=x".withoutTracking, "https://example.com/a")
        XCTAssertEqual("https://example.com/a#.Vh3xYz.twitter".withoutTracking, "https://example.com/a")
        XCTAssertEqual("https://example.com/a#_=_".withoutTracking, "https://example.com/a")
        XCTAssertEqual("https://example.com/a#sthash.AbC1.dpbs".withoutTracking, "https://example.com/a")
        XCTAssertEqual("https://example.com/a#section-2".withoutTracking, "https://example.com/a#section-2")
        XCTAssertEqual("https://example.com/a#:~:text=hello".withoutTracking, "https://example.com/a#:~:text=hello")
    }

    // MARK: - Categories and options

    func testCategorySpecificHelpersTouchOnlyTheirCategory() {
        let url = "https://example.com?utm_source=google&fbclid=123&mc_cid=456&awc=789&id=page"
        XCTAssertEqual(url.withoutAnalytics, "https://example.com?fbclid=123&mc_cid=456&awc=789&id=page")
        XCTAssertEqual(url.withoutSocial, "https://example.com?utm_source=google&mc_cid=456&awc=789&id=page")
        XCTAssertEqual(url.withoutEmail, "https://example.com?utm_source=google&fbclid=123&awc=789&id=page")
        XCTAssertEqual(url.withoutEcommerce, "https://example.com?utm_source=google&fbclid=123&mc_cid=456&id=page")
    }

    func testCategoryHelpersDoNotUnwrapOrTouchThePath() {
        let google = "https://www.google.com/url?q=https://example.com/a&utm_source=x"
        XCTAssertEqual(google.withoutAnalytics, "https://www.google.com/url?q=https://example.com/a")
        let amazon = "https://www.amazon.com/T/dp/B08N5WRWNW/ref=sr_1_1?utm_source=x"
        XCTAssertEqual(amazon.withoutAnalytics, "https://www.amazon.com/T/dp/B08N5WRWNW/ref=sr_1_1")
    }

    func testCustomParameters() {
        XCTAssertEqual("https://example.com?utm_source=test&debug=true&id=123".withoutTracking(removing: ["debug"]), "https://example.com?id=123")
        XCTAssertEqual("https://example.com?utm_source=test&debug=true&temp=1".withoutParams(["debug", "temp"]), "https://example.com?utm_source=test")
        XCTAssertEqual("https://example.com?utm_source=test&Debug=true".withoutParams(["debug"]), "https://example.com?utm_source=test")
    }

    func testPreserveWinsOverEveryRule() {
        let options = CleanOptions(preserve: ["utm_source", "tag"])
        XCTAssertEqual(URLStripper.clean("https://www.amazon.com/dp/B08N5WRWNW?tag=keep-20&utm_source=keep&utm_medium=drop", options: options),
                       "https://www.amazon.com/dp/B08N5WRWNW?tag=keep-20&utm_source=keep")
    }

    // MARK: - Report

    func testReportSaysWhatWentAndWhy() {
        let report = "https://www.amazon.com/Thing/dp/B08N5WRWNW/ref=sr_1_1?tag=a-20&utm_source=x&fbclid=y&psc=1#xtor=1".cleanReport
        XCTAssertEqual(report.cleaned, "https://www.amazon.com/dp/B08N5WRWNW?psc=1")
        XCTAssertTrue(report.didChange)
        XCTAssertEqual(Set(report.removed.map(\.name)), ["tag", "utm_source", "fbclid"])
        XCTAssertEqual(report.removed.first { $0.name == "tag" }?.scope, "Amazon")
        XCTAssertEqual(report.removed.first { $0.name == "tag" }?.category, .ecommerce)
        XCTAssertEqual(report.removed.first { $0.name == "utm_source" }?.scope, "global")
        XCTAssertEqual(report.removed.first { $0.name == "fbclid" }?.category, .social)
        XCTAssertEqual(report.pathChanges, ["removed /ref=sr_1_1", "canonicalised to /dp/B08N5WRWNW"])
        XCTAssertTrue(report.fragmentRemoved)
        XCTAssertEqual(report.removedByCategory[.social], ["fbclid"])
    }

    func testReportOfACleanURLReportsNothing() {
        let report = "https://example.com/a?id=1".cleanReport
        XCTAssertFalse(report.didChange)
        XCTAssertTrue(report.removed.isEmpty && report.unwrapped.isEmpty && report.pathChanges.isEmpty)
        XCTAssertFalse(report.fragmentRemoved)
    }

    // MARK: - Foundation URL parity

    func testURLAPIMatchesStringAPI() {
        let pairs = [
            "https://example.com?utm_source=test&id=1",
            "https://www.amazon.com/T/dp/B08N5WRWNW/ref=sr_1_1?tag=x&psc=1",
            "https://www.google.com/url?q=https://example.com/a",
        ]
        for s in pairs {
            let url = URL(string: s)!
            XCTAssertEqual(url.withoutTracking.absoluteString, s.withoutTracking, s)
            XCTAssertEqual(url.withoutAnalytics.absoluteString, s.withoutAnalytics, s)
            XCTAssertEqual(url.unwrappedRedirect.absoluteString, s.unwrappedRedirect, s)
            XCTAssertEqual(url.cleanReport.cleaned, s.cleanReport.cleaned, s)
        }
        XCTAssertEqual(URL(string: "https://example.com?utm_source=x&debug=1")!.withoutTracking(removing: ["debug"]),
                       URL(string: "https://example.com")!)
        XCTAssertEqual(URL(string: "https://example.com?utm_source=x&debug=1")!.withoutParams(["debug"]),
                       URL(string: "https://example.com?utm_source=x")!)
    }

    // MARK: - The database view

    func testTheGlobalListNoLongerContainsSiteSpecificNames() {
        for name in ["ref", "tag", "s", "k", "t", "from", "price", "hash", "user_id", "_", "keywords", "bvid"] {
            XCTAssertFalse(TrackingParameters.all.contains(name), "\(name) is not tracking everywhere")
        }
        for name in ["gclid", "fbclid", "mc_cid", "awc", "msclkid", "igshid"] {
            XCTAssertTrue(TrackingParameters.all.contains(name), name)
        }
        XCTAssertTrue(TrackingParameters.prefixes.contains("utm_"))
        XCTAssertEqual(TrackingParameters.all, TrackingParameters.analytics.union(TrackingParameters.social)
            .union(TrackingParameters.email).union(TrackingParameters.ecommerce).union(TrackingParameters.other))
        XCTAssertFalse(TrackingParameters.hostRules.isEmpty)
        XCTAssertFalse(TrackingParameters.redirects.isEmpty)
    }

    func testIsTrackingAnswersPerHost() {
        XCTAssertEqual(URLStripper.isTracking("ref", on: "www.amazon.com"), .ecommerce)
        XCTAssertNil(URLStripper.isTracking("ref", on: "github.com"))
        XCTAssertNil(URLStripper.isTracking("ref"))
        XCTAssertEqual(URLStripper.isTracking("UTM_Medium"), .analytics)
        XCTAssertEqual(URLStripper.isTracking("s", on: "x.com"), .social)
        XCTAssertNil(URLStripper.isTracking("s", on: "wordpress.org"))
        XCTAssertEqual(TrackingParameters.category(of: "fbclid"), .social)
    }

    func testEveryHostRuleAndRedirectHasAtLeastOneHostAndALabel() {
        for rule in HostRules.all {
            XCTAssertFalse(rule.hosts.isEmpty, rule.label)
            XCTAssertFalse(rule.parameters.isEmpty, rule.label)
            XCTAssertFalse(rule.label.isEmpty)
        }
        for rule in Redirects.rules {
            XCTAssertFalse(rule.hosts.isEmpty, rule.label)
            XCTAssertFalse(rule.label.isEmpty)
        }
    }

    /// No name may appear in both the global table and a host rule: if it is
    /// tracking everywhere the host rule is redundant, and if it is not, the
    /// global entry is a false positive waiting to happen.
    func testGlobalAndHostTablesDoNotOverlap() {
        let global = TrackingParameters.all
        for rule in HostRules.all {
            for pattern in rule.parameters {
                if case .exact(let name) = pattern {
                    XCTAssertFalse(global.contains(name), "\(name) is both global and scoped to \(rule.label)")
                }
            }
        }
    }

    // MARK: - Performance

    func testPerformanceRealWorldBatch() {
        let urls = [
            "https://www.amazon.com/Sony-WH-1000XM5/dp/B09XS7JWHH/ref=sr_1_3?keywords=x&qid=1&sr=8-3&tag=a-20&utm_source=g",
            "https://www.google.com/url?sa=t&url=https%3A%2F%2Fexample.com%2Farticle&ved=2ah&usg=AOv",
            "https://x.com/user/status/1?s=20&t=abc",
            "https://example.com/very/long/path?utm_source=a&utm_medium=b&utm_campaign=c&gclid=d&fbclid=e&id=1&page=2",
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=share&si=x&t=42s",
        ]
        measure { for _ in 0..<200 { for url in urls { _ = url.withoutTracking } } }
    }
}
