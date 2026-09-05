//
//  URLValidatorV2Tests.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  Version 2: deterministic host matching, the platform table, link signals,
//  and the rewritten extractors, checked against real URL shapes.
//

import XCTest
@testable import URLValidator

final class URLValidatorV2Tests: XCTestCase {

    private func ids(_ s: String) -> [String: String] { URLValidator.analyze(s).extractedIDs }

    // MARK: - The table is the single source of truth

    func testEveryPlatformAppearsInTheTableExactlyOnce() {
        var seen: [Platform: Int] = [:]
        for entry in PlatformDomains.table { seen[entry.platform, default: 0] += 1 }
        for platform in Platform.allCases where platform != .unknown {
            XCTAssertEqual(seen[platform], 1, "\(platform) appears \(seen[platform] ?? 0) times in PlatformDomains.table")
        }
        XCTAssertNil(seen[.unknown])
    }

    func testEveryPlatformHasACategory() {
        for platform in Platform.allCases where platform != .unknown {
            XCTAssertNotEqual(platform.category, .unknown, "\(platform)")
        }
    }

    func testNoHostIsClaimedByTwoPlatforms() {
        var owners: [String: Platform] = [:]
        for entry in PlatformDomains.table {
            for host in entry.hosts {
                XCTAssertNil(owners[host], "\(host) is claimed by \(owners[host]!) and \(entry.platform)")
                owners[host] = entry.platform
            }
        }
    }

    // MARK: - Deterministic host matching

    func testMostSpecificHostWins() {
        XCTAssertEqual("https://music.youtube.com/watch?v=x".urlPlatform, .youtubeMusic)
        XCTAssertEqual("https://www.youtube.com/watch?v=x".urlPlatform, .youtube)
        XCTAssertEqual("https://podcasters.spotify.com/pod".urlPlatform, .podcastsSpotify)
        XCTAssertEqual("https://open.spotify.com/track/x".urlPlatform, .spotify)
        XCTAssertEqual("https://read.amazon.com/?asin=B0".urlPlatform, .kindle)
        XCTAssertEqual("https://music.amazon.co.uk/albums/x".urlPlatform, .amazonMusic)
        XCTAssertEqual("https://www.amazon.co.uk/dp/B08N5WRWNW".urlPlatform, .amazon)
    }

    /// The first version used `contains`, so `notbandcamp.com` was Bandcamp.
    func testLookAlikeHostsAreNotMatched() {
        for host in ["notbandcamp.com", "mybandcamp.com", "youtube.com.evil.example", "amazonaws.com", "amazon.example.com", "fakegithub.com"] {
            XCTAssertNil("https://\(host)/x".urlPlatform, host)
        }
    }

    func testBrandMatchesEveryCountryTLD() {
        for host in ["amazon.com", "amazon.co.uk", "amazon.com.au", "amazon.co.jp", "smile.amazon.de", "www.amazon.nl"] {
            XCTAssertEqual("https://\(host)/dp/B08N5WRWNW".urlPlatform, .amazon, host)
        }
        XCTAssertEqual("https://www.ebay.com.au/itm/123456789012".urlPlatform, .ebay)
        XCTAssertEqual("https://www.google.co.uk/search?q=x".urlPlatform, .googleSearch)
        XCTAssertEqual("https://www.vinted.fr/items/1".urlPlatform, .vinted)
    }

    func testPathOverrides() {
        XCTAssertEqual("https://www.youtube.com/shorts/abc123def45".urlPlatform, .youtubeShorts)
        XCTAssertEqual("https://www.instagram.com/reels/Cabc/".urlPlatform, .instagramReels)
        XCTAssertEqual("https://www.google.com/maps/place/Big+Ben".urlPlatform, .googleMaps)
        XCTAssertEqual("https://maps.app.goo.gl/AbC123".urlPlatform, .googleMaps)
        XCTAssertEqual("https://goo.gl/maps/AbC123".urlPlatform, .googleMaps)
        XCTAssertEqual("https://itunes.apple.com/us/app/things-3/id904237743".urlPlatform, .appStore)
        XCTAssertEqual("https://itunes.apple.com/us/album/abbey-road/1441164426".urlPlatform, .appleMusic)
        XCTAssertEqual("https://itunes.apple.com/us/podcast/atp/id617416468".urlPlatform, .applePodcasts)
    }

    func testNewPlatforms() {
        let cases: [(String, Platform)] = [
            ("https://chatgpt.com/share/abc", .chatgpt), ("https://claude.ai/chat/abc", .claude),
            ("https://gemini.google.com/app", .gemini), ("https://www.perplexity.ai/search/x", .perplexity),
            ("https://huggingface.co/apple/DCLM-7B", .huggingface), ("https://www.threads.com/@zuck", .threads),
            ("https://apps.apple.com/gb/app/things-3/id904237743", .appStore),
            ("https://play.google.com/store/apps/details?id=com.spotify.music", .googlePlay),
            ("https://tv.apple.com/gb/show/severance/umc.cmc.1srk2goyh2q2zdxcx605w8vtx", .appleTV),
            ("https://www.netflix.com/title/80057281", .netflix), ("https://www.imdb.com/title/tt0111161/", .imdb),
            ("https://letterboxd.com/film/parasite-2019/", .letterboxd), ("https://www.strava.com/activities/123", .strava),
            ("https://calendly.com/dave/30min", .calendly), ("https://cal.com/dave/30min", .calCom),
            ("https://news.ycombinator.com/item?id=1", .hackerNews), ("https://www.nytimes.com/2026/01/01/x.html", .nytimes),
            ("https://bsky.app/profile/jay.bsky.team/post/3k", .bluesky), ("https://warpcast.com/dwr", .farcaster),
            ("https://swiftpackageindex.com/apple/swift-argument-parser", .swiftPackageIndex),
            ("https://finance.yahoo.com/quote/AAPL", .yahooFinance), ("https://www.temu.com/x.html", .temu),
            ("https://primal.net/p/npub1", .nostr), ("https://lu.ma/abc", .luma), ("https://polymarket.com/event/x", .polymarket),
            ("https://arxiv.org/abs/2301.12345", .arxiv), ("https://doi.org/10.1000/xyz", .doi),
            ("https://pubmed.ncbi.nlm.nih.gov/12345678/", .pubmed), ("https://www.wikidata.org/wiki/Q42", .wikidata),
            ("https://web.archive.org/web/2024/https://example.com", .internetArchive),
            ("https://mail.google.com/mail/u/0/#inbox", .gmail), ("https://forms.gle/abc", .googleForms),
            ("https://www.audible.co.uk/pd/B0ABC12345", .audible), ("https://what3words.com/filled.count.soap", .what3words),
            ("https://www.eventbrite.co.uk/e/x-tickets-1234567890", .eventbrite), ("https://www.bbc.co.uk/news/x", .bbc),
        ]
        for (url, platform) in cases { XCTAssertEqual(url.urlPlatform, platform, url) }
    }

    func testRetiredServicesAreStillRecognisedAndSaySo() {
        XCTAssertEqual("https://podcasts.google.com/feed/x".urlPlatform, .googlePodcasts)
        XCTAssertTrue(Platform.googlePodcasts.isDefunct)
        XCTAssertEqual(Platform.googlePodcasts.retiredIn, 2024)
        XCTAssertEqual(Platform.googlePodcasts.successor, .youtubeMusic)
        XCTAssertTrue(Platform.skype.isDefunct)
        XCTAssertFalse(Platform.youtube.isDefunct)
        XCTAssertNil(Platform.youtube.retiredIn)
        XCTAssertTrue("https://podcasts.google.com/feed/x".urlAnalysis.summary.contains("retired 2024"))
    }

    // MARK: - Validity

    func testBareDecimalsAreNotHosts() {
        XCTAssertFalse(URLValidator.isValid("1.5"))
        XCTAssertFalse(URLValidator.isValid("3.14"))
        XCTAssertFalse(URLValidator.isValid("example.c"))
        XCTAssertTrue(URLValidator.isValid("192.168.1.1"))
        XCTAssertTrue(URLValidator.isValid("10.0.0.1:8080/admin"))
        XCTAssertTrue(URLValidator.isValid("example.com"))
        XCTAssertTrue(URLValidator.isValid("localhost:3000"))
    }

    // MARK: - Extractors: video

    func testYouTubeFormsThatUsedToLoseTheID() {
        XCTAssertEqual("https://youtube.com/shorts/abc123def45?feature=share".youtubeVideoID, "abc123def45")
        XCTAssertEqual("https://www.youtube.com/live/abc123def45?si=x".youtubeVideoID, "abc123def45")
        XCTAssertEqual("https://www.youtube.com/embed/abc123def45".youtubeVideoID, "abc123def45")
        XCTAssertEqual("https://www.youtube-nocookie.com/embed/abc123def45".youtubeVideoID, "abc123def45")
        XCTAssertEqual("https://youtu.be/abc123def45?si=share".youtubeVideoID, "abc123def45")
        XCTAssertEqual("https://music.youtube.com/watch?v=abc123def45&list=PL1".youtubeVideoID, "abc123def45")
        let full = ids("https://www.youtube.com/watch?v=abc123def45&list=PLxyz&t=42s")
        XCTAssertEqual(full["youtube_playlist_id"], "PLxyz")
        XCTAssertEqual(full["youtube_timestamp"], "42s")
        XCTAssertEqual(ids("https://www.youtube.com/@mkbhd")["youtube_channel_handle"], "mkbhd")
        XCTAssertEqual(ids("https://www.youtube.com/channel/UCBJycsmduvYEL83R_U4JriQ")["youtube_channel_id"], "UCBJycsmduvYEL83R_U4JriQ")
    }

    func testTikTokTwitchVimeoLoom() {
        let tt = ids("https://www.tiktok.com/@scout2015/video/6718335390845095173")
        XCTAssertEqual(tt["tiktok_video_id"], "6718335390845095173"); XCTAssertEqual(tt["tiktok_user"], "scout2015")
        XCTAssertEqual(ids("https://vm.tiktok.com/ZMdvJ9RJK/")["tiktok_short_code"], "ZMdvJ9RJK")
        XCTAssertEqual(ids("https://www.tiktok.com/@u/photo/7300000000000000000")["tiktok_photo_id"], "7300000000000000000")
        XCTAssertEqual(ids("https://www.twitch.tv/videos/1234567890")["twitch_video_id"], "1234567890")
        XCTAssertEqual(ids("https://www.twitch.tv/shroud")["twitch_channel"], "shroud")
        XCTAssertNil(ids("https://www.twitch.tv/directory")["twitch_channel"])
        XCTAssertEqual(ids("https://vimeo.com/123456789/abcdef0123")["vimeo_video_id"], "123456789", "a private hash after the id must not hide the id")
        XCTAssertEqual(ids("https://www.loom.com/share/abc123def456")["loom_video_id"], "abc123def456")
    }

    // MARK: - Extractors: social

    /// Real LinkedIn URLs end `…-activity-7123-AbCd`: the id is NOT after the last dash.
    func testLinkedInRealWorldFormat() {
        let real = ids("https://www.linkedin.com/posts/satyanadella_ai-activity-7160000000000000000-AbCd?utm_source=share")
        XCTAssertEqual(real["linkedin_activity_id"], "7160000000000000000")
        XCTAssertEqual(ids("https://www.linkedin.com/feed/update/urn:li:activity:7160000000000000001/")["linkedin_activity_id"], "7160000000000000001")
        XCTAssertEqual(ids("https://www.linkedin.com/in/davidsherlock/")["linkedin_handle"], "davidsherlock")
        XCTAssertEqual(ids("https://www.linkedin.com/company/apple/")["linkedin_company"], "apple")
        XCTAssertEqual(ids("https://www.linkedin.com/jobs/view/3900000000/")["linkedin_job_id"], "3900000000")
    }

    func testTwitterInstagramFacebookReddit() {
        let tw = ids("https://x.com/apple/status/1700000000000000000/photo/1")
        XCTAssertEqual(tw["tweet_id"], "1700000000000000000"); XCTAssertEqual(tw["twitter_user"], "apple")
        XCTAssertEqual(ids("https://twitter.com/i/web/status/1700000000000000000")["tweet_id"], "1700000000000000000")
        XCTAssertNil(ids("https://x.com/i/web/status/1")["twitter_user"], "i is a route, not a user")
        XCTAssertEqual(ids("https://x.com/hashtag/swift")["twitter_hashtag"], "swift")

        XCTAssertEqual(ids("https://www.instagram.com/reels/CxYz123/")["instagram_post_id"], "CxYz123")
        let story = ids("https://www.instagram.com/stories/apple/3200000000000000000/")
        XCTAssertEqual(story["instagram_user"], "apple"); XCTAssertEqual(story["instagram_story_id"], "3200000000000000000")
        XCTAssertEqual(ids("https://www.instagram.com/apple/")["instagram_user"], "apple")
        XCTAssertNil(ids("https://www.instagram.com/explore/")["instagram_user"])

        XCTAssertEqual(ids("https://fb.watch/abc123/")["facebook_video_short_code"], "abc123")
        XCTAssertEqual(ids("https://www.facebook.com/apple/videos/1234567890/")["facebook_video_id"], "1234567890")
        XCTAssertEqual(ids("https://www.facebook.com/reel/1234567890")["facebook_video_id"], "1234567890")
        let perma = ids("https://www.facebook.com/permalink.php?story_fbid=111&id=222")
        XCTAssertEqual(perma["facebook_post_id"], "111"); XCTAssertEqual(perma["facebook_page_id"], "222")
        XCTAssertEqual(ids("https://www.facebook.com/profile.php?id=4")["facebook_profile_id"], "4")
        XCTAssertEqual(ids("https://www.facebook.com/share/p/AbC123/")["facebook_share_code"], "AbC123")
        XCTAssertEqual(ids("https://www.facebook.com/photo.php?fbid=999")["facebook_photo_id"], "999")

        let r = ids("https://www.reddit.com/r/swift/comments/abc123/title/def456/")
        XCTAssertEqual(r["subreddit"], "swift"); XCTAssertEqual(r["reddit_post_id"], "abc123"); XCTAssertEqual(r["reddit_comment_id"], "def456")
        XCTAssertEqual(ids("https://www.reddit.com/r/swift/s/AbCdEf")["reddit_share_id"], "AbCdEf")
        XCTAssertEqual(ids("https://redd.it/abc123")["reddit_post_id"], "abc123")
        XCTAssertEqual(ids("https://www.reddit.com/user/spez")["reddit_user"], "spez")
        XCTAssertEqual(ids("https://www.reddit.com/u/spez")["reddit_user"], "spez")
    }

    func testBlueskyThreadsMastodon() {
        let b = ids("https://bsky.app/profile/jay.bsky.team/post/3kabcdefghij")
        XCTAssertEqual(b["bluesky_handle"], "jay.bsky.team"); XCTAssertEqual(b["bluesky_post_id"], "3kabcdefghij")
        let t = ids("https://www.threads.net/@zuck/post/Cabc123")
        XCTAssertEqual(t["threads_user"], "zuck"); XCTAssertEqual(t["threads_post_id"], "Cabc123")
        let m = ids("https://mastodon.social/@Gargron/100254678")
        XCTAssertEqual(m["mastodon_user"], "Gargron"); XCTAssertEqual(m["mastodon_status_id"], "100254678")
        XCTAssertEqual(ids("https://hachyderm.io/@user@other.social")["mastodon_user"], "user@other.social")
    }

    // MARK: - Extractors: audio and apps

    func testAppleMusicPodcastsAppStoreGooglePlaySteam() {
        let album = ids("https://music.apple.com/gb/album/abbey-road/1441164426?i=1441164816")
        XCTAssertEqual(album["apple_music_album_id"], "1441164426"); XCTAssertEqual(album["apple_music_track_id"], "1441164816")
        XCTAssertEqual(album["apple_storefront"], "gb")
        XCTAssertEqual(ids("https://music.apple.com/us/playlist/todays-hits/pl.f4d106fed2bd41149aaacabb233eb5eb")["apple_music_playlist_id"], "pl.f4d106fed2bd41149aaacabb233eb5eb")
        let pod = ids("https://podcasts.apple.com/gb/podcast/accidental-tech-podcast/id617416468?i=1000600000000")
        XCTAssertEqual(pod["apple_podcast_id"], "617416468"); XCTAssertEqual(pod["apple_podcast_episode_id"], "1000600000000")
        XCTAssertEqual(ids("https://apps.apple.com/gb/app/things-3/id904237743")["app_store_id"], "904237743")
        XCTAssertEqual(ids("https://play.google.com/store/apps/details?id=com.spotify.music&hl=en")["google_play_package"], "com.spotify.music")
        XCTAssertEqual(ids("https://store.steampowered.com/app/1245620/ELDEN_RING/")["steam_app_id"], "1245620")
        XCTAssertEqual(ids("https://open.spotify.com/intl-de/track/4cOdK2wGLETKBW3PvgPWqT?si=x")["spotify_track_id"], "4cOdK2wGLETKBW3PvgPWqT")
        XCTAssertEqual(ids("https://open.spotify.com/audiobook/7iHfbu1YPACw6oZPAFJtqe")["spotify_audiobook_id"], "7iHfbu1YPACw6oZPAFJtqe")
        XCTAssertEqual(ids("https://soundcloud.com/artist/sets/my-playlist")["soundcloud_playlist"], "my-playlist")
        XCTAssertEqual(ids("https://myband.bandcamp.com/album/first")["bandcamp_artist"], "myband")
    }

    // MARK: - Extractors: shopping and reference

    func testAmazonASINInEveryShape() {
        for url in [
            "https://www.amazon.com/dp/B08N5WRWNW",
            "https://www.amazon.co.uk/Sony-Headphones/dp/B08N5WRWNW/ref=sr_1_1?keywords=x",
            "https://www.amazon.de/gp/product/B08N5WRWNW",
            "https://www.amazon.com/gp/aw/d/B08N5WRWNW",
            "https://www.amazon.com/exec/obidos/ASIN/B08N5WRWNW/ref=x",
        ] { XCTAssertEqual(url.amazonASIN, "B08N5WRWNW", url) }
        XCTAssertNil("https://www.amazon.com/s?k=usb+c+hub".amazonASIN)
        XCTAssertEqual(ids("https://www.amazon.com/s?k=usb+c+hub")["amazon_search_query"], "usb c hub")
        XCTAssertEqual(ids("https://www.ebay.co.uk/itm/Vintage-Lens/123456789012")["ebay_item_id"], "123456789012")
        XCTAssertEqual(ids("https://www.etsy.com/listing/1234567890/handmade-mug")["etsy_listing_id"], "1234567890")
    }

    func testReferenceIdentifiers() {
        XCTAssertEqual("https://www.imdb.com/title/tt0111161/".imdbID, "tt0111161")
        XCTAssertEqual(ids("https://www.imdb.com/name/nm0000151/")["imdb_name_id"], "nm0000151")
        let wiki = ids("https://en.wikipedia.org/wiki/Swift_(programming_language)")
        XCTAssertEqual(wiki["wikipedia_title"], "Swift (programming language)"); XCTAssertEqual(wiki["wikipedia_language"], "en")
        XCTAssertEqual(ids("https://de.m.wikipedia.org/wiki/Berlin")["wikipedia_language"], "de")
        XCTAssertEqual(ids("https://www.wikidata.org/wiki/Q42")["wikidata_id"], "Q42")
        XCTAssertEqual(ids("https://www.wikidata.org/wiki/Property:P31")["wikidata_id"], "P31")
        XCTAssertEqual("https://arxiv.org/abs/2301.12345v2".arxivID, "2301.12345v2")
        XCTAssertEqual("https://arxiv.org/pdf/2301.12345.pdf".arxivID, "2301.12345")
        XCTAssertEqual(ids("https://arxiv.org/abs/hep-th/9901001")["arxiv_id"], "hep-th/9901001")
        XCTAssertEqual("https://doi.org/10.1038/s41586-020-2649-2".doi, "10.1038/s41586-020-2649-2")
        XCTAssertEqual(ids("https://pubmed.ncbi.nlm.nih.gov/33199800/")["pubmed_id"], "33199800")
        XCTAssertEqual(ids("https://www.goodreads.com/book/show/11084145-steve-jobs")["goodreads_book_id"], "11084145")
        XCTAssertEqual(ids("https://letterboxd.com/film/parasite-2019/")["letterboxd_film"], "parasite-2019")
        XCTAssertEqual(ids("https://www.themoviedb.org/movie/496243-gisaengchung")["tmdb_movie_id"], "496243")
        let wb = ids("https://web.archive.org/web/20240101000000/https://example.com/page?x=1")
        XCTAssertEqual(wb["wayback_timestamp"], "20240101000000"); XCTAssertEqual(wb["wayback_url"], "https://example.com/page?x=1")
        XCTAssertEqual(ids("https://news.ycombinator.com/item?id=38000000")["hackernews_item_id"], "38000000")
        XCTAssertEqual(ids("https://www.google.com/search?q=swift+concurrency")["google_query"], "swift concurrency")
    }

    // MARK: - Extractors: developer

    func testGitHubBeyondOwnerAndRepo() {
        XCTAssertEqual(ids("https://github.com/apple/swift/commit/abc123")["github_commit"], "abc123")
        XCTAssertEqual(ids("https://github.com/apple/swift/releases/tag/swift-6.0-RELEASE")["github_release_tag"], "swift-6.0-RELEASE")
        let tree = ids("https://github.com/apple/swift/blob/main/README.md")
        XCTAssertEqual(tree["github_ref"], "main"); XCTAssertEqual(tree["github_path"], "README.md")
        XCTAssertEqual(ids("https://github.com/apple/swift/discussions/123")["github_discussion_number"], "123")
        let gist = ids("https://gist.github.com/dave/0123456789abcdef")
        XCTAssertEqual(gist["github_owner"], "dave"); XCTAssertEqual(gist["github_gist_id"], "0123456789abcdef")
        XCTAssertEqual(ids("https://raw.githubusercontent.com/apple/swift/main/README.md")["github_ref"], "main")
        XCTAssertEqual(ids("https://dave.github.io/site/")["github_owner"], "dave")
        XCTAssertNil(ids("https://github.com/orgs/apple/repositories")["github_owner"], "orgs is a route, not an owner")
        XCTAssertEqual(ids("https://github.com/apple")["github_owner"], "apple")
    }

    func testGitLabStackOverflowNpmHuggingFace() {
        let mr = ids("https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123")
        XCTAssertEqual(mr["gitlab_namespace"], "gitlab-org"); XCTAssertEqual(mr["gitlab_project"], "gitlab"); XCTAssertEqual(mr["gitlab_mr_number"], "123")
        XCTAssertEqual(ids("https://stackoverflow.com/questions/24002092/what-is-the-difference")["stackoverflow_question_id"], "24002092")
        XCTAssertEqual(ids("https://stackoverflow.com/a/24002259")["stackoverflow_answer_id"], "24002259")
        XCTAssertEqual(ids("https://www.npmjs.com/package/@types/node")["npm_package"], "@types/node")
        XCTAssertEqual(ids("https://www.npmjs.com/package/express")["npm_package"], "express")
        let hf = ids("https://huggingface.co/datasets/openai/gsm8k")
        XCTAssertEqual(hf["huggingface_owner"], "openai"); XCTAssertEqual(hf["huggingface_kind"], "dataset")
        XCTAssertEqual(ids("https://huggingface.co/papers/2301.12345")["arxiv_id"], "2301.12345")
        XCTAssertEqual(ids("https://swiftpackageindex.com/apple/swift-argument-parser")["package_repo"], "swift-argument-parser")
    }

    // MARK: - Extractors: documents and messaging

    func testGoogleDocsDropboxFigmaNotion() {
        XCTAssertEqual(ids("https://docs.google.com/document/d/1AbCdEfGhIjK/edit")["google_docs_id"], "1AbCdEfGhIjK")
        let sheet = ids("https://docs.google.com/spreadsheets/d/1AbC/edit#gid=123")
        XCTAssertEqual(sheet["google_sheets_id"], "1AbC")
        XCTAssertEqual(ids("https://drive.google.com/file/d/1XyZ/view?usp=sharing")["google_drive_file_id"], "1XyZ")
        XCTAssertEqual(ids("https://drive.google.com/open?id=1XyZ")["google_drive_file_id"], "1XyZ")
        XCTAssertEqual(ids("https://drive.google.com/drive/folders/1Fold")["google_drive_folder_id"], "1Fold")
        XCTAssertEqual(ids("https://docs.google.com/forms/d/e/1FAIpQLS/viewform")["google_forms_id"], "1FAIpQLS")
        XCTAssertEqual(ids("https://www.dropbox.com/scl/fi/abc123/file.pdf?rlkey=x")["dropbox_share_key"], "abc123")
        XCTAssertEqual(ids("https://www.dropbox.com/s/abc123/file.pdf")["dropbox_share_key"], "abc123")
        let fig = ids("https://www.figma.com/design/AbC123/My-File?node-id=1-2")
        XCTAssertEqual(fig["figma_file_key"], "AbC123"); XCTAssertEqual(fig["figma_node_id"], "1-2"); XCTAssertEqual(fig["figma_kind"], "design")
        XCTAssertEqual(ids("https://www.notion.so/My-Page-3d27b24a8d8081d08deff23f9c006907")["notion_page_id"], "3d27b24a-8d80-81d0-8def-f23f9c006907")
        XCTAssertEqual(ids("https://acme.notion.site/Roadmap-3d27b24a8d8081d08deff23f9c006907?pvs=4")["notion_page_id"], "3d27b24a-8d80-81d0-8def-f23f9c006907")
        let cal = ids("https://calendly.com/dave/30min")
        XCTAssertEqual(cal["calendly_user"], "dave"); XCTAssertEqual(cal["calendly_event"], "30min")
        XCTAssertEqual(ids("https://calendly.com/d/d2nb-2qp-5qw")["calendly_link_code"], "d2nb-2qp-5qw")
        XCTAssertEqual(ids("https://linear.app/acme/issue/ACM-123/fix-it")["linear_issue_key"], "ACM-123")
        XCTAssertEqual(ids("https://acme.atlassian.net/browse/ACM-123")["jira_issue_key"], "ACM-123")
        XCTAssertEqual(ids("https://acme.substack.com/p/hello")["substack_publication"], "acme")
    }

    func testMessagingLinks() {
        XCTAssertEqual(ids("https://discord.gg/swift")["discord_invite"], "swift")
        XCTAssertEqual(ids("https://discord.com/invite/swift")["discord_invite"], "swift")
        let ch = ids("https://discord.com/channels/111/222/333")
        XCTAssertEqual(ch["discord_guild_id"], "111"); XCTAssertEqual(ch["discord_channel_id"], "222"); XCTAssertEqual(ch["discord_message_id"], "333")
        XCTAssertEqual(ids("https://t.me/+AbCdEf123")["telegram_invite"], "AbCdEf123")
        XCTAssertEqual(ids("https://t.me/joinchat/AbCdEf123")["telegram_invite"], "AbCdEf123")
        let msg = ids("https://t.me/durov/123")
        XCTAssertEqual(msg["telegram_user"], "durov"); XCTAssertEqual(msg["telegram_message_id"], "123")
        XCTAssertEqual(ids("https://t.me/somebot?start=ref1")["telegram_start_parameter"], "ref1")
        XCTAssertNil(ids("https://t.me/s/channel")["telegram_invite"])
        XCTAssertEqual(ids("https://wa.me/447700900123?text=hi")["whatsapp_number"], "447700900123")
        XCTAssertEqual(ids("https://chat.whatsapp.com/AbC123")["whatsapp_invite"], "AbC123")
        XCTAssertEqual(ids("https://zoom.us/j/1234567890?pwd=x")["zoom_meeting_id"], "1234567890")
        XCTAssertNil(ids("https://zoom.us/j/1234567890?pwd=x")["zoom_passcode"], "passcodes are not harvested")
        XCTAssertEqual(ids("https://meet.google.com/abc-defg-hij")["google_meet_code"], "abc-defg-hij")
        let slack = ids("https://acme.slack.com/archives/C01234567/p1700000000000100")
        XCTAssertEqual(slack["slack_workspace"], "acme"); XCTAssertEqual(slack["slack_channel_id"], "C01234567"); XCTAssertEqual(slack["slack_message_ts"], "1700000000000100")
    }

    func testMapsLinks() {
        let g = ids("https://www.google.com/maps/place/Big+Ben/@51.5007,-0.1246,17z/data=x")
        XCTAssertEqual(g["maps_place"], "Big Ben"); XCTAssertEqual(g["maps_latitude"], "51.5007"); XCTAssertEqual(g["maps_longitude"], "-0.1246")
        XCTAssertEqual(ids("https://maps.app.goo.gl/AbC123")["google_maps_short_code"], "AbC123")
        XCTAssertEqual(ids("https://www.google.com/maps?q=51.5,-0.12")["maps_latitude"], "51.5")
        XCTAssertEqual(ids("https://www.google.com/maps?cid=123")["google_maps_cid"], "123")
        let a = ids("https://maps.apple.com/?ll=51.5007,-0.1246&q=Big%20Ben")
        XCTAssertEqual(a["maps_latitude"], "51.5007"); XCTAssertEqual(a["maps_query"], "Big Ben")
        let osm = ids("https://www.openstreetmap.org/#map=17/51.5007/-0.1246")
        XCTAssertEqual(osm["maps_zoom"], "17"); XCTAssertEqual(osm["maps_longitude"], "-0.1246")
        XCTAssertEqual(ids("https://what3words.com/filled.count.soap")["what3words_address"], "filled.count.soap")
    }

    func testImagesAndCrowdfunding() {
        XCTAssertEqual(ids("https://imgur.com/a/AbC123")["imgur_album_id"], "AbC123")
        XCTAssertEqual(ids("https://i.imgur.com/AbC123.png")["imgur_image_id"], "AbC123")
        XCTAssertEqual(ids("https://unsplash.com/photos/a-cat-sitting-on-a-sofa-AbCdEfGhIjK")["unsplash_photo_id"], "AbCdEfGhIjK")
        let f = ids("https://www.flickr.com/photos/nasa/12345678901/")
        XCTAssertEqual(f["flickr_user"], "nasa"); XCTAssertEqual(f["flickr_photo_id"], "12345678901")
        let ks = ids("https://www.kickstarter.com/projects/creator/my-project")
        XCTAssertEqual(ks["kickstarter_creator"], "creator"); XCTAssertEqual(ks["kickstarter_project"], "my-project")
        XCTAssertEqual(ids("https://www.eventbrite.co.uk/e/swift-meetup-tickets-1234567890")["eventbrite_event_id"], "1234567890")
        XCTAssertEqual(ids("https://www.strava.com/activities/9876543210")["strava_activity_id"], "9876543210")
        XCTAssertEqual(ids("https://polymarket.com/event/will-it-rain")["polymarket_event_slug"], "will-it-rain")
        XCTAssertEqual(ids("https://etherscan.io/tx/0xabc")["ethereum_tx"], "0xabc")
    }

    // MARK: - Signals

    func testAPlainLinkHasNoConcerns() {
        let s = "https://example.com/a?b=1".linkSignals
        XCTAssertFalse(s.isSuspicious); XCTAssertFalse(s.isShortened); XCTAssertFalse(s.isTrackingRedirect)
        XCTAssertEqual(s.subdomainDepth, 0); XCTAssertNil(s.nonStandardPort)
    }

    func testShortenersAreNamed() {
        XCTAssertEqual("https://bit.ly/3abc".linkSignals.shortener, "Bitly")
        XCTAssertEqual("https://youtu.be/abc".linkSignals.shortener, "YouTube")
        XCTAssertEqual("https://t.co/abc".linkSignals.shortener, "Twitter/X")
        XCTAssertTrue("https://tinyurl.com/x".isShortenedURL)
        XCTAssertFalse("https://tinyurl.com/x".isSuspiciousURL, "shortened is a fact, not a concern")
        XCTAssertEqual(["https://bit.ly/a", "https://example.com/b"].shortenedURLs, ["https://bit.ly/a"])
    }

    func testTrackingRedirectsAreFlagged() {
        XCTAssertTrue("https://www.google.com/url?q=https://example.com".linkSignals.isTrackingRedirect)
        XCTAssertTrue("https://nam12.safelinks.protection.outlook.com/?url=x".linkSignals.isTrackingRedirect)
        XCTAssertTrue("https://l.facebook.com/l.php?u=x".linkSignals.isTrackingRedirect)
        XCTAssertFalse("https://www.google.com/search?q=x".linkSignals.isTrackingRedirect)
        XCTAssertTrue("https://www.google.com/url?q=https://example.com".linkSignals.embedsURL)
    }

    func testPhishingShapes() {
        let userinfo = "https://apple.com@evil.example/login".linkSignals
        XCTAssertTrue(userinfo.hasUserInfo); XCTAssertTrue(userinfo.isSuspicious)
        XCTAssertTrue(userinfo.concerns.first?.contains("evil.example") ?? false, "the concern names the REAL host")

        let ip = "http://192.168.1.10/admin".linkSignals
        XCTAssertTrue(ip.hostIsIPAddress); XCTAssertTrue(ip.isLocalOrPrivate)
        XCTAssertTrue("http://8.8.8.8/".linkSignals.hostIsIPAddress)
        XCTAssertFalse("http://8.8.8.8/".linkSignals.isLocalOrPrivate)

        XCTAssertTrue("https://xn--pple-43d.com/".linkSignals.hasPunycode)
        XCTAssertEqual("https://example.com:8443/".linkSignals.nonStandardPort, 8443)
        XCTAssertNil("https://example.com:443/".linkSignals.nonStandardPort)
        XCTAssertGreaterThanOrEqual("https://a.b.c.d.e.example.com/".linkSignals.subdomainDepth, 4)
        XCTAssertTrue("https://a.b.c.d.e.example.com/".linkSignals.isSuspicious)
    }

    func testDangerousSchemesAreReportedEvenThoughInvalid() {
        let js = URLValidator.analyze("javascript:alert(1)")
        XCTAssertFalse(js.isValid)
        XCTAssertTrue(js.signals.schemeIsDangerous)
        XCTAssertTrue(js.signals.isSuspicious)
        XCTAssertTrue("data:text/html;base64,PHNjcmlwdD4=".linkSignals.schemeIsDangerous)
        XCTAssertFalse("https://example.com".linkSignals.schemeIsDangerous)
    }

    /// The homograph trick is only visible in the string as typed — after
    /// Foundation encodes the host, a Cyrillic а and a Latin a look the same.
    func testMixedScriptDetectionOnTheTypedHost() {
        XCTAssertTrue(Signals.hasMixedScripts("аpple.com"))          // Cyrillic а
        XCTAssertFalse(Signals.hasMixedScripts("apple.com"))
        XCTAssertFalse(Signals.hasMixedScripts("яндекс.рф"))         // all Cyrillic — not mixed
        XCTAssertEqual(Signals.hostAsTyped(from: "https://user@аpple.com:8080/x?y#z"), "аpple.com")
        XCTAssertEqual(Signals.hostAsTyped(from: "example.com/path"), "example.com")
    }

    func testRegistrableDomainDepth() {
        XCTAssertEqual(Signals.registrableLabelCount("example.co.uk"), 3)
        XCTAssertEqual(Signals.registrableLabelCount("example.com"), 2)
        XCTAssertEqual("https://shop.example.co.uk/".linkSignals.subdomainDepth, 1)
    }

    // MARK: - Summary, URL parity, coverage

    func testSummaryIncludesTheNewSignals() {
        XCTAssertTrue("https://bit.ly/x".urlAnalysis.summary.contains("shortened via Bitly"))
        XCTAssertTrue("https://apple.com@evil.example/".urlAnalysis.summary.contains("concern"))
        XCTAssertTrue("https://youtu.be/abc123def45".urlAnalysis.summary.hasPrefix("YouTube"))
    }

    func testURLTypedAPIMatchesStringAPI() {
        let s = "https://www.youtube.com/watch?v=abc123def45&list=PL1"
        let u = URL(string: s)!
        XCTAssertEqual(u.platform, s.urlPlatform)
        XCTAssertEqual(u.extractedIDs, s.urlAnalysis.extractedIDs)
        XCTAssertEqual(u.linkSignals, s.linkSignals)
        XCTAssertEqual(u.isShortened, s.isShortenedURL)
    }

    func testExtractorCoverageIsBroad() {
        XCTAssertGreaterThanOrEqual(URLValidator.platformsWithIDExtraction.count, 100)
        for extractor in Extractors.all { XCTAssertFalse(extractor.platforms.isEmpty) }
    }

    func testDetectionIsFastEnoughForAKeyboard() {
        let urls = ["https://www.youtube.com/watch?v=abc", "https://www.amazon.co.uk/dp/B08N5WRWNW", "https://example.com/x", "https://news.ycombinator.com/item?id=1"]
        measure { for _ in 0..<500 { for u in urls { _ = URLValidator.detectPlatform(from: u) } } }
    }
}
