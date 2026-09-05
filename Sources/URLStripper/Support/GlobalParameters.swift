//
//  GlobalParameters.swift
//  URLStripper
//
//  Created by David Sherlock on 2026.
//
//  Parameters that are tracking on EVERY host. The bar for this table is
//  "no site anywhere uses this name for something functional" — which is why
//  it is short, and why names like `ref`, `tag`, `s`, `k`, `from`, `price`,
//  `hash`, `user_id` and `_` are NOT here. Those live in HostRules, scoped to
//  the one site where they are tracking.
//

import Foundation
import URLCore

enum GlobalParameters {

    /// Category → patterns. Names lowercased.
    static let table: [TrackingCategory: [ParameterPattern]] = [
        .analytics: [
            // Google Analytics / Ads / Merchant
            .prefix("utm_"), .exact("gclid"), .exact("gclsrc"), .exact("dclid"),
            .exact("gbraid"), .exact("wbraid"), .exact("gad_source"), .exact("gad_campaignid"),
            .exact("gad"), .exact("srsltid"), .exact("_ga"), .exact("_gl"), .exact("gs_l"),
            // Microsoft, Yandex, Baidu
            .exact("msclkid"), .exact("yclid"), .exact("ysclid"), .exact("_openstat"),
            // Matomo / Piwik
            .prefix("mtm_"), .prefix("pk_"), .prefix("piwik_"), .prefix("matomo_"),
            // Adobe / Marin / Kenshoo / Webtrekk / AT Internet
            .exact("s_kwcid"), .exact("ef_id"), .exact("mkwid"), .exact("pcrid"), .exact("pgrid"),
            .exact("ptaid"), .prefix("wt_"), .exact("wtrid"), .exact("xtor"), .exact("xtref"),
            .prefix("at_"), .prefix("otm_"), .prefix("stm_"), .prefix("hmb_"),
            // IBM Acoustic
            .exact("cm_mmc"), .exact("cm_ven"), .exact("cm_cat"), .exact("cm_pla"),
            .exact("cm_ite"), .exact("cm_lm"), .exact("cm_sp"),
            // Assorted attribution
            .exact("cmpid"), .exact("mbid"), .exact("ncid"), .exact("sr_share"),
            .exact("guccounter"), .exact("guce_referrer"), .exact("guce_referrer_sig"),
            .exact("sznclid"), .exact("dicbo"), .exact("wickedid"), .exact("rb_clickid"),
            .exact("ceneo_spo"), .exact("os_ehash"), .exact("_branch_match_id"),
            .exact("_branch_referrer"), .exact("ocid"), .exact("icid"), .exact("intcid"),
            .exact("intcmp"), .exact("int_source"), .exact("int_medium"), .exact("int_campaign"),
            .exact("soc_src"), .exact("soc_trk"), .exact("echobox"), .exact("__source"),
        ],
        .social: [
            .exact("fbclid"), .exact("fb_action_ids"), .exact("fb_action_types"),
            .exact("fb_source"), .exact("fb_ref"), .exact("action_object_map"),
            .exact("action_type_map"), .exact("action_ref_map"),
            .exact("igshid"), .exact("igsh"),
            .exact("twclid"), .exact("__twitter_impression"), .exact("ref_src"),
            .exact("tw_source"), .exact("tw_campaign"), .exact("tw_term"),
            .exact("tw_content"), .exact("tw_adid"),
            .exact("ttclid"), .exact("li_fat_id"), .exact("sccid"), .exact("ndclid"),
            .exact("epik"),
        ],
        .email: [
            // Mailchimp, Marketo, HubSpot
            .exact("mc_cid"), .exact("mc_eid"), .exact("mc_tc"), .exact("mkt_tok"),
            .exact("_hsenc"), .exact("_hsmi"), .exact("__hstc"), .exact("__hssc"),
            .exact("__hsfp"), .exact("hsctatracking"), .prefix("hsa_"),
            // Klaviyo, Drip, Vero, Omeda, Bronto, ActiveCampaign, Blueshift, Salesforce
            .exact("_ke"), .exact("_kx"), .exact("__s"), .exact("vero_conv"), .exact("vero_id"),
            .exact("oly_anon_id"), .exact("oly_enc_id"), .exact("_bta_tid"), .exact("_bta_c"),
            .exact("vgo_ee"), .prefix("bsft_"), .prefix("sfmc_"), .prefix("trk_"),
            // dotdigital, MailerLite, ConvertKit, Beehiiv, Eloqua
            .exact("dm_i"), .exact("ml_subscriber"), .exact("ml_subscriber_hash"),
            .exact("ck_subscriber_id"), .exact("_bhlid"), .exact("elqtrackid"), .exact("elqtrack"),
            .exact("elqaid"), .exact("elqat"), .exact("elqcampaignid"),
            .exact("nr_email_referer"), .exact("sms_source"), .exact("sms_click"), .exact("sms_uph"),
        ],
        .ecommerce: [
            // Affiliate networks: Awin, CJ, Rakuten, Impact, Zanox, Amazon Associates
            .exact("awc"), .exact("cjevent"), .exact("cjdata"), .exact("ranmid"), .exact("raneaid"),
            .exact("ransiteid"), .exact("irclickid"), .exact("irgwc"), .exact("zanpid"),
            .exact("ascsubtag"), .exact("linkcode"), .exact("linkid"), .exact("creativeasin"),
            .prefix("pf_rd_"), .prefix("pd_rd_"), .exact("affid"), .exact("aff_id"),
            .exact("affiliate_id"), .exact("aff_request_id"), .exact("clickid"), .exact("click_id"),
            .exact("k_clickid"),
            // Shopify storefront tracking — on every Shopify shop, custom domains included
            .exact("_pos"), .exact("_sid"), .exact("_ss"), .exact("_psq"), .exact("_fd"),
            .exact("pr_prod_strat"), .exact("pr_rec_id"), .exact("pr_rec_pid"),
            .exact("pr_ref_pid"), .exact("pr_seq"),
        ],
        .other: [
            .exact("ito"), .exact("ftag"), .exact("taid"), .exact("gdfms"), .exact("gdftrk"),
            .exact("gdffi"),
        ],
    ]

    /// Flattened for one-pass matching.
    private static let flat: [(ParameterPattern, TrackingCategory)] =
        table.flatMap { category, patterns in patterns.map { ($0, category) } }

    /// The category a lowercased name belongs to anywhere, or nil.
    static func category(of name: String) -> TrackingCategory? {
        for (pattern, category) in flat {
            switch pattern {
            case .exact(let e) where name == e: return category
            case .prefix(let p) where name.hasPrefix(p): return category
            default: continue
            }
        }
        return nil
    }

    /// Every exact name, by category — for listings and the legacy
    /// `TrackingParameters` view. Prefixes are not names and are excluded.
    static func exactNames(in category: TrackingCategory) -> Set<String> {
        Set((table[category] ?? []).compactMap { if case .exact(let n) = $0 { return n } else { return nil } })
    }

    static func prefixes(in category: TrackingCategory) -> Set<String> {
        Set((table[category] ?? []).compactMap { if case .prefix(let n) = $0 { return n } else { return nil } })
    }
}
