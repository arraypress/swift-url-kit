//
//  HostRules.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  Tracking that is only tracking on one site. Curated from ClearURLs'
//  ruleset (206 providers, checked 2026-09-06) and the sites' own link formats,
//  keeping the hosts a person actually pastes. Names lowercased.
//
//  The test for inclusion: would stripping this on THIS host ever break the
//  link? `k` on amazon.com is the search query, so it is not here. `keywords`
//  on amazon.com is a legacy alias for the query, so it is not here either.
//

import Foundation
import URLCore

enum HostRules {

    static let all: [HostRule] = [

        // MARK: Search engines

        HostRule(hosts: [.brand("google")], parameters: [
            .exact("ved"), .exact("ei"), .exact("oq"), .exact("esrc"), .exact("uact"),
            .exact("cd"), .exact("cad"), .exact("sa"), .exact("usg"), .exact("ust"),
            .exact("rct"), .exact("source"), .exact("sxsrf"), .exact("rlz"), .exact("aqs"),
            .exact("sourceid"), .exact("iflsig"), .exact("fbs"), .exact("ictx"), .exact("cshid"),
            .exact("pcampaignid"), .exact("sca_esv"), .exact("sca_upv"), .prefix("gs_"),
            .prefix("gws_"), .prefix("gfe_"), .exact("bih"), .exact("biw"), .exact("dpr"),
            .exact("vet"), .exact("atyp"), .exact("sei"), .exact("dcr"), .exact("je"),
            .exact("_u"), .exact("opi"), .exact("ie"), .exact("oe"),
        ], category: .analytics, label: "Google",
           excluding: [.suffix("mail.google.com"), .suffix("accounts.google.com"),
                       .suffix("docs.google.com"), .suffix("drive.google.com")]),

        HostRule(hosts: [.suffix("play.google.com")], parameters: [
            .exact("pcampaignid"), .exact("referrer"),
        ], category: .analytics, label: "Google Play"),

        HostRule(hosts: [.brand("bing")], parameters: [
            .exact("cvid"), .exact("sk"), .exact("sp"), .exact("sc"), .exact("qs"), .exact("qp"),
            .exact("form"), .exact("pq"), .exact("ghc"), .exact("ghsh"), .exact("ghacc"),
            .exact("ghpl"), .exact("pglt"), .exact("ntref"), .exact("refig"),
        ], category: .analytics, label: "Bing"),

        HostRule(hosts: [.suffix("duckduckgo.com")], parameters: [.exact("t")],
                 category: .analytics, label: "DuckDuckGo"),

        HostRule(hosts: [.brand("yahoo")], parameters: [
            .exact("fr"), .exact("fr2"),
        ], category: .analytics, label: "Yahoo"),

        HostRule(hosts: [.brand("yandex"), .exact("ya.ru")], parameters: [
            .exact("lr"), .exact("redircnt"), .exact("clid"),
        ], category: .analytics, label: "Yandex"),

        // MARK: Video

        HostRule(hosts: [.suffix("youtube.com"), .suffix("youtu.be"), .suffix("youtube-nocookie.com")],
                 parameters: [
            .exact("feature"), .exact("si"), .exact("kw"), .exact("pp"), .exact("ab_channel"),
            .exact("embeds_referring_euri"), .exact("embeds_referring_origin"),
            .exact("source_ve_path"),
        ], category: .other, label: "YouTube"),

        HostRule(hosts: [.suffix("netflix.com")], parameters: [
            .exact("trackid"), .exact("tctx"), .prefix("jb"),
        ], category: .other, label: "Netflix"),

        HostRule(hosts: [.suffix("twitch.tv")], parameters: [
            .exact("tt_medium"), .exact("tt_content"), .exact("tt_email_id"),
        ], category: .other, label: "Twitch"),

        HostRule(hosts: [.suffix("bilibili.com"), .exact("b23.tv")], parameters: [
            .exact("spm_id_from"), .exact("vd_source"), .exact("from_source"), .exact("from"),
            .exact("seid"), .exact("share_source"), .exact("share_medium"), .exact("share_plat"),
            .exact("share_tag"), .exact("share_session_id"), .exact("share_from"),
            .exact("share_times"), .exact("unique_k"), .exact("plat_id"), .exact("buvid"),
            .exact("is_story_h5"), .exact("up_id"), .exact("bbid"), .exact("ts"),
            .exact("visit_id"), .exact("session_id"), .exact("broadcast_type"),
            .exact("is_room_feed"), .exact("refer_from"), .exact("msource"),
            .exact("timestamp"), .exact("launch_id"), .exact("live_from"),
        ], category: .other, label: "Bilibili"),

        // MARK: Music

        HostRule(hosts: [.suffix("spotify.com"), .exact("spotify.link")], parameters: [
            .exact("si"), .exact("nd"), .exact("dlsi"),
        ], category: .other, label: "Spotify"),

        HostRule(hosts: [.suffix("apple.com")], parameters: [
            .exact("app"), .prefix("ign-itsc"), .prefix("ign-mpt"), .exact("itscg"),
            .exact("itsct"), .exact("ct"), .exact("mt"), .exact("ls"), .exact("at"),
            .exact("pt"), .exact("uo"),
        ], category: .analytics, label: "Apple"),

        // MARK: Social

        HostRule(hosts: [.suffix("facebook.com"), .exact("fb.com"), .exact("fb.me"), .exact("fb.watch")],
                 parameters: [
            .exact("ref"), .exact("fref"), .exact("refid"), .exact("ref_type"), .exact("refsrc"),
            .prefix("hc_"), .prefix("__cft__"), .prefix("__xts__"), .exact("__tn__"), .exact("eid"),
            .exact("comment_tracking"), .exact("dti"), .exact("app"), .exact("video_source"),
            .exact("ftentidentifier"), .exact("pageid"), .exact("padding"), .exact("ls_ref"),
            .exact("action_history"), .exact("tracking"), .exact("referral_code"),
            .exact("referral_story_type"), .exact("eav"), .exact("sfnsn"), .exact("idorvanity"),
            .exact("wtsid"), .exact("rdc"), .exact("rdr"), .exact("paipv"), .exact("_nc_x"),
            .exact("_rdr"), .exact("mibextid"), .exact("rdid"), .exact("extid"),
            .exact("notif_id"), .exact("notif_t"),
        ], category: .social, label: "Facebook"),

        HostRule(hosts: [.suffix("threads.net"), .suffix("threads.com")], parameters: [
            .exact("xmt"),
        ], category: .social, label: "Threads"),

        HostRule(hosts: [.suffix("twitter.com"), .suffix("x.com"), .exact("t.co")], parameters: [
            .exact("s"), .exact("t"), .exact("cn"), .exact("src"), .exact("ref_url"),
            .exact("cxt"), .exact("mx"),
        ], category: .social, label: "Twitter/X"),

        HostRule(hosts: [.suffix("tiktok.com")], parameters: [
            .exact("_d"), .exact("_t"), .exact("_r"), .exact("u_code"), .exact("preview_pb"),
            .exact("timestamp"), .exact("user_id"), .exact("share_app_name"), .exact("share_app_id"),
            .exact("share_iid"), .exact("share_link_id"), .exact("source"), .exact("sender_device"),
            .exact("sender_web_id"), .exact("is_from_webapp"), .exact("is_copy_url"), .exact("k"),
            .exact("checksum"), .exact("tt_from"), .exact("enter_from"), .exact("enter_method"),
            .exact("_svg"), .exact("refer"), .exact("referer_url"), .exact("referer_video_id"),
            .exact("web_id"),
        ], category: .social, label: "TikTok"),

        HostRule(hosts: [.suffix("douyin.com")], parameters: [
            .exact("previous_page"), .exact("enter_from"), .exact("enter_method"), .exact("iid"),
        ], category: .social, label: "Douyin"),

        HostRule(hosts: [.suffix("reddit.com"), .exact("redd.it")], parameters: [
            .exact("$deep_link"), .exact("%24deep_link"), .exact("correlation_id"),
            .exact("ref_campaign"), .exact("ref_source"), .exact("$3p"), .exact("%243p"),
            .exact("rdt"), .exact("$original_url"), .exact("%24original_url"),
            .exact("share_id"), .exact("ref"), .exact("ref_share"),
        ], category: .social, label: "Reddit"),

        HostRule(hosts: [.suffix("linkedin.com"), .exact("lnkd.in")], parameters: [
            .exact("trk"), .exact("trkinfo"), .exact("trkemail"), .exact("refid"),
            .exact("trackingid"), .exact("lipi"), .exact("licu"), .exact("original_referer"),
            .exact("upsellorderorigin"), .exact("midtoken"), .exact("midsig"), .exact("eid"),
        ], category: .social, label: "LinkedIn"),

        HostRule(hosts: [.suffix("pinterest.com"), .exact("pin.it")], parameters: [
            .exact("sender"), .exact("sfo"), .exact("nic_v2"), .exact("nic_v3"),
        ], category: .social, label: "Pinterest"),

        HostRule(hosts: [.suffix("snapchat.com")], parameters: [.exact("sc_referrer"), .exact("sc_ua")],
                 category: .social, label: "Snapchat"),

        HostRule(hosts: [.suffix("tumblr.com")], parameters: [.exact("source")],
                 category: .social, label: "Tumblr"),

        HostRule(hosts: [.exact("vk.com"), .exact("vk.ru")], parameters: [
            .exact("from"), .exact("ref"), .exact("ref_domain"),
        ], category: .social, label: "VK"),

        HostRule(hosts: [.suffix("weibo.com"), .suffix("weibo.cn")], parameters: [
            .exact("refer_flag"), .exact("from"),
        ], category: .social, label: "Weibo"),

        // MARK: Shopping

        HostRule(hosts: [.brand("amazon"), .exact("a.co"), .exact("amzn.to"), .exact("amzn.eu"), .exact("amzn.asia")],
                 parameters: [
            .exact("ref"), .exact("ref_"), .exact("tag"), .exact("th"), .exact("qid"), .exact("sr"),
            .exact("srs"), .exact("sprefix"), .exact("crid"), .exact("dchild"), .exact("camp"),
            .exact("creative"), .exact("aaxitk"), .exact("hsa_cr_id"), .exact("content-id"),
            .exact("dib"), .exact("dib_tag"), .exact("social_share"), .exact("starsleft"),
            .exact("skiptwisterog"), .exact("_encoding"), .exact("smid"), .exact("qualifier"),
            .exact("spia"), .exact("ms3_c"), .exact("refrid"), .exact("rnid"),
            .exact("field-lbr_brands_browse-bin"), .prefix("__mk_"), .exact("ie"), .exact("adid"),
            .prefix("cv_ct_"), .prefix("sb-ci-"),
        ], category: .ecommerce, label: "Amazon"),

        HostRule(hosts: [.suffix("imdb.com")], parameters: [.exact("ref_")],
                 category: .ecommerce, label: "IMDb"),

        HostRule(hosts: [.brand("ebay")], parameters: [
            .exact("_trkparms"), .exact("_trksid"), .exact("_from"), .exact("hash"),
            .exact("mkevt"), .exact("mkcid"), .exact("mkrid"), .exact("mkpid"), .exact("campid"),
            .exact("toolid"), .exact("customid"), .exact("amdata"),
        ], category: .ecommerce, label: "eBay"),

        HostRule(hosts: [.brand("aliexpress")], parameters: [
            .exact("ws_ab_test"), .exact("btsid"), .exact("algo_expid"), .exact("algo_exp_id"),
            .exact("algo_pvid"), .exact("gps-id"), .prefix("scm"), .exact("cv"), .exact("af"),
            .exact("mall_affr"), .exact("sk"), .exact("dp"), .exact("terminal_id"),
            .exact("spm"), .exact("pdp_npi"), .exact("pdp_ext_f"), .exact("gatewayadapt"),
            .exact("utparam-url"), .exact("aff_fcid"), .exact("aff_fsk"), .exact("aff_platform"),
            .exact("aff_trace_key"), .exact("afsmartredirect"), .exact("srcsns"),
            .exact("businesstype"), .exact("templateid"),
        ], category: .ecommerce, label: "AliExpress"),

        HostRule(hosts: [.suffix("taobao.com"), .suffix("tmall.com")], parameters: [
            .exact("spm"), .exact("scm"), .exact("ut_sk"), .exact("sp_tk"), .exact("share_crt_v"),
            .exact("suid"), .exact("cpp"), .exact("shareurl"), .exact("short_name"), .exact("pvid"),
            .exact("un"), .exact("sourcetype"), .exact("tbsocialpopkey"), .exact("app"),
            .exact("bxsign"), .exact("tk"),
        ], category: .ecommerce, label: "Taobao"),

        HostRule(hosts: [.suffix("etsy.com")], parameters: [
            .exact("click_key"), .exact("click_sum"), .exact("organic_search_click"), .exact("ref"),
            .exact("frs"), .exact("crt"), .exact("sts"), .exact("share_time"),
        ], category: .ecommerce, label: "Etsy"),

        HostRule(hosts: [.suffix("walmart.com")], parameters: [.exact("u1"), .prefix("ath")],
                 category: .ecommerce, label: "Walmart"),

        HostRule(hosts: [.suffix("bestbuy.com")], parameters: [
            .exact("loc"), .exact("acampid"), .exact("mpid"), .exact("intl"), .exact("ref"),
        ], category: .ecommerce, label: "Best Buy"),

        HostRule(hosts: [.suffix("target.com")], parameters: [
            .exact("afid"), .exact("cpng"), .exact("fndsrc"), .exact("lnm"), .exact("ref"),
        ], category: .ecommerce, label: "Target"),

        HostRule(hosts: [.suffix("steampowered.com"), .suffix("steamcommunity.com")],
                 parameters: [.exact("snr")], category: .ecommerce, label: "Steam"),

        HostRule(hosts: [.suffix("roblox.com")], parameters: [.exact("refpageid")],
                 category: .other, label: "Roblox"),

        // MARK: Travel

        HostRule(hosts: [.brand("airbnb")], parameters: [
            .exact("federated_search_id"), .exact("search_type"), .exact("source"),
            .exact("source_impression_id"), .exact("previous_page_section_name"),
            .exact("unique_share_id"), .exact("viralityentrypoint"), .exact("_set_bev_on_new_domain"),
        ], category: .other, label: "Airbnb"),

        HostRule(hosts: [.suffix("booking.com")], parameters: [
            .exact("aid"), .exact("label"), .exact("sid"), .exact("srpvid"), .exact("from_sn"),
            .exact("ucfs"),
        ], category: .ecommerce, label: "Booking.com"),

        HostRule(hosts: [.brand("tripadvisor")], parameters: [.exact("m"), .prefix("sup")],
                 category: .other, label: "Tripadvisor"),

        // MARK: Publishers

        HostRule(hosts: [.suffix("nytimes.com")], parameters: [
            .exact("smid"), .exact("smtyp"), .exact("emc"), .exact("nl"), .exact("te"),
            .exact("referringsource"), .exact("regi_id"), .exact("segment_id"),
            .exact("campaign_id"), .exact("instance_id"), .exact("user_id"),
        ], category: .other, label: "New York Times"),

        HostRule(hosts: [.suffix("theguardian.com")], parameters: [.exact("cmp")],
                 category: .other, label: "The Guardian"),

        HostRule(hosts: [.suffix("bbc.com"), .suffix("bbc.co.uk")], parameters: [
            .exact("ns_mchannel"), .exact("ns_source"), .exact("ns_campaign"),
            .exact("ns_linkname"), .exact("ns_fee"),
        ], category: .other, label: "BBC"),

        HostRule(hosts: [.suffix("washingtonpost.com")], parameters: [
            .exact("itid"), .exact("wpisrc"), .exact("wpmk"), .exact("tid"),
        ], category: .other, label: "Washington Post"),

        HostRule(hosts: [.suffix("bloomberg.com")], parameters: [
            .exact("leadsource"), .exact("srnd"), .exact("sref"), .exact("in_source"),
        ], category: .other, label: "Bloomberg"),

        HostRule(hosts: [.suffix("forbes.com")], parameters: [.exact("sh")],
                 category: .other, label: "Forbes"),

        HostRule(hosts: [.suffix("spiegel.de")], parameters: [
            .exact("b"), .exact("sara_ref"), .exact("sara_ecid"),
        ], category: .other, label: "Spiegel"),

        HostRule(hosts: [.suffix("medium.com")], parameters: [.exact("source")],
                 category: .other, label: "Medium"),

        HostRule(hosts: [.suffix("substack.com")], parameters: [.exact("r"), .exact("s")],
                 category: .other, label: "Substack"),

        HostRule(hosts: [.suffix("wikipedia.org"), .suffix("wikimedia.org")], parameters: [.exact("wprov")],
                 category: .other, label: "Wikipedia"),

        // MARK: Work

        HostRule(hosts: [.suffix("github.com")], parameters: [
            .exact("email_token"), .exact("email_source"), .exact("notification_referrer_id"),
            .exact("ref_cta"), .exact("ref_loc"), .exact("ref_page"), .exact("ref_product"),
            .exact("ref_style"), .exact("ref_plan"),
        ], category: .other, label: "GitHub"),

        HostRule(hosts: [.suffix("stackoverflow.com"), .suffix("stackexchange.com")], parameters: [
            .exact("so_medium"), .exact("so_source"), .exact("r"),
        ], category: .other, label: "Stack Overflow"),

        HostRule(hosts: [.suffix("quora.com")], parameters: [
            .exact("ch"), .exact("oid"), .exact("share"), .exact("srid"), .exact("target_type"),
        ], category: .other, label: "Quora"),

        HostRule(hosts: [.suffix("notion.so"), .suffix("notion.site")], parameters: [.exact("pvs")],
                 category: .other, label: "Notion"),

        HostRule(hosts: [.suffix("indeed.com")], parameters: [
            .exact("from"), .exact("alid"), .exact("tk"), .exact("vjtk"), .exact("advn"),
            .exact("adid"), .exact("sjdu"), .exact("xkcb"),
        ], category: .other, label: "Indeed"),

        HostRule(hosts: [.suffix("glassdoor.com")], parameters: [
            .exact("ao"), .exact("guid"), .exact("src"), .exact("vt"), .exact("cs"), .exact("cb"),
        ], category: .other, label: "Glassdoor"),

        HostRule(hosts: [.suffix("mozilla.org")], parameters: [.exact("src"), .exact("redirect_source")],
                 category: .other, label: "Mozilla"),
    ]

    /// The rules that apply to a normalised host.
    static func matching(_ host: String) -> [HostRule] {
        all.filter { HostMatcher.matches(host, any: $0.hosts) && !HostMatcher.matches(host, any: $0.excluding) }
    }

    /// The rule that removes a lowercased name, if any.
    static func rule(removing name: String, among rules: [HostRule]) -> HostRule? {
        for rule in rules {
            for pattern in rule.parameters {
                switch pattern {
                case .exact(let e) where name == e: return rule
                case .prefix(let p) where name.hasPrefix(p): return rule
                default: continue
                }
            }
        }
        return nil
    }
}
