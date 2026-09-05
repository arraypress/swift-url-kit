# Swift URL Kit

Understand a link, then clean it. Offline, Foundation only, on every Apple
platform.

```swift
import URLKit

let link = "https://www.google.com/url?q=https%3A%2F%2Fwww.amazon.co.uk%2FSony-WH-1000XM5%2Fdp%2FB09XS7JWHH%2Fref%3Dsr_1_3%3Ftag%3Dx-21&sa=D&ved=2ahUK"

link.withoutTracking
// "https://www.amazon.co.uk/dp/B09XS7JWHH"

let analysis = link.withoutTracking.urlAnalysis
analysis.platform            // .amazon
analysis.extractedIDs        // ["amazon_asin": "B09XS7JWHH"]
link.linkSignals.isTrackingRedirect   // true — it was a Google redirect
```

Three modules, one repository:

| Module | Does | Import when |
|---|---|---|
| **`URLStripper`** | Removes tracking parameters, unwraps redirect pages, canonicalises Amazon/eBay paths, drops share fragments | you clean links |
| **`URLValidator`** | Recognises 450+ platforms, extracts identifiers from 100+ of them, reads link signals (shortened, phishing shapes), judges file type | you understand links |
| **`URLCore`** | Host matching, URL parts, the redirect and shortener tables both of the above share | you build on the primitives |
| `URLKit` | All three | you want one import |

Each is its own product, so `import URLStripper` alone pulls in nothing about
platforms. `URLCore` is re-exported by the other two.

## URLStripper

```swift
"https://x.com/user/status/1?s=20&t=abc".withoutTracking
// "https://x.com/user/status/1"

"https://www.amazon.com/s?k=usb+c+hub".withoutTracking
// unchanged — k is the search query, not tracking
```

Rules are **host-scoped**. A short global table holds names no site uses
functionally (`utm_*`, `gclid`, `fbclid`, `mc_cid`, affiliate click ids). A
table of 55 sites holds names that are tracking on one host and functional
elsewhere — `ref` is Amazon's tag and GitHub's branch, `t` is Twitter's share
token and YouTube's timestamp. A single global list of 340 names, measured on
fifteen real links, broke twelve of them; that measurement is now a test.

Also: 27 **redirect wrappers** are unwrapped offline three levels deep (Google,
Bing's base64, DuckDuckGo, Outlook Safe Links, Proofpoint v2/v3, Slack,
Facebook, Instagram, YouTube, Reddit, LinkedIn, Steam, VK, AMP caches);
Amazon's `/ref=` segments go and product URLs canonicalise to `/dp/ASIN`;
`#xtor=`, `#utm_`, AddThis and ShareThis fragments go while anchors and
`#:~:text=` stay. Kept parameters come back byte for byte. `cleanReport`
says what was removed and why; `CleanOptions.preserve` wins over every rule.

## URLValidator

```swift
"https://youtube.com/shorts/abc123def45?feature=share".urlAnalysis
// platform .youtubeShorts, extractedIDs ["youtube_video_id": "abc123def45"]

"https://www.linkedin.com/posts/satya_ai-activity-7160000000000000000-AbCd"
    .urlAnalysis.extractedIDs["linkedin_activity_id"]   // "7160000000000000000"

"https://apple.com@evil.example/login".linkSignals.concerns
// ["has credentials before @ — the real host is evil.example"]

"https://bit.ly/3abc".linkSignals.shortener   // "Bitly"
Platform.googlePodcasts.isDefunct              // true, retiredIn 2024
```

Detection is **deterministic**: hosts live in one table with their category,
built into an exact-host index walked from the full host towards the
registrable domain, so `music.youtube.com` beats `youtube.com` every time and
`notbandcamp.com` is nobody. Brands match any country TLD. Path overrides
handle Shorts, Reels, Google Maps under `google.com`, and apps under
`itunes.apple.com`.

**Identifiers** come from eleven small extractors with stable `platform_thing`
keys — `youtube_video_id`, `github_owner`, `amazon_asin`, `imdb_id`,
`wikipedia_title`, `arxiv_id`, `doi`, `notion_page_id`, `discord_invite`,
`maps_latitude` — across YouTube, X, Instagram, TikTok, Facebook, LinkedIn,
Reddit, Bluesky, Threads, Mastodon, Spotify, Apple Music and Podcasts, App
Store, Google Play, Steam, Amazon, eBay, Etsy, IMDb, Letterboxd, TMDB,
Goodreads, Wikipedia, Wikidata, arXiv, PubMed, DOI, the Wayback Machine,
GitHub (commits, releases, gists, Pages), GitLab, Stack Overflow, npm, PyPI,
Hugging Face, Google Docs/Sheets/Slides/Drive/Forms, Dropbox, Figma, Notion,
Calendly, Linear, Jira, Discord, Telegram, WhatsApp, Zoom, Meet, Slack, Google
and Apple Maps, OpenStreetMap, what3words, Strava, Imgur, Unsplash, Flickr,
Kickstarter, Eventbrite, Polymarket, Etherscan and more. Search queries are
form-decoded; passcodes are never harvested.

**Signals** are judged from the URL text alone: shortened (and by whom),
tracking redirect, credentials before `@`, bare or private IP, punycode, mixed
scripts in the typed host, non-standard port, `javascript:`/`data:` schemes,
subdomain depth, unusual length. `concerns` lists the ones worth a pause, in
words; being shortened is a fact, not a concern.

## URLCore

```swift
HostMatcher.matches("smile.amazon.de", .brand("amazon"))   // true
HostMatcher.matches("amazonaws.com", .brand("amazon"))     // false
Redirects.unwrap(components)                               // (destination, "Google")
Redirects.isTrackingRedirect(components)                   // true for opaque click-trackers too
Shorteners.service(for: "t.co")                            // "Twitter/X"
URLParts(url)                                              // host, segments, query, fragment — parsed once
```

## Requirements

iOS 15 / macOS 12 / tvOS 15 / watchOS 8 / visionOS 1 · Swift 6.1

## Installation

```swift
.package(url: "https://github.com/arraypress/swift-url-kit.git", from: "1.0.0")
```

then `URLKit`, or `URLStripper` / `URLValidator` individually, as a product.

## History

This kit supersedes `swift-url-stripper` (1.0.0) and `swift-url-validator`
(1.0.1). Module names are unchanged, so existing imports keep working; only the
package URL changes. What changed in each is in the modules' own commit
history and in the section above.

## Layout

```
Sources/URLCore/        HostPattern  HostMatcher  URLParts  RedirectRule  Redirects  Shorteners
Sources/URLStripper/    Core/ Enums/ Models/ Support/ Extensions/
Sources/URLValidator/   Core/ Enums/ Models/ Protocols/ Support/Extractors/ Extensions/
Sources/URLKit/         the umbrella
Tests/                  URLCoreTests  URLStripperTests (48)  URLValidatorTests (105)
```

## License

MIT — see LICENSE.
