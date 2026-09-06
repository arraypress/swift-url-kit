//
//  Shorteners.swift
//  URLCore
//
//  Created by David Sherlock on 2026.
//
//  Hosts that exist to hide a destination behind a short code. Resolving one
//  needs a network request; this library only recognises them.
//

import Foundation

/// The shortener hosts this kit recognises.
///
/// Recognition only: a shortener keeps its destination server-side, so
/// resolving one needs `URLExpander`.
public enum Shorteners {

    /// Host → service name. Includes platform-owned shorteners (youtu.be,
    /// redd.it) because the destination is still hidden until resolved.
    public static let hosts: [String: String] = [
        // General-purpose
        "bit.ly": "Bitly", "bitly.com": "Bitly", "j.mp": "Bitly", "tinyurl.com": "TinyURL",
        "tiny.cc": "Tiny.cc", "t.ly": "T.LY", "is.gd": "is.gd", "v.gd": "v.gd", "ow.ly": "Hootsuite",
        "buff.ly": "Buffer", "rebrand.ly": "Rebrandly", "cutt.ly": "Cuttly", "shorturl.at": "ShortURL",
        "short.io": "Short.io", "bl.ink": "BL.INK", "snip.ly": "Sniply", "trib.al": "Trib.al",
        "dlvr.it": "dlvr.it", "ift.tt": "IFTTT", "mcaf.ee": "McAfee", "po.st": "Po.st",
        "s.id": "S.id", "rb.gy": "Rebrandly", "tr.im": "tr.im", "goo.gl": "Google", "g.co": "Google",
        "lnkd.in": "LinkedIn", "t.co": "Twitter/X", "fb.me": "Facebook", "amzn.to": "Amazon",
        "amzn.eu": "Amazon", "amzn.asia": "Amazon", "a.co": "Amazon", "youtu.be": "YouTube",
        "redd.it": "Reddit", "spoti.fi": "Spotify", "spotify.link": "Spotify", "apple.co": "Apple",
        "msft.it": "Microsoft", "aka.ms": "Microsoft", "pin.it": "Pinterest", "1drv.ms": "OneDrive",
        "we.tl": "WeTransfer", "db.tt": "Dropbox", "chng.it": "Change.org", "flic.kr": "Flickr",
        "gph.is": "Giphy", "boxd.it": "Letterboxd", "pca.st": "Pocket Casts", "dai.ly": "Dailymotion",
        "b23.tv": "Bilibili", "vm.tiktok.com": "TikTok", "vt.tiktok.com": "TikTok", "nico.ms": "Niconico",
        "abnb.me": "Airbnb", "on.soundcloud.com": "SoundCloud", "link.medium.com": "Medium",
        "maps.app.goo.gl": "Google Maps", "photos.app.goo.gl": "Google Photos", "forms.gle": "Google Forms",
        "w3w.co": "what3words", "lu.ma": "Luma", "cal.com": "Cal.com",
        // Ad-interstitial shorteners — the destination is behind an ad wall
        "adf.ly": "Adfly", "bc.vc": "BC.VC", "ouo.io": "ouo.io", "shorte.st": "Shorte.st",
        "linkvertise.com": "Linkvertise", "sub2unlock.com": "Sub2Unlock",
    ]

    /// The service behind a host — "Bitly", "YouTube" — or nil if it is not
    /// a shortener. Pass a host normalised by ``HostMatcher/normalise(_:)``.
    public static func service(for host: String) -> String? {
        if let s = hosts[host] { return s }
        // Shorteners are never subdomained except by their owner: still a shortener.
        for (h, s) in hosts where host.hasSuffix("." + h) { return s }
        return nil
    }
}
